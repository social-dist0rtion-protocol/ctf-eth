// @format
var fs = require("fs");

var Entrance = artifacts.require("./Entrance.sol");
var EnterAgain = artifacts.require("./EnterAgain.sol");

module.exports = function(deployer, network) {
  deployer.deploy(EnterAgain, '0x1898Ed72826BEfa2D549004C57F048A95ae0B982');
};
