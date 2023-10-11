const Aspect     = artifacts.require("Aspect")
const AspectBare = artifacts.require("AspectBare")
const shared     = artifacts.require("shared")

const { asEthWord } = require("../utils/ethword.js")

module.exports = function (deployer, network) {
  deployer.deploy(shared)
  if (network == "test") {
    deployer.link(shared, AspectBare)
    deployer.deploy(AspectBare, asEthWord("test aspect"))
  }
  deployer.link(shared, Aspect)
  deployer.deploy(Aspect, asEthWord("aspect"))
};
