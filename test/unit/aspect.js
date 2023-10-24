const AspectBare = artifacts.require("AspectBare")
const { day } = require("../utils/time.js")
const { asEthWord, asEthBytes } = require("../../utils/ethword.js")
const { objectify } = require("../utils/containers.js")
const { awaitException } = require("../utils/exception.js")
const {
  expect,
  equal,
  matchFields,
  consistOf,
  beApprox,
  beInstanceOf,
  beEmpty,
  beNumber,
} = require("../matchers/matchers.js")

contract("Aspect", accounts => {

  let testAspect

  let now
  let fromOwner = { from: accounts[0] }

  beVMException = (msg) => beInstanceOf(Error).and(matchFields({
    "data": matchFields({
      "reason": msg
    }),
  }))

  beforeEach(async () => {
    now = Math.floor(Date.now() / 1000)
    testAspect = await AspectBare.new(asEthWord("TestAspect"), accounts[0])
  })
  describe("request", () => {
    beforeEach(async () => {
      await testAspect.insertGeneration(asEthWord(1), now, now + 10 * day, [])
      await testAspect.insertGeneration(asEthWord(2), now, now + 10 * day, [])
      await testAspect.insertGeneration(asEthWord(3), now - 10 * day, now - 5 * day, [])
      await testAspect.insertGeneration(asEthWord(4), now + 5 * day, now + 10 * day, [])
    })
    it("should store multiple distinct records", async () => {
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
      })).to(beVMException("generation does not exist"))
    })
    it("should not allow requesting from inactive generation", async () => {
      expect(await awaitException(() => {
        return testAspect.request(
          asEthWord(3),
          asEthBytes("details", 24),
          asEthWord("content"),
          { from: accounts[1] }
        )
      })).to(beVMException("generation inactive"))
    })
    it("should not allow requesting from expired generation", async () => {
      expect(await awaitException(() => {
        return testAspect.request(
          asEthWord(4),
          asEthBytes("details", 24),
          asEthWord("content"),
          { from: accounts[1] }
        )
      })).to(beVMException("generation inactive"))
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
      })).to(beVMException("already exists"))
    })
  })
  describe("grant", () => {

    let hash

    beforeEach(async () => {
      await testAspect.insertGeneration(asEthWord(1), now - 10 * day, now + 10 * day, [])
      await testAspect.setApprovers([
        accounts[2],
        accounts[3],
        accounts[4],
        accounts[5],
        accounts[6]
      ], [])
      await testAspect.insertPendingRecord(
        accounts[1],
        asEthWord(1),
        now - 10 * day,
        asEthBytes("details", 24),
        asEthWord("content"),
        [accounts[2], accounts[4], accounts[6]]
      )
      hash = (await testAspect.getPendingRecordsByGeneration(asEthWord(1)))[0].hash
    })
    it("should emit grant event and remove the record from pending", async () => {
      expect((await testAspect.grant(hash, fromOwner)).logs).to(consistOf([
        matchFields({
          "event": "AspectGranted",
          "args": matchFields({
            "recipient":  accounts[1],
            "generation": asEthWord(1),
            "details":    asEthBytes("details", 24),
            "content":    asEthWord("content"),
            "approvers":  "0x15",
          }),
        })
      ]))

      let match = consistOf([matchFields({
        "recipient":  accounts[1],
        "generation": asEthWord(1),
        "details":    asEthBytes("details", 24),
        "content":    asEthWord("content"),
        "approvers":  consistOf([accounts[2], accounts[4], accounts[6]]),
        "timestamp":  beApprox(now, 5),
      })])
      expect(await testAspect.getPendingRecordsByGeneration(asEthWord(1))).to(beEmpty())
    })
    it("should only allow owner to grant", async () => {
      expect(await awaitException(() => {
        return testAspect.grant(hash, { from: accounts[1] })
      })).to(beVMException("only owner can perform this action"))
    })
    it("should not allow granting aspect more than once", async () => {
      await testAspect.grant(hash, fromOwner)

      expect(await awaitException(() => {
        return testAspect.grant(hash, fromOwner)
      })).to(beVMException("record not pending"))
    })
    it("should fail if record doesn't exist", async () => {
      expect(await awaitException(() => {
        return testAspect.grant(asEthWord(1), fromOwner)
      })).to(beVMException("record does not exist"))
    })
    it("should not allow granting after generation is expired", async () => {
      await testAspect.insertGeneration(asEthWord(2), now - 20 * day, now - 10 * day, [])
      await testAspect.insertPendingRecord(
        accounts[1],
        asEthWord(2),
        now - 15 * day,
        asEthBytes("details", 24),
        asEthWord("content"),
        []
      )
      hash = (await testAspect.getPendingRecordsByGeneration(asEthWord(2)))[0].hash

      expect(await awaitException(() => {
        return testAspect.grant(hash, fromOwner)
      })).to(beVMException("generation inactive"))
    })
  })
  describe("approve", () => {

    let hash

    beforeEach(async () => {
      await testAspect.setApprovers(accounts.slice(2, 6), [accounts[3], accounts[5]])
      await testAspect.insertGeneration(asEthWord(1), now, now + 10 * day, accounts.slice(4, 6))
      await testAspect.insertPendingRecord(
        accounts[1],
        asEthWord(1),
        now - 10 * day,
        asEthBytes("details 1", 24),
        asEthWord("content 1"),
        []
      )
      hash = (await testAspect.getPendingRecordsByGeneration(asEthWord(1)))[0].hash
    })
    it("should add approvals to the record", async () => {
      await testAspect.approve(hash, { from: accounts[4] })
      await testAspect.approve(hash, { from: accounts[5] })

      let resp = (await testAspect.getPendingRecordsByGeneration(asEthWord(1))).map(objectify)
      expect(resp.length).to(equal(1))
      expect(resp[0]).to(matchFields({
        "hash":      hash,
        "approvers": consistOf(accounts.slice(4, 6)),
      }))
    })
    it("should fail if record sender is not approver", async () => {
      expect(await awaitException(() => {
        return testAspect.approve(hash, { from: accounts[2] })
      })).to(beVMException("only approver can perform this action"))
      expect(await awaitException(() => {
        return testAspect.approve(hash, { from: accounts[3] })
      })).to(beVMException("only approver can perform this action"))
    })
    it("should fail if record does not exist", async () => {
      expect(await awaitException(() => {
        return testAspect.approve(asEthWord(1), { from: accounts[4] })
      })).to(beVMException("record does not exist"))
    })
    it("should not allow approving after generation is expired", async () => {
      await testAspect.insertGeneration(asEthWord(2), now - 20 * day, now - 10 * day, [accounts[2]])
      await testAspect.setApprovers([accounts[2]], [])
      await testAspect.insertPendingRecord(
        accounts[1],
        asEthWord(2),
        now - 15 * day,
        asEthBytes("details 1", 24),
        asEthWord("content 1"),
        []
      )
      hash = (await testAspect.getPendingRecordsByGeneration(asEthWord(2)))[0].hash

      expect(await awaitException(() => {
        return testAspect.approve(hash, { from: accounts[2] })
      })).to(beVMException("generation inactive"))
    })
  })
  describe("newGeneration", () => {
    it("should emit new generation event and add a new generation", async () => {
      await testAspect.setApprovers([
        accounts[2],
        accounts[3],
        accounts[4],
        accounts[5],
        accounts[6]
      ], [
        accounts[2],
        accounts[4],
        accounts[6]
      ])
      let logs = (await testAspect.newGeneration(asEthWord(1), now, now + 10 * day, fromOwner)).logs
      expect(logs).to(consistOf([
        matchFields({
          "event": "NewGeneration",
          "args": matchFields({
            "id": asEthWord(1),
          })
        })
      ]))
      expect(objectify(await testAspect.getGeneration(asEthWord(1), fromOwner))).to(matchFields({
        "id":              asEthWord(1),
        "begin_timestamp": beNumber(now),
        "end_timestamp":   beNumber(now + 10 * day),
        "approvers":       consistOf([accounts[2], accounts[4], accounts[6]]),
      }))
    })
    it("should not allow creating multiple generations with same id", async () => {
      await testAspect.newGeneration(asEthWord(1), now, now + 10 * day, fromOwner)
      expect(await awaitException(() => {
        return testAspect.newGeneration(asEthWord(1), now, now + 10 * day, fromOwner)
      })).to(beVMException("already exists"))
    })
    it("should not allow creating generations with end timestamp before beginning", async () => {
      expect(await awaitException(() => {
        return testAspect.newGeneration(asEthWord(1), now + 10 * day, now, fromOwner)
      })).to(beVMException("ending must be before beginning"))
    })
    it("should only allow owner to create generations", async () => {
      expect(await awaitException(() => {
        return testAspect.newGeneration(asEthWord(1), now, now + 10 * day, { from: accounts[1]})
      })).to(beVMException("only owner can perform this action"))
    })
  })
  describe("clearGeneration", () => {
    beforeEach(async () => {
      await testAspect.insertGeneration(asEthWord(1), now - 10 * day, now - day, [])
      await testAspect.insertGeneration(asEthWord(2), now - 10 * day, now - day, [])
      await testAspect.insertGeneration(asEthWord(3), now - 10 * day, now + 10 * day, [])
      await testAspect.insertPendingRecord(
        accounts[1],
        asEthWord(1),
        now - 10 * day,
        asEthBytes("details", 24),
        asEthWord("content"),
        []
      )
    })
    it("should remove pending records from cleared generation", async () => {
      let addPendingRecord = async (gen, details) => {
        await testAspect.insertPendingRecord(
          accounts[1],
          asEthWord(gen),
          now - day,
          asEthBytes(details, 24),
          asEthWord(""),
          []
        )
      }
      let matchRecord = (gen, details) => matchFields({
        "generation": asEthWord(gen),
        "details":    asEthBytes(details, 24),
      })

      await addPendingRecord(1, "det 1")
      await addPendingRecord(2, "det 2")
      await addPendingRecord(1, "det 3")
      await addPendingRecord(2, "det 4")

      await testAspect.clearGeneration(asEthWord(1))

      let resp = (await testAspect.getPendingRecordsByGeneration(asEthWord(1))).map(objectify)
      expect(resp).to(beEmpty())
      resp = (await testAspect.getPendingRecordsByGeneration(asEthWord(2))).map(objectify)
      expect(resp).to(consistOf([matchRecord(2, "det 2"), matchRecord(2, "det 4")]))
    })
    it("should only allow owner to clear generations", async () => {
      expect(await awaitException(() => {
        return testAspect.clearGeneration(asEthWord(1), {from: accounts[1]})
      })).to(beVMException("only owner can perform this action"))
    })
    it("should fail if generation doesn't exist", async () => {
      expect(await awaitException(() => {
        return testAspect.clearGeneration(asEthWord(4), {from: accounts[1]})
      })).to(beVMException("only owner can perform this action"))
    })
    it("should fail if generation hasn't expired", async () => {
      expect(await awaitException(() => {
        return testAspect.clearGeneration(asEthWord(3), {from: accounts[1]})
      })).to(beVMException("only owner can perform this action"))
    })
  })
  describe("enableApprover", async () => {
    it("should add approvers to approvers list and index", async () => {
      await testAspect.setApprovers(accounts.slice(1, 4), [accounts[3]])

      await testAspect.enableApprover(accounts[2])
      await testAspect.enableApprover(accounts[3])
      await testAspect.enableApprover(accounts[4])

      let resp = (await testAspect.getApprovers()).map(objectify)
      expect(resp).to(consistOf([
        matchFields({
          "approver": accounts[1],
          "enabled":  false,
        }),
        matchFields({
          "approver": accounts[2],
          "enabled":  true,
        }),
        matchFields({
          "approver": accounts[3],
          "enabled":  true,
        }),
        matchFields({
          "approver": accounts[4],
          "enabled":  true,
        }),
      ]))
    })
    it("should only allow owner to enable approvers", async () => {
      expect(await awaitException(() => {
        return testAspect.enableApprover(accounts[2], {from: accounts[1]})
      })).to(beVMException("only owner can perform this action"))
    })
  })
  describe("enableApproverForGeneration", async () => {
    beforeEach(async () => {
      await testAspect.insertGeneration(asEthWord(1), now, now + 10 * day, [])
    })
    it("should enable approvers for a generation", async () => {
      await testAspect.setApprovers(accounts.slice(1, 3), [])

      await testAspect.enableApproverForGeneration(accounts[2], asEthWord(1))
      await testAspect.enableApproverForGeneration(accounts[3], asEthWord(1))

      let resp = (await testAspect.getApprovers()).map(objectify)
      expect(resp).to(consistOf([
        matchFields({
          "approver": accounts[1],
          "enabled":  false,
        }),
        matchFields({
          "approver": accounts[2],
          "enabled":  false,
        }),
        matchFields({
          "approver": accounts[3],
          "enabled":  false,
        }),
      ]))
      expect(objectify(await testAspect.getGeneration(asEthWord(1), fromOwner))).to(matchFields({
        "id":        asEthWord(1),
        "approvers": consistOf(accounts.slice(2, 4)),
      }))
    })
    it("should only allow owner to enable approvers for a generation", async () => {
      expect(await awaitException(() => {
        return testAspect.enableApproverForGeneration(
          accounts[2],
          asEthWord(1),
          { from: accounts[1] }
        )
      })).to(beVMException("only owner can perform this action"))
    })
    it("should fail if generation doesn't exist", async () => {
      expect(await awaitException(() => {
        return testAspect.enableApproverForGeneration(accounts[1], asEthWord(2))
      })).to(beVMException("generation does not exist"))
    })
    it("should only allow owner to enable approvers for a generation", async () => {
      await testAspect.insertGeneration(asEthWord(2), now - 10 * day, now - day, [])
      expect(await awaitException(() => {
        return testAspect.enableApproverForGeneration(accounts[1], asEthWord(2))
      })).to(beVMException("generation is expired"))
    })
  })
  describe("disableApprover", () => {
    it("should disable approvers", async () => {
      await testAspect.setApprovers(accounts.slice(1, 4), accounts.slice(1, 4))

      await testAspect.disableApprover(accounts[2])

      let resp = (await testAspect.getApprovers()).map(objectify)
      expect(resp).to(consistOf([
        matchFields({
          "approver": accounts[1],
          "enabled":  true,
        }),
        matchFields({
          "approver": accounts[2],
          "enabled":  false,
        }),
        matchFields({
          "approver": accounts[3],
          "enabled":  true,
        }),
      ]))
    })
    it("should only allow owner to disable approver", async () => {
      expect(await awaitException(() => {
        return testAspect.disableApprover(accounts[1], { from: accounts[1] })
      })).to(beVMException("only owner can perform this action"))
    })
  })
  describe("disableApproverForGeneration", async () => {
    beforeEach(async () => {
      await testAspect.setApprovers(accounts.slice(1, 4), [])
      await testAspect.insertGeneration(asEthWord(1), now, now + 10 * day, accounts.slice(1, 4))
    })
    it("should enable approvers for a generation", async () => {
      await testAspect.disableApproverForGeneration(accounts[1], asEthWord(1))
      await testAspect.disableApproverForGeneration(accounts[3], asEthWord(1))

      let resp = (await testAspect.getApprovers()).map(objectify)
      expect(resp).to(consistOf([
        matchFields({
          "approver": accounts[1],
          "enabled":  false,
        }),
        matchFields({
          "approver": accounts[2],
          "enabled":  false,
        }),
        matchFields({
          "approver": accounts[3],
          "enabled":  false,
        }),
      ]))
      expect(objectify(await testAspect.getGeneration(asEthWord(1), fromOwner))).to(matchFields({
        "id":        asEthWord(1),
        "approvers": consistOf([accounts[2]]),
      }))
    })
    it("should only allow owner to disable approvers for a generation", async () => {
      expect(await awaitException(() => {
        return testAspect.disableApproverForGeneration(
          accounts[2],
          asEthWord(1),
          { from: accounts[1] }
        )
      })).to(beVMException("only owner can perform this action"))
    })
    it("should fail if generation doesn't exist", async () => {
      expect(await awaitException(() => {
        return testAspect.disableApproverForGeneration(accounts[1], asEthWord(2))
      })).to(beVMException("generation does not exist"))
    })
    it("should only allow owner to disable approvers for a generation", async () => {
      await testAspect.insertGeneration(asEthWord(2), now - 10 * day, now - day, [])
      expect(await awaitException(() => {
        return testAspect.disableApproverForGeneration(accounts[1], asEthWord(2))
      })).to(beVMException("generation is expired"))
    })
  })
  describe("changeOwnership", () => {
    it("should only allow owner to change owner", async () => {
      expect(await awaitException(() => {
        return testAspect.changeOwnership(accounts[2], { from: accounts[1] })
      })).to(beVMException("only owner can perform this action"))
    })
    it("should allow owner to change owner", async () => {
      await testAspect.changeOwnership(accounts[1], { from: accounts[0] })
      expect(await awaitException(() => {
        return testAspect.changeOwnership(accounts[2], { from: accounts[0] })
      })).to(beVMException("only owner can perform this action"))
      await testAspect.changeOwnership(accounts[2], { from: accounts[1] })
      expect(await awaitException(() => {
        return testAspect.changeOwnership(accounts[3], { from: accounts[1] })
      })).to(beVMException("only owner can perform this action"))
    })
  })
})
