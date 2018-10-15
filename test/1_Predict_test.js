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
const REVERT = "revert"

contract("PredicFactory",async (accounts)=>{
  const owner = accounts[0];
  const oracleowner = accounts[1]
  let predict;
  let broker = accounts[8]
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
      let created = await this.test.factory.createPredict(coin,price,time,1,oracleowner,endpoint,{from:accounts[1],value:10})
      expect(created).to.be.ok
      predict = created.logs[0].args.newPredict
    expect(predict).to.be.ok
    console.log("predict", predict)
    let createdPredict = await this.test.factory.getPredictInfo(predict)
    console.log("PREDICT JUST CREATED ",createdPredict)
    let oracleInfo = await this.test.factory.getOracle(predict);
      console.log("ORACLE info : ", oracleInfo)
  })
  it("2. Join Prediction on greater side",async function(){
    await this.test.factory.joinPrediction(predict, 1,{from:accounts[3],value:10});
    await this.test.factory.joinPrediction(predict,0,{from:accounts[4],value:20});
    await this.test.factory.joinPrediction(predict,-1,{from:accounts[5],value:30});
    let players = await this.test.factory.getParticipants(predict);
    console.log("Players ", players)

  })
  it("3. Validate info", async function(){

  })
  it("4. Same player should not be able to join twice", async function(){
    await expect(this.test.factory.joinPrediction(predict,1,{from:accounts[4],value:10})).to
      .eventually.be.rejectedWith(REVERT)
    await expect(this.test.factory.joinPrediction(predict,-1,{from:accounts[4],value:10})).to
      .eventually.be.rejectedWith(REVERT)
  })
  it("5. Setup condition for settling prediction",async function(){
    //get zap token
    await this.test.token.allocate(broker,10000000,{from:owner})
    let balance = await this.test.token.balanceOf(broker)
    expect(balance.toNumber()).to.be.equal(10000000)
    await this.test.token.approve(this.test.bondage.address,1000,{from:broker})

  })
  it("6. Should have All settle-able conditions", async function(){

  })
  it("Should Settle the prediction by query provider, and Provider should receive the correct query", async ()=>{
    let queryId = await this.test.factory.settlePrediction(predict,{from:broker})
  })
  it("7. Oracle Response query ", async function(){

  })
  it("8. Prediction should be settled", async function(){

  })
})