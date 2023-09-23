const Aspect     = artifacts.require("Aspect")
const AspectBare = artifacts.require("AspectBare")
const shared     = artifacts.require("shared")

module.exports = function (deployer, network) {
  deployer.deploy(shared)
  if (network == "test") {
    deployer.link(shared, AspectBare)
    deployer.deploy(AspectBare, "test aspect")
  }
  deployer.link(shared, Aspect)
  deployer.deploy(Aspect, "aspect")
};
