const Aspect = artifacts.require("Aspect")
const { BigNumber } = require("bignumber.js")
const {
  expect,
  equal,
  matchFields,
  beNumber,
  beInstanceOf,
  contain,
  consistOf
} = require("./matchers/matchers.js")
const { asEthWord } = require("./utils/numbers.js")
const { objectify } = require("./utils/objectify.js")
const { day } = require("./utils/time.js")

contract("Aspect", accounts => {

  let testAspect

  let unixTime = Math.floor(Date.now() / 1000)
  let testNo   = 0x100

  let fromOwner = { from: accounts[0] }

  before(async () => {
    testAspect = await Aspect.new("TestAspect", fromOwner)
  })

  beforeEach(() => {
    testNo += 0x100
  })

  describe("Management", () => {
    it("should set generation approvers by contract approvers", async () => {
      await testAspect.enableApprover(accounts[1], fromOwner)
      await testAspect.enableApprover(accounts[2], fromOwner)
      await testAspect.newGeneration(
        asEthWord(testNo + 1),
        unixTime,
        unixTime + 30 * day,
        fromOwner
      )

      await testAspect.disableApprover(accounts[1], fromOwner)
      await testAspect.enableApprover(accounts[3], fromOwner)
      await testAspect.enableApprover(accounts[4], fromOwner)
      await testAspect.newGeneration(
        asEthWord(testNo + 2),
        unixTime + 15 * day,
        unixTime + 45 * day,
        fromOwner
      )

      await testAspect.disableApprover(accounts[2], fromOwner)
      await testAspect.enableApprover(accounts[5], fromOwner)
      await testAspect.enableApprover(accounts[6], fromOwner)
      await testAspect.newGeneration(
        asEthWord(testNo + 3),
        unixTime + 30 * day,
        unixTime + 60 * day,
        fromOwner
      )

      let resp = await testAspect.getGenerations(fromOwner)
      expect(resp.map(objectify)).to(consistOf([
        matchFields({
          "id":              beNumber(testNo + 1),
          "begin_timestamp": beNumber(unixTime),
          "end_timestamp":   beNumber(unixTime + 30 * day),
          "approvers":       consistOf([accounts[1], accounts[2]]),
        }),
        matchFields({
          "id":              beNumber(testNo + 2),
          "begin_timestamp": beNumber(unixTime + 15 * day),
          "end_timestamp":   beNumber(unixTime + 45 * day),
          "approvers":       consistOf([accounts[2], accounts[3], accounts[4]]),
        }),
        matchFields({
          "id":              beNumber(testNo + 3),
          "begin_timestamp": beNumber(unixTime + 30 * day),
          "end_timestamp":   beNumber(unixTime + 60 * day),
          "approvers":       consistOf([accounts[3], accounts[4], accounts[5], accounts[6]]),
        }),
      ]))
    })
  })
})
