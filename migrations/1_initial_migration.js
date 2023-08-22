const Aspect = artifacts.require("Aspect");
const shared = artifacts.require("shared");

module.exports = function (deployer) {
  deployer.deploy(shared);
  deployer.link(shared, Aspect);
  deployer.deploy(Aspect, "test aspect");
};
