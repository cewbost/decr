const Aspect = artifacts.require("Aspect");
const Bitset = artifacts.require("Bitset");

module.exports = function (deployer) {
  deployer.deploy(Bitset);
  deployer.link(Bitset, Aspect);
  deployer.deploy(Aspect, "test aspect");
};
