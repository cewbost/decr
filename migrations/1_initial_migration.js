const Aspect     = artifacts.require("Aspect")
const AspectBare = artifacts.require("AspectBare")
const shared     = artifacts.require("shared")
const Console = artifacts.require("Console")

const { asEthWord } = require("../utils/ethword.js")

module.exports = function (deployer, network, accounts) {
  deployer.deploy(shared)
  deployer.link(shared, Aspect)
  deployer.link(shared, Console)
  if (network == "test") {
    deployer.link(shared, AspectBare)
    deployer.deploy(Console, asEthWord("test aspect console"))
  }
};
