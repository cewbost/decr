const Aspect = artifacts.require("Aspect")
const { BigNumber } = require("bignumber.js")
const { expect, equal, matchFields, beNumber, beInstanceOf, contain } = require("./matchers/matchers.js")
const { asEthWord } = require("./utils/numbers.js")

contract("Aspect", accounts => {

  let testAspect

  before(async () => {
    testAspect = await Aspect.new("TestAspect", { from: accounts[0] })
  })

  describe("thing", () => {
    let x
    before(() => {
      x = "world"
    })
    it("should do a thing", () => {
      console.log("hello, " + x)
    })
  })
})
