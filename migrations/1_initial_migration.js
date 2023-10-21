const Aspect     = artifacts.require("Aspect")
const AspectBare = artifacts.require("AspectBare")
const Console = artifacts.require("Console")

const { asEthWord } = require("../utils/ethword.js")

const config = require("../config.js")

module.exports = function (deployer, network, accounts) {
  if (network == "test") {
    deployer.deploy(Console, asEthWord("test aspect console"))
  } else {
    deployer.deploy(Console, asEthWord(config.console_tag))
  }
};
