var Migrations = artifacts.require("./Migrations.sol");
var zapcoor = "0x0014f9acd4f4ad4ac65fec3dcee75736fd0a0230"
var DB = artifacts.require("Db")
var Factory = artifacts.require("PredictFactory")
async function deploy(deployer,network) {
  const dbInstance = await deployer.deploy(DB);
  let factoryInstance = await deployer.deploy(Factory,dbInstance.address,zapcoor);
  await dbInstance.setStorageContract(factoryInstance.address,true);

};

module.exports = (deployer, network) => {
  deployer.then(async () => await deploy(deployer, network));
};