const Aspect = artifacts.require("Aspect");
const Shared = artifacts.require("Shared");

module.exports = function (deployer) {
  deployer.deploy(Shared);
  deployer.link(Shared, Aspect);
  deployer.deploy(Aspect, "test aspect");
};
