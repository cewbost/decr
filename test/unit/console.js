const Console = artifacts.require("Console")
const Aspect = artifacts.require("Aspect")
const { asEthWord } = require("../../utils/ethword.js")
const { awaitException } = require("../utils/exception.js")
const { expect, equal, matchList, matchFields, beInstanceOf } = require("../matchers/matchers.js")

contract("Console", accounts => {

  let testConsole

  let tagNo = 0
  newTag = () => {
    tagNo++
    return "tag " + tagNo
  }

  beVMException = (msg) => beInstanceOf(Error).and(matchFields({
    "data": matchFields({
      "reason": msg
    }),
  }))

  matchCreateEvent = (tag) => matchFields({
    "event": "AspectCreated",
    "args":  matchFields({"tag": asEthWord(tag)}),
  })

  before(async () => {
    testConsole = await Console.deployed()
  })
  describe("createAspect", () => {
    it("should create aspects owned by the caller", async () => {
      const [tag1, tag2] = [newTag(), newTag()]
      let logs = []
      logs.push(...(await testConsole.createAspect(asEthWord(tag1), { from: accounts[1] })).logs)
      logs.push(...(await testConsole.createAspect(asEthWord(tag2), { from: accounts[2] })).logs)
      expect(logs).to(matchList([
        matchCreateEvent(tag1),
        matchCreateEvent(tag2),
      ]))

      let aspects = []
      for (log of logs) {
        aspects.push(await Aspect.at(log.args.addr))
      }

      expect(await aspects[0].amIOwner({ from: accounts[1] })).to(equal(true))
      expect(await aspects[0].amIOwner({ from: accounts[2] })).to(equal(false))
      expect(await aspects[1].amIOwner({ from: accounts[2] })).to(equal(true))
      expect(await aspects[1].amIOwner({ from: accounts[1] })).to(equal(false))
    })
    it("should not allow creating multiple aspects with the same tag", async () => {
      const tag = newTag()
      await testConsole.createAspect(asEthWord(tag), { from: accounts[1] })
      expect(await awaitException(() => {
        return testConsole.createAspect(asEthWord(tag), { from: accounts[1] })
      })).to(beInstanceOf(Error).and(matchFields({
        "data": matchFields({
          "reason": "tag already taken",
        }),
      })))
    })
  })
})
