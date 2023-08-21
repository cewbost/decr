const Aspect = artifacts.require("Aspect")
const { BigNumber } = require("bignumber.js")
const {
  expect,
  equal,
  matchFields,
  beNumber,
  beInstanceOf,
  contain,
  consistOf,
  throwError
} = require("./matchers/matchers.js")
const { asEthWord, asEthBytes } = require("./utils/ethword.js")
const { objectify } = require("./utils/objectify.js")
const { day } = require("./utils/time.js")
const { awaitException } = require("./utils/exception.js")

contract("Aspect", accounts => {

  beVMException = (msg) => beInstanceOf(Error).and(matchFields({
    "data": matchFields({
      "reason": "Only owner can perform this action."
    }),
  }))

  let testAspect

  let unixTime = Math.floor(Date.now() / 1000)

  let fromOwner = { from: accounts[0] }

  beforeEach(async () => {
    testAspect = await Aspect.new("TestAspect", fromOwner)
  })

  describe("Management", () => {
    it("should set generation approvers by contract approvers", async () => {
      await testAspect.enableApprover(accounts[1], fromOwner)
      await testAspect.enableApprover(accounts[2], fromOwner)
      await testAspect.newGeneration(
        asEthWord(1),
        unixTime,
        unixTime + 30 * day,
        fromOwner
      )

      await testAspect.disableApprover(accounts[1], fromOwner)
      await testAspect.enableApprover(accounts[3], fromOwner)
      await testAspect.enableApprover(accounts[4], fromOwner)
      await testAspect.newGeneration(
        asEthWord(2),
        unixTime + 15 * day,
        unixTime + 45 * day,
        fromOwner
      )

      await testAspect.disableApprover(accounts[2], fromOwner)
      await testAspect.enableApprover(accounts[5], fromOwner)
      await testAspect.enableApprover(accounts[6], fromOwner)
      await testAspect.newGeneration(
        asEthWord(3),
        unixTime + 30 * day,
        unixTime + 60 * day,
        fromOwner
      )

      let resp = await testAspect.getGenerations(fromOwner)
      expect(resp.map(objectify)).to(consistOf([
        matchFields({
          "id":              beNumber(1),
          "begin_timestamp": beNumber(unixTime),
          "end_timestamp":   beNumber(unixTime + 30 * day),
          "approvers":       consistOf([accounts[1], accounts[2]]),
        }),
        matchFields({
          "id":              beNumber(2),
          "begin_timestamp": beNumber(unixTime + 15 * day),
          "end_timestamp":   beNumber(unixTime + 45 * day),
          "approvers":       consistOf([accounts[2], accounts[3], accounts[4]]),
        }),
        matchFields({
          "id":              beNumber(3),
          "begin_timestamp": beNumber(unixTime + 30 * day),
          "end_timestamp":   beNumber(unixTime + 60 * day),
          "approvers":       consistOf([accounts[3], accounts[4], accounts[5], accounts[6]]),
        }),
      ]))
    })
    it("should allow changing ownership", async () => {
      await testAspect.changeOwnership(accounts[1], { from: accounts[0] })

      await testAspect.enableApprover(accounts[2], { from: accounts[1] })
      await testAspect.enableApprover(accounts[3], { from: accounts[1] })
      await testAspect.disableApprover(accounts[2], { from: accounts[1] })
      await testAspect.newGeneration(
        asEthWord(1),
        unixTime,
        unixTime + 30 * day,
        { from: accounts[1] }
      )

      expect(await awaitException(() => {
        return testAspect.newGeneration(
          asEthWord(2),
          unixTime,
          unixTime + 30 * day,
          { from: accounts[0] }
        )
      })).to(beVMException("Only owner can perform this action."))
      expect(await awaitException(() => {
        return testAspect.enableApprover(accounts[4], { from: accounts[0] })
      })).to(beVMException("Only owner can perform this action."))
      expect(await awaitException(() => {
        return testAspect.disableApprover(accounts[3], { from: accounts[0] })
      })).to(beVMException("Only owner can perform this action."))

      await testAspect.changeOwnership(accounts[0], { from: accounts[1] })

      await testAspect.enableApprover(accounts[4], { from: accounts[0] })
      await testAspect.disableApprover(accounts[3], { from: accounts[0] })
      await testAspect.newGeneration(
        asEthWord(2),
        unixTime,
        unixTime + 30 * day,
        { from: accounts[0] }
      )

      expect(await awaitException(() => {
        return testAspect.newGeneration(
          asEthWord(3),
          unixTime,
          unixTime + 30 * day,
          { from: accounts[1] }
        )
      })).to(beVMException("Only owner can perform this action."))
      expect(await awaitException(() => {
        return testAspect.enableApprover(accounts[5], { from: accounts[1] })
      })).to(beVMException("Only owner can perform this action."))
      expect(await awaitException(() => {
        return testAspect.disableApprover(accounts[4], { from: accounts[1] })
      })).to(beVMException("Only owner can perform this action."))

      let resp = await testAspect.getGenerations({ from: accounts[0] })
      expect(resp.map(objectify)).to(consistOf([
        matchFields({
          "id":              beNumber(1),
          "begin_timestamp": beNumber(unixTime),
          "end_timestamp":   beNumber(unixTime + 30 * day),
          "approvers":       consistOf([accounts[3]]),
        }),
        matchFields({
          "id":              beNumber(2),
          "begin_timestamp": beNumber(unixTime),
          "end_timestamp":   beNumber(unixTime + 30 * day),
          "approvers":       consistOf([accounts[4]]),
        }),
      ]))
    })
  })
  describe("Requests", () => {

    newGenerations = async (num) => {
      for (let n = 1; n <= num; n++)
        await testAspect.newGeneration(asEthWord(n), unixTime, unixTime + 30 * day, fromOwner)
    }

    it("should allow granting requested aspects", async () => {
      await newGenerations(1)

      const numUsers = 5;
      for (let n = 0; n < numUsers; n++) await testAspect.request(
        asEthWord(1),
        asEthBytes(`details ${n}`,20),
        asEthWord(`content ${n}`),
        { from: accounts[n + 1] }
      )
    })
  })
})
