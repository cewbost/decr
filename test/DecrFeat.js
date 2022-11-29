const DecrFeat = artifacts.require("DecrFeat")
const { BigNumber } = require("bignumber.js")
const { expect, equal, matchFields, beNumber, beInstanceOf, contain } = require("./matchers/matchers.js")
const { asEthWord } = require("./utils/numbers.js")

contract("DecrFeat", accounts => {

  const testUrls = ['http://example.io/1', 'http://example.io/2']
    const testDets = 1
    const testHash = 2

  const matchEmptyContent = matchFields({
    "granterLink": "",
    "recipientLink": "",
    "contentHash": beNumber(0),
    "details": beNumber(0),
  })
  const beVMException = beInstanceOf(Error).and(matchFields({
    "message": contain("VM Exception")
  }))

  let testFeat

  before(async () => {
    testFeat = await DecrFeat.new("testDecr", { from: accounts[0] })
  })

  describe("initial state", () => {
    it("should not have any propsals or reciepts assigned to arbitrary account", async () => {
      expect(await testFeat.proposals(accounts[1])).to(matchEmptyContent);
      expect(await testFeat.recipients(accounts[1])).to(matchEmptyContent);
    })
  })
  describe("propose", () => {
    it("should record proposals", async () => {
      await testFeat.propose(accounts[2], testUrls[0], asEthWord(testHash), asEthWord(testDets))
      expect(await testFeat.proposals(accounts[2])).to(matchFields({
        "granterLink":    testUrls[0],
        "recipientLink":  "",
        "details":        beNumber(testDets),
        "contentHash":    beNumber(testHash),
      }))
      expect(await testFeat.recipients(accounts[2])).to(matchEmptyContent)
    })
    it("should not allow anyone other than owner to make proposals", async () => {
      let err = null
      try {
        await testFeat.propose(
          accounts[0],
          testUrls[0],
          asEthWord(testHash),
          asEthWord(testDets),
          { from: accounts[1] }
        )
      } catch (e) {
        err = e
      }
      expect(err).to(beVMException)
      expect(await testFeat.recipients(accounts[0])).to(matchEmptyContent)
    })
    it("should not allow making multiple proposals to accounts", async () => {
      let err = null
      try {
        await testFeat.propose(accounts[3], testUrls[0], asEthWord(testHash), asEthWord(testDets))
        await testFeat.propose(accounts[3], testUrls[0], asEthWord(testHash), asEthWord(testDets))
      } catch(e) {
        err = e
      }
      expect(err).to(beVMException)
    })
    it("should not allow proposing feats with zero details", async () => {
      let err = null
      try {
        await testFeat.propose(accounts[3], testUrls[0], asEthWord(testHash), asEthWord(0))
      } catch(e) {
        err = e
      }
      expect(err).to(beVMException)
    })
  })
  describe("accept", () => {
    it("should record the recipient", async () => {
      await testFeat.propose(accounts[4], testUrls[0], asEthWord(testHash), asEthWord(testDets))
      await testFeat.accept(testUrls[1], { from: accounts[4] })

      expect(await testFeat.proposals(accounts[4])).to(matchEmptyContent)
      assert(await testFeat.recipients(accounts[4]), "the recipient should be recorded")
      expect(await testFeat.recipients(accounts[4])).to(matchFields({
        "granterLink":    testUrls[0],
        "recipientLink":  testUrls[1],
        "details":        beNumber(testDets),
        "contentHash":    beNumber(testHash),
      }))
    })
    it("should fail if no proposal has been made", async () => {
      let err = null
      try {
        await testFeat.accept(testUrls[1], { from: accounts[5] })
      } catch(e) {
        err = e
      }
      expect(err).to(beVMException)
    })
  })
  describe("reject", () => {
    it("should remove the proposal", async () => {
      await testFeat.propose(accounts[6], testUrls[0], asEthWord(testHash), asEthWord(testDets))
      await testFeat.reject({ from: accounts[6] })

      expect(await testFeat.proposals(accounts[6])).to(matchEmptyContent)
      expect(await testFeat.recipients(accounts[6])).to(matchEmptyContent)
    })
    it("should fail if no proposal has been made", async () => {
      let err = null
      try {
        await testFeat.reject({ from: accounts[7] })
      } catch(e) {
        err = e
      }
      expect(err).to(beVMException)
    })
  })
})
