const Aspect     = artifacts.require("Aspect")
const AspectBare = artifacts.require("AspectBare")
const Console    = artifacts.require("Console")

const { asEthWord } = require("../utils/ethword.js")

const config = require("../config.js")

module.exports = function (deployer, network, accounts) {
  let console_name = network == "test"? asEthWord("test aspect console") : asEthWord(config.console_tag)
  deployer.deploy(Console, console_name)
};
