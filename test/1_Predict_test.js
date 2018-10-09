const BigNumber =web3.BigNumber;

const expect = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .expect;

const PredictFactory = artifacts.require("PredictFactory");
const Db = artifacts.require("Database")
const Predict = artifacts.require("PricePredict");
const ZapDB = artifacts.require("./node_modules/zap_contracts/contracts/database/Database.sol")
const ZapCoor = artifacts.require("./node_modules/zap_contracts/contracts/lib/ownership/ZapCoordinator.sol")
const Bondage = artifacts.require("./node_modules/zap_contracts/contracts/platform/bondage/Bondage.sol")
const Dispatch = artifacts.require("./node_modules/zap_contracts/contracts/platform/dispatch/Dispatch.sol")
const ZapToken = artifacts.require("./node_modules/zap_contracts/contracts/platform/token/ZapToken.sol")

/// Oracle const
const pubkey = "123";
const title = "priceOracle"
const endpoint = "price"
const coin = "BTC"
const curve = [1,1,1000000000000]


contract("PredicFactory",async (accounts)=>{
  const owner = accounts[0];
  const oracleowner = accounts[1]
  beforeEach(async function deployContract(){
    /***Deploy zap contrracts ***/
    this.currentTest.zapdb = await ZapDB.new()
    this.currentTest.zapcoor = await ZapCoor.new();
    await this.currentTest.zapdb.transferOwnership(this.currentTest.zapcoor.address);
    await this.currentTest.zapcoor.addImmutableContract('DATABASE', this.currentTest.zapdb.address);

    this.currentTest.token = await ZapToken.new();
    await this.currentTest.zapcoor.addImmutableContract('ZAP_TOKEN', this.currentTest.token.address);

    this.currentTest.registry = await Registry.new(this.currentTest.zapcoor.address);
    await this.currentTest.zapcoor.updateContract('REGISTRY', this.currentTest.registry.address);

    this.currentTest.cost = await Cost.new(this.currentTest.zapcoor.address);
    await this.currentTest.zapcoor.updateContract('CURRENT_COST', this.currentTest.cost.address);

    this.currentTest.bondage = await Bondage.new(this.currentTest.zapcoor.address);
    await this.currentTest.zapcoor.updateContract('BONDAGE', this.currentTest.bondage.address);

    this.currentTest.dispatch = await Dispatch.new(this.currentTest.zapcoor.address);
    await this.currentTest.zapcoor.updateContract('DISPATCH', this.currentTest.dispatch.address);

    await this.currentTest.zapcoor.updateAllDependencies();

    /*** Deploy Predict related contracts ***/
    this.currentTest.db = await Db.new();
    this.currentTest.factory = await PredictFactory.new(this.currentTest.db.address,this.currentTest.zapcoor.address);

    /*** Create Zap Oracle ***/
    await this.currentTest.registry.initiateProvider(publicKey, title, { from: oracleowner });
    await this.currentTest.registry.initiateProviderCurve(endpoint, curve, 0, { from: oracleOwner });

  })
  it("1. Create new Predict Contract", async function(){

  })
})