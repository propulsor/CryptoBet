
const HDWalletProvider = require("truffle-hdwallet-provider")
const mnemonic = 'pact inside track layer hello carry used silver pyramid bronze drama time';
module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    "kovan": {
      provider: function () {
        return new HDWalletProvider(mnemonic, 'https://kovan.infura.io')
      },
      network_id: '42',
      gas: 8000000,
      gasPrice: 30000000000,
    },
    "ganache": {
      provider: function () {
        return new HDWalletProvider(mnemonic, 'https//127.0.0.1:8545')
      },
      network_id: 5777,
      gas: 8000000,
      gasPrice: 10000000000,
    }
  }
};
