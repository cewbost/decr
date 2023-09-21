const AspectBare = artifacts.require("AspectBare")
const { day } = require("../utils/time.js")
const { asEthWord, asEthBytes } = require("../utils/ethword.js")
const { objectify } = require("../utils/objectify.js")
const { awaitException } = require("../utils/exception.js")
const {
  expect,
  equal,
  matchFields,
  consistOf,
  beApprox,
  beInstanceOf,
} = require("../matchers/matchers.js")

contract("AspectBare", accounts => {

  beVMException = (msg) => beInstanceOf(Error).and(matchFields({
    "data": matchFields({
      "reason": msg
    }),
  }))

  let testAspect

  let timeNow = () => Math.floor(Date.now() / 1000)
  let unixTime = Math.floor(Date.now() / 1000)
  let fromOwner = { from: accounts[0] }

  before(async () => {
    testAspect = await AspectBare.new("TestAspect")
  })
  afterEach(async () => {
    await testAspect.clearBare()
  })
  describe("request", () => {
    beforeEach(async () => {
      await testAspect.addGenerationBare(unixTime, unixTime + 10 * day, asEthWord(1))
      await testAspect.addGenerationBare(unixTime, unixTime + 10 * day, asEthWord(2))
      await testAspect.addGenerationBare(unixTime - 10 * day, unixTime - 5 * day, asEthWord(3))
      await testAspect.addGenerationBare(unixTime + 5 * day, unixTime + 10 * day, asEthWord(4))
    })
    it("should store multiple distinct records", async () => {
      let now = timeNow()
      let requestAndMatcher = async (account, gen, details, content) => {
        await testAspect.request(
          gen,
          asEthBytes(details, 24),
          asEthWord(content),
          { from: account }
        )
        return matchFields({
          "recipient":  account,
          "generation": gen,
          "details":    asEthBytes(details, 24),
          "content":    asEthWord(content),
          "timestamp":  beApprox(now, 5),
        })
      }
      let match1 = await requestAndMatcher(accounts[1], asEthWord(1), "det 1", "con 1")
      let match2 = await requestAndMatcher(accounts[1], asEthWord(2), "det 2", "con 2")
      let match3 = await requestAndMatcher(accounts[2], asEthWord(1), "det 3", "con 3")
      let match4 = await requestAndMatcher(accounts[2], asEthWord(2), "det 4", "con 4")
      let match5 = await requestAndMatcher(accounts[1], asEthWord(1), "det 5", "con 5")
      let match6 = await requestAndMatcher(accounts[1], asEthWord(2), "det 6", "con 6")
      let match7 = await requestAndMatcher(accounts[2], asEthWord(1), "det 7", "con 7")
      let match8 = await requestAndMatcher(accounts[2], asEthWord(2), "det 8", "con 8")

      let recs = await testAspect.getPendingRecordsByRecipient(accounts[1])
      expect(recs.map(objectify)).to(consistOf([match1, match2, match5, match6]))
      recs = await testAspect.getPendingRecordsByRecipient(accounts[2])
      expect(recs.map(objectify)).to(consistOf([match3, match4, match7, match8]))
      recs = await testAspect.getPendingRecordsByGeneration(asEthWord(1))
      expect(recs.map(objectify)).to(consistOf([match1, match3, match5, match7]))
      recs = await testAspect.getPendingRecordsByGeneration(asEthWord(2))
      expect(recs.map(objectify)).to(consistOf([match2, match4, match6, match8]))
    })
    it("should not allow requesting from a generation which does not exist", async () => {
      expect(await awaitException(() => {
        return testAspect.request(
          asEthWord(5),
          asEthBytes("details", 24),
          asEthWord("content"),
          { from: accounts[1] }
        )
      })).to(beVMException("Generation does not exist."))
    })
    it("should not allow requesting from inactive generation", async () => {
      expect(await awaitException(() => {
        return testAspect.request(
          asEthWord(3),
          asEthBytes("details", 24),
          asEthWord("content"),
          { from: accounts[1] }
        )
      })).to(beVMException("Generation inactive."))
    })
    it("should not allow requesting from expired generation", async () => {
      expect(await awaitException(() => {
        return testAspect.request(
          asEthWord(4),
          asEthBytes("details", 24),
          asEthWord("content"),
          { from: accounts[1] }
        )
      })).to(beVMException("Generation inactive."))
    })
    it("should not allow rerequesting aspect", async () => {
      await testAspect.request(
        asEthWord(1),
        asEthBytes("details", 24),
        asEthWord("content"),
        { from: accounts[1] }
      )
      expect(await awaitException(() => {
        return testAspect.request(
          asEthWord(1),
          asEthBytes("details", 24),
          asEthWord("content"),
          { from: accounts[1] }
        )
      })).to(beVMException("Already exists."))
    })
    it("should not allow rerequesting granted aspect", async () => {
      await testAspect.addRecordBare(
        accounts[1],
        asEthWord(1),
        asEthBytes("details", 24),
        asEthWord("content")
      )
      expect(await awaitException(() => {
        return testAspect.request(
          asEthWord(1),
          asEthBytes("details", 24),
          asEthWord("content"),
          { from: accounts[1] }
        )
      })).to(beVMException("Already exists."))
    })
  })
})
