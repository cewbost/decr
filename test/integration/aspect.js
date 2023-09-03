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
  beEmpty,
  matchElements
} = require("./matchers/matchers.js")
const { asEthWord, asEthBytes } = require("./utils/ethword.js")
const { objectify } = require("./utils/objectify.js")
const { day } = require("./utils/time.js")
const { awaitException } = require("./utils/exception.js")
const { split } = require("./utils/split.js")

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

    it("should allow granting requested aspects, single user and generation", async () => {
      await newGenerations(1)
      const numRequests = 5
      for (let n = 0; n < numRequests; n++) await testAspect.request(
        asEthWord(1),
        asEthBytes(`details ${n}`, 24),
        asEthWord(`content ${n}`),
        { from: accounts[1] }
      )

      let matchRecord = (num) => matchFields({
        "recipient": accounts[1],                  
        "details":   asEthBytes(`details ${num}`,  24),
        "content":   asEthWord(`content ${num}`), 
      })
      let records = (await testAspect.getPendingRecordsByGeneration(asEthWord(1))).map(objectify)
      expect(records).to(consistOf([
        matchRecord(0),
        matchRecord(1),
        matchRecord(2),
        matchRecord(3),
        matchRecord(4),
      ]))

      let st = new Set([asEthWord(`content 0`), asEthWord(`content 2`), asEthWord(`content 4`)])
      let sp = split(records, rec => st.has(rec.content))
      for (let rec of sp[true]) await testAspect.grant(rec.hash)

      let matchPending = consistOf([matchRecord(1), matchRecord(3)])
      let matchGranted = consistOf([matchRecord(0), matchRecord(2), matchRecord(4)])
      expect((await testAspect.getPendingRecordsByGeneration(asEthWord(1))).map(objectify))
        .to(matchPending)
      expect((await testAspect.getRecordsByGeneration(asEthWord(1))).map(objectify))
        .to(matchGranted)
      expect((await testAspect.getPendingRecordsByRecipient(accounts[1])).map(objectify))
        .to(matchPending)
      expect((await testAspect.getRecordsByRecipient(accounts[1])).map(objectify))
        .to(matchGranted)
    })
    it("should allow granting requested aspects, multiple users and generations", async () => {
      const numGenerations = 5
      const numAccounts    = 5
      await newGenerations(numGenerations)
      for (let g = 1; g <= numGenerations; g++) for (let a = 1; a <= numAccounts; a++) {
        await testAspect.request(
          asEthWord(g),
          asEthBytes("details", 24),
          asEthWord("content"),
          { from: accounts[a] }
        )
      }

      let matchRecord = (acc, gen) => matchFields({
        "recipient":  accounts[acc],                  
        "generation": asEthWord(gen),
        "details":    asEthBytes("details",  24),
        "content":    asEthWord("content"), 
      })
      let matchGenWithAccs = (gen, accs) => consistOf(accs.map(arg => matchRecord(arg, gen)))
      let matchAccWithGens = (acc, gens) => consistOf(gens.map(arg => matchRecord(acc, arg)))

      let gensRecs = new Array(5)
      gensRecs[0] = (await testAspect.getPendingRecordsByGeneration(asEthWord(1))).map(objectify)
      gensRecs[1] = (await testAspect.getPendingRecordsByGeneration(asEthWord(2))).map(objectify)
      gensRecs[2] = (await testAspect.getPendingRecordsByGeneration(asEthWord(3))).map(objectify)
      gensRecs[3] = (await testAspect.getPendingRecordsByGeneration(asEthWord(4))).map(objectify)
      gensRecs[4] = (await testAspect.getPendingRecordsByGeneration(asEthWord(5))).map(objectify)
      expect(gensRecs[0]).to(matchGenWithAccs(1, [1, 2, 3, 4, 5]))
      expect(gensRecs[1]).to(matchGenWithAccs(2, [1, 2, 3, 4, 5]))
      expect(gensRecs[2]).to(matchGenWithAccs(3, [1, 2, 3, 4, 5]))
      expect(gensRecs[3]).to(matchGenWithAccs(4, [1, 2, 3, 4, 5]))
      expect(gensRecs[4]).to(matchGenWithAccs(5, [1, 2, 3, 4, 5]))
      expect((await testAspect.getPendingRecordsByRecipient(accounts[1])).map(objectify))
        .to(matchAccWithGens(1, [1, 2, 3, 4, 5]))
      expect((await testAspect.getPendingRecordsByRecipient(accounts[2])).map(objectify))
        .to(matchAccWithGens(2, [1, 2, 3, 4, 5]))
      expect((await testAspect.getPendingRecordsByRecipient(accounts[3])).map(objectify))
        .to(matchAccWithGens(3, [1, 2, 3, 4, 5]))
      expect((await testAspect.getPendingRecordsByRecipient(accounts[4])).map(objectify))
        .to(matchAccWithGens(4, [1, 2, 3, 4, 5]))
      expect((await testAspect.getPendingRecordsByRecipient(accounts[5])).map(objectify))
        .to(matchAccWithGens(5, [1, 2, 3, 4, 5]))

      for (let [idx, recs] of gensRecs.entries()) {
        let accs = new Set(accounts.slice(1, 1 + numAccounts - idx))
        for (let rec of recs.filter(r => accs.has(r.recipient))) await testAspect.grant(rec.hash)
      }

      expect((await testAspect.getPendingRecordsByGeneration(asEthWord(1))).map(objectify))
        .to(beEmpty())
      expect((await testAspect.getPendingRecordsByGeneration(asEthWord(2))).map(objectify))
        .to(matchGenWithAccs(2, [5]))
      expect((await testAspect.getPendingRecordsByGeneration(asEthWord(3))).map(objectify))
        .to(matchGenWithAccs(3, [4, 5]))
      expect((await testAspect.getPendingRecordsByGeneration(asEthWord(4))).map(objectify))
        .to(matchGenWithAccs(4, [3, 4, 5]))
      expect((await testAspect.getPendingRecordsByGeneration(asEthWord(5))).map(objectify))
        .to(matchGenWithAccs(5, [2, 3, 4, 5]))

      expect((await testAspect.getPendingRecordsByRecipient(accounts[1])).map(objectify))
        .to(beEmpty())
      expect((await testAspect.getPendingRecordsByRecipient(accounts[2])).map(objectify))
        .to(matchAccWithGens(2, [5]))
      expect((await testAspect.getPendingRecordsByRecipient(accounts[3])).map(objectify))
        .to(matchAccWithGens(3, [4, 5]))
      expect((await testAspect.getPendingRecordsByRecipient(accounts[4])).map(objectify))
        .to(matchAccWithGens(4, [3, 4, 5]))
      expect((await testAspect.getPendingRecordsByRecipient(accounts[5])).map(objectify))
        .to(matchAccWithGens(5, [2, 3, 4, 5]))

      expect((await testAspect.getRecordsByGeneration(asEthWord(1))).map(objectify))
        .to(matchGenWithAccs(1, [1, 2, 3, 4, 5]))
      expect((await testAspect.getRecordsByGeneration(asEthWord(2))).map(objectify))
        .to(matchGenWithAccs(2, [1, 2, 3, 4]))
      expect((await testAspect.getRecordsByGeneration(asEthWord(3))).map(objectify))
        .to(matchGenWithAccs(3, [1, 2, 3]))
      expect((await testAspect.getRecordsByGeneration(asEthWord(4))).map(objectify))
        .to(matchGenWithAccs(4, [1, 2]))
      expect((await testAspect.getRecordsByGeneration(asEthWord(5))).map(objectify))
        .to(matchGenWithAccs(5, [1]))

      expect((await testAspect.getRecordsByRecipient(accounts[1])).map(objectify))
        .to(matchAccWithGens(1, [1, 2, 3, 4, 5]))
      expect((await testAspect.getRecordsByRecipient(accounts[2])).map(objectify))
        .to(matchAccWithGens(2, [1, 2, 3, 4]))
      expect((await testAspect.getRecordsByRecipient(accounts[3])).map(objectify))
        .to(matchAccWithGens(3, [1, 2, 3]))
      expect((await testAspect.getRecordsByRecipient(accounts[4])).map(objectify))
        .to(matchAccWithGens(4, [1, 2]))
      expect((await testAspect.getRecordsByRecipient(accounts[5])).map(objectify))
        .to(matchAccWithGens(5, [1]))
    })
  })
})
