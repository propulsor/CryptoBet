const BigNumber =web3.BigNumber;

const expect = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .expect;

const PredictFactory = artifacts.require("PredictFactory");
const Db = artifacts.require("Db");
const Predict = artifacts.require("PricePredict");
const ZapDB = artifacts.require("Database");
const ZapCoor = artifacts.require("ZapCoordinator");
console.log("zap coor", ZapCoor)
const Bondage = artifacts.require("Bondage");
const Dispatch = artifacts.require("Dispatch");
const ZapToken = artifacts.require("ZapToken");
const Registry = artifacts.require("Registry");
const Cost = artifacts.require("CurrentCost")

/// Oracle const
const pubkey = "123";
const title = "priceOracle"
const endpoint = "price"
const curve = [1,1,1000000000000]
///Predict
const coin = "BTC"
const price = 7000
const time = Date.now()

contract("PredicFactory",async (accounts)=>{
  const owner = accounts[0];
  const oracleowner = accounts[1]
  beforeEach(async function deployContract(){
    /***Deploy zap contrracts ***/
    this.currentTest.zapdb = await ZapDB.new();
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
    this.currentTest.db.setStorageContract(this.currentTest.factory.address,true)

    /*** Create Zap Oracle ***/
    await this.currentTest.registry.initiateProvider(pubkey, title, { from: oracleowner });
    await this.currentTest.registry.initiateProviderCurve(endpoint, curve, 0, { from: oracleowner });

  })
  it("1. Create new Predict Contract", async function(){
    console.log("balance " , web3.eth.getBalance(accounts[1]).toString())
      const predict = await this.test.factory.createPredict(coin,price,time,1,oracleowner,endpoint,{from:accounts[1],value:10})
    console.log(predict)
      expect(predict).to.be.ok
  })
  it("2. Join Prediction",async function(){

  })
  it("3. Set up broker", async function(){

  })
  it("4. Getters", async function(){

  })
  it("5. Settle Prediction", async function(){

  })
  it("6. Oracle Response query ", async function(){

  })
  it("7. Prediction should be settled", async function(){

  })
})