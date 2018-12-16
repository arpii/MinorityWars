var HDWalletProvider = require("truffle-hdwallet-provider");
var secret = require('./secret');
var mnemonic = secret.mnemonic;

module.exports = {
  networks: {
    dexonnet: {
      provider: new HDWalletProvider(mnemonic,
        "http://testnet.dexon.org:8545", 0, 1, true, "m/44'/237'/0'/0/"),
      network_id: "dexonnet"
    },
  },
};
