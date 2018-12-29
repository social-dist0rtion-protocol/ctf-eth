// @format
var fs = require('fs');

var Entrance = artifacts.require('./entrance.sol');
var EnterAgain = artifacts.require('./enteragain.sol');

module.exports = function(deployer, network) {
  deployer.deploy(Entrance, 0xbc4f77).then(instance => {
    return deployer.deploy(EnterAgain, instance.address);
  });
};
