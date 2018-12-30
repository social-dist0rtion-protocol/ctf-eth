require("dotenv").config();

const Web3 = require("web3");
const WalletProvider = require("truffle-wallet-provider");
const Wallet = require("ethereumjs-wallet");

const web3 = new Web3();
const privateKey = new Buffer("1CE6A4CC4C9941A4781349F988E129ACCDC35A55BB3D5B1A7B342BC2171DB484", "hex");
const wallet = Wallet.fromPrivateKey(privateKey);
const provider = new WalletProvider(wallet, "https://ropsten.infura.io");

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: '15'
    },
    ropsten: {
      provider: provider,
      gas: 4600000,
      gasPrice: web3.utils.toWei("20", "gwei"),
      network_id: "3"
    }
  }
};
