const Aspect = artifacts.require("Aspect")
const { BigNumber } = require("bignumber.js")
const { asEthWord, asEthBytes } = require("../utils/ethword.js")
const { objectify, split } = require("../utils/containers.js")
const { day } = require("../utils/time.js")
const { awaitException } = require("../utils/exception.js")
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
} = require("../matchers/matchers.js")

contract("Aspect -- integration", accounts => {

  beVMException = (msg) => beInstanceOf(Error).and(matchFields({
    "data": matchFields({
      "reason": msg
    }),
  }))

  matchGrantEvent = (acc, gen, details, content, approvers) => matchFields({
    "event": "AspectGranted",
    "args": matchFields({
      "recipient":  acc,
      "generation": asEthWord(gen),
      "details":    asEthBytes(details, 24),
      "content":    asEthWord(content),
      "approvers":  approvers,
    }),
  })

  let testAspect

  let unixTime = Math.floor(Date.now() / 1000)
  let fromOwner = { from: accounts[0] }

  beforeEach(async () => {
    testAspect = await Aspect.new("TestAspect", fromOwner)
  })

  describe("Management", () => {
    it("should allow setting approvers by generation", async () => {
      await testAspect.newGeneration(
        asEthWord(1),
        unixTime,
        unixTime + 30 * day,
        fromOwner
      )
      await testAspect.newGeneration(
        asEthWord(2),
        unixTime + 15 * day,
        unixTime + 45 * day,
        fromOwner
      )

      await testAspect.enableApproverForGeneration(accounts[1], asEthWord(1), fromOwner)
      await testAspect.enableApproverForGeneration(accounts[2], asEthWord(1), fromOwner)
      await testAspect.enableApproverForGeneration(accounts[1], asEthWord(2), fromOwner)

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
          "approvers":       consistOf([accounts[1]]),
        }),
      ]))

      await testAspect.disableApproverForGeneration(accounts[1], asEthWord(1), fromOwner)
      await testAspect.disableApproverForGeneration(accounts[1], asEthWord(2), fromOwner)

      resp = await testAspect.getGenerations(fromOwner)
      expect(resp.map(objectify)).to(consistOf([
        matchFields({
          "id":              beNumber(1),
          "begin_timestamp": beNumber(unixTime),
          "end_timestamp":   beNumber(unixTime + 30 * day),
          "approvers":       consistOf([accounts[2]]),
        }),
        matchFields({
          "id":              beNumber(2),
          "begin_timestamp": beNumber(unixTime + 15 * day),
          "end_timestamp":   beNumber(unixTime + 45 * day),
          "approvers":       beEmpty(),
        }),
      ]))
    })
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
      })).to(beVMException("Only owner can perform this action"))
      expect(await awaitException(() => {
        return testAspect.enableApprover(accounts[4], { from: accounts[0] })
      })).to(beVMException("Only owner can perform this action"))
      expect(await awaitException(() => {
        return testAspect.enableApproverForGeneration(
          accounts[4],
          asEthWord(1),
          { from: accounts[0] }
        )
      })).to(beVMException("Only owner can perform this action"))
      expect(await awaitException(() => {
        return testAspect.disableApprover(accounts[3], { from: accounts[0] })
      })).to(beVMException("Only owner can perform this action"))
      expect(await awaitException(() => {
        return testAspect.disableApproverForGeneration(
          accounts[3],
          asEthWord(1),
          { from: accounts[0] }
        )
      })).to(beVMException("Only owner can perform this action"))

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
        return testAspect.enableApprover(accounts[5], { from: accounts[1] })
      })).to(beVMException("Only owner can perform this action"))

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
      let logs = []
      for (let rec of sp[true]) logs.push(...(await testAspect.grant(rec.hash)).logs)

      expect(logs).to(consistOf([
        matchGrantEvent(accounts[1], 1, "details 0", "content 0"),
        matchGrantEvent(accounts[1], 1, "details 2", "content 2"),
        matchGrantEvent(accounts[1], 1, "details 4", "content 4"),
      ]))
      let matchPending = consistOf([matchRecord(1), matchRecord(3)])
      expect((await testAspect.getPendingRecordsByGeneration(asEthWord(1))).map(objectify))
        .to(matchPending)
      expect((await testAspect.getPendingRecordsByRecipient(accounts[1])).map(objectify))
        .to(matchPending)
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

      let getRecords = async (fn, num) => {
        let res = new Array(num)
        for (let n = 1; n <= num; n++) res[n - 1] = (await fn(n)).map(objectify)
        return res
      }
      let getPendingRecordsByGenerations = () =>
        getRecords(n => testAspect.getPendingRecordsByGeneration(asEthWord(n)), numGenerations)
      let getPendingRecordsByRecipients = () =>
        getRecords(n => testAspect.getPendingRecordsByRecipient(accounts[n]), numGenerations)

      let gensRecs = await getPendingRecordsByGenerations()
      expect(gensRecs).to(matchElements([
        matchGenWithAccs(1, [1, 2, 3, 4, 5]),
        matchGenWithAccs(2, [1, 2, 3, 4, 5]),
        matchGenWithAccs(3, [1, 2, 3, 4, 5]),
        matchGenWithAccs(4, [1, 2, 3, 4, 5]),
        matchGenWithAccs(5, [1, 2, 3, 4, 5]),
      ]))
      expect(await getPendingRecordsByRecipients()).to(matchElements([
        matchAccWithGens(1, [1, 2, 3, 4, 5]),
        matchAccWithGens(2, [1, 2, 3, 4, 5]),
        matchAccWithGens(3, [1, 2, 3, 4, 5]),
        matchAccWithGens(4, [1, 2, 3, 4, 5]),
        matchAccWithGens(5, [1, 2, 3, 4, 5]),
      ]))

      let logs = []
      for (let [idx, recs] of gensRecs.entries()) {
        let accs = new Set(accounts.slice(1, 1 + numAccounts - idx))
        for (let rec of recs.filter(r => accs.has(r.recipient))) {
          logs.push(...(await testAspect.grant(rec.hash)).logs)
        }
      }

      let matchGrantEvents = (account, gens) =>
        gens.map(gen => matchGrantEvent(account, gen, "details", "content"))

      expect(logs).to(consistOf([
        ...matchGrantEvents(accounts[1], [1, 2, 3, 4, 5]),
        ...matchGrantEvents(accounts[2], [1, 2, 3, 4]),
        ...matchGrantEvents(accounts[3], [1, 2, 3]),
        ...matchGrantEvents(accounts[4], [1, 2]),
        ...matchGrantEvents(accounts[5], [1]),
      ]))
      expect(await getPendingRecordsByGenerations()).to(matchElements([
        beEmpty(),
        matchGenWithAccs(2, [5]),
        matchGenWithAccs(3, [4, 5]),
        matchGenWithAccs(4, [3, 4, 5]),
        matchGenWithAccs(5, [2, 3, 4, 5]),
      ]))
      expect(await getPendingRecordsByRecipients()).to(matchElements([
        beEmpty(),
        matchAccWithGens(2, [5]),
        matchAccWithGens(3, [4, 5]),
        matchAccWithGens(4, [3, 4, 5]),
        matchAccWithGens(5, [2, 3, 4, 5]),
      ]))
    })
    it("should not allow non-owners to grant requests", async () => {
      await testAspect.enableApprover(accounts[1], fromOwner)
      await testAspect.newGeneration(
        asEthWord(1),
        unixTime,
        unixTime + 30 * day,
        fromOwner
      )
      await testAspect.request(
        asEthWord(1),
        asEthBytes("details", 24),
        asEthWord("content"),
        { from: accounts[2] }
      )
      let hash = (await testAspect.getPendingRecordsByGeneration(asEthWord(1)))
        .map(objectify)[0].hash

      for (let acc of accounts.slice(1, 4)) {
        expect(await awaitException(() => {
          return testAspect.grant(hash, { from: acc })
        })).to(beVMException("Only owner can perform this action"))
      }
    })
    it("should not allow approving resubmitting already granted request", async () => {
      await testAspect.newGeneration(
        asEthWord(1),
        unixTime,
        unixTime + 30 * day,
        fromOwner
      )
      await testAspect.request(
        asEthWord(1),
        asEthBytes("details", 24),
        asEthWord("content"),
        { from: accounts[2] }
      )
      let hash = (await testAspect.getPendingRecordsByGeneration(asEthWord(1)))
        .map(objectify)[0].hash
      await testAspect.grant(hash, fromOwner)

      expect(await awaitException(() => {
        return testAspect.request(
          asEthWord(1),
          asEthBytes("details", 24),
          asEthWord("content"),
          { from: accounts[2] }
        )
      })).to(beVMException("Already exists"))
    })
  })
  describe("Approvers", () => {

    let approvers

    beforeEach(async () => {
      approvers = accounts.slice(1, 4)
      for (let app of approvers) await testAspect.enableApprover(app, fromOwner)
      await testAspect.newGeneration(
        asEthWord(1),
        unixTime,
        unixTime + 30 * day,
        fromOwner
      )
    })
    it("should allow approving requests", async () => {
      for (let acc of accounts.slice(4, 7)) await testAspect.request(
        asEthWord(1),
        asEthBytes("details", 24),
        asEthWord("content"),
        { from: acc }
      )
      let recs = (await testAspect.getPendingRecordsByGeneration(asEthWord(1))).map(objectify)
      let hashes = accounts.slice(4, 7)
        .map(acc => recs.filter(rec => rec.recipient == acc)[0].hash)

      for (let [idx, hash] of hashes.entries()) for (let app of approvers.slice(0, idx + 1))
        await testAspect.approve(hash, { from: app })

      recs = (await testAspect.getPendingRecordsByGeneration(asEthWord(1))).map(objectify)
      expect(recs).to(consistOf([
        matchFields({
          "hash":      hashes[0],
          "approvers": consistOf(approvers.slice(0, 1)),
        }),
        matchFields({
          "hash":      hashes[1],
          "approvers": consistOf(approvers.slice(0, 2)),
        }),
        matchFields({
          "hash":      hashes[2],
          "approvers": consistOf(approvers.slice(0, 3)),
        }),
      ]))

      let logs = []
      for (let hash of hashes) logs.push(...(await testAspect.grant(hash)).logs)
      expect(logs).to(consistOf([
        matchGrantEvent(accounts[4], 1, "details", "content", "0x01"),
        matchGrantEvent(accounts[5], 1, "details", "content", "0x03"),
        matchGrantEvent(accounts[6], 1, "details", "content", "0x07"),
      ]))
    })
    it("should not allow approving already granted request", async () => {
      await testAspect.request(
        asEthWord(1),
        asEthBytes("details", 24),
        asEthWord("content"),
        { from: accounts[4] }
      )
      let hash = (await testAspect.getPendingRecordsByGeneration(asEthWord(1)))
        .map(objectify)[0].hash
      await testAspect.grant(hash, fromOwner)

      expect(await awaitException(() => {
        return testAspect.approve(hash, { from: accounts[1] })
      })).to(beVMException("Record not pending"))
    })
  })
})
