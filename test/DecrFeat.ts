const DecrFeat = artifacts.require("DecrFeat")

contract("DecrFeat", accounts => {

  let testFeat;

  before(async () => {
    testFeat = await DecrFeat.new("testDecr", { from: accounts[0] })
  })

  describe("initial state", () => {
    it("should not have any propsals or reciepts assigned to arbitrary account", async () => {
      assert(!(await testFeat.proposals(accounts[1])), "arbitrary user has proposal")
      assert(!(await testFeat.recipients(accounts[1])), "arbitrary user has recieved feat")
    })
  })
  describe("propose", () => {
    it("should record proposals", async () => {
      await testFeat.propose(accounts[2])
      assert(await testFeat.proposals(accounts[2]), "account has not recieved proposal")
      assert(!(await testFeat.recipients(accounts[2])), "account has been recorded as recipient")
    })
    it("should not allow anyone other than owner to make proposals", async () => {
      let err = null
      try {
        await testFeat.propose(accounts[0], { from: accounts[1] })
      } catch (e) {
        err = e
      }
      assert.instanceOf(err, Error, "propose from account other than owner should fail")
      assert(!(await testFeat.proposals[0]), "proposal was recorded")
    })
    it("should not allow making multiple proposals to accounts", async () => {
      let err = null
      try {
        await testFeat.propose(accounts[3])
        await testFeat.propose(accounts[3])
      } catch(e) {
        err = e
      }
      assert.instanceOf(err, Error, "multiple proposals should fail")
    })
  })
  describe("accept", () => {
    it("should record the recipient", async () => {
      await testFeat.propose(accounts[4])
      await testFeat.accept({ from: accounts[4] })

      assert(!(await testFeat.proposals(accounts[4])), "the proposal should be removed")
      assert(await testFeat.recipients(accounts[4]), "the recipient should be recorded")
    })
    it("should fail if no proposal has been made", async () => {
      let err = null
      try {
        await testFeat.accept({ from: accounts[5] })
      } catch(e) {
        err = e
      }
      assert.instanceOf(err, Error, "accepting the feat should fail")
    })
  })
  describe("reject", () => {
    it("should remove the proposal", async () => {
      await testFeat.propose(accounts[6])
      await testFeat.reject({ from: accounts[6] })

      assert(!(await testFeat.proposals(accounts[6])), "the proposal should be removed")
      assert(!(await testFeat.recipients(accounts[6])), "the recipient should not be recorded")
    })
    it("should fail if no proposal has been made", async () => {
      let err = null
      try {
        await testFeat.reject({ from: accounts[7] })
      } catch(e) {
        err = e
      }
      assert.instanceOf(err, Error, "accepting the feat should fail")
    })
  })
})
