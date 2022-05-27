var decrFeatContract = artifacts.require("decrFeat");

module.exports = function (deployer) {
  deployer.deploy(decrFeatContract, "test feat");
};
