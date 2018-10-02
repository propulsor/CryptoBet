pragma solidity ^0.4.0;
import "../database/Idatabase.sol";
import "../Ownable.sol";
import "../SafeMath.sol";
import "../ReentrancyGuard.sol";
import "../zap/ZapBridge.sol";
import "./Predict.sol";

/** Price betting contract*/
contract PredictFactory is ReentrancyGuard,Ownable{

    uint256 public count;

    //Database
    Idatabase public db;

    //events
    event JoinPredict(address indexed player, uint256 indexed side, uint256 indexed amount);
    event SettlePredict(byte32 indexed id, uint256 indexed price, uint256 indexed winside);
    event PredictCreated(bytes32 indexed id, bytes32 indexed coin, uint256 indexed price, uint256 indexed time);

    constructor(address _dbAddress, address _zapCoor){
        require(_dbAddress != address(0),"db address is required");
        assert(_zapCoor != address(0), "Zap Coordinator address is required");
        db = Idatabase(_dbAddress);
        db.setStorageContract(address(this));
        bondage = ZapBridge(_zapCoor).getContract("BONDAGE");
        dispatch = ZapBridge(_zapCoor).getContract("DISPATCH");
        zapToken = ZapBridge(_zapCoor).getContract("ZAP_TOKEN");
    }

    function createPredict(bytes32 _coin, uint256 _price, uint256 _time, uint256 _side) public payable{
        address newPredict = new Predict(_coin,_price,_time,_side);
        byte32 id = keccack256(abi.encodePacked(msg.sender,newPredict,_coin,_price,_time));
        db.setAddress(keccak256(abi.encodePacked(id)),newPredict);
        db.pushBytesArray(keccak256(abi.encodePacked("AllPredicts")),id);
        emit PredictCreated(id,_coin,_price,_time);
    }

    function joinPrediction(address _predict, uint256 _side) public {
        Predict(_predict).joinPrediction(_side);
        emit JoinPredict(msg.sender,_side,msg.value);
    }

    //Anyone can call settle and spend gas on executing this
    function settlePrediction(address _predict) public{
        Predict(_predict).settlePrediction();
        emit SettlePredict()
    }

    function getPredictInfo(address __predict) public view{
        return Predict(_predict).getInfo();
    }
    function getPredictAddress(bytes32 id){
        return db.getAddress(id);
    }

    function getAllBets() public view returns (bytes32[]){
        return db.getBytesArray(keccak256(abi.encodePacked("AllPredicts")));
    }

}
