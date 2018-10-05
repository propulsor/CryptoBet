pragma solidity ^0.4.0;
import "../database/Idatabase.sol";
import "../Ownable.sol";
import "../SafeMath.sol";
import "../ReentrancyGuard.sol";
import "../zap/ZapBridge.sol";
import "./PricePredict.sol";
import "./Ipredict.sol";

/** Price betting contract*/
contract PredictFactory is ReentrancyGuard,Ownable{

    uint256 public count;

    //Database
    Idatabase public db;
    Ipredict Predict;
    ZapBridge zapToken;
    ZapBridge bondage;
    ZapBridge dispatch;

    //events
    event JoinPredict(address indexed player, uint256 indexed side, uint256 indexed amount, bool indexed join);
    event SettlingPrediction(bytes32 indexed id, uint256 indexed queryId);
    event PredictCreated(bytes32 indexed id, bytes32 indexed coin, uint256 indexed price, uint256 indexed time);
    event Settled(bytes32 indexed id, uint256 indexed resultPrice, uint256 winAmount, uint256 lostAmount);

    constructor(address _dbAddress, address _zapCoor){
        require(_dbAddress != address(0),"db address is required");
        assert(_zapCoor != address(0), "Zap Coordinator address is required");
        db = Idatabase(_dbAddress);
        db.setStorageContract(address(this));
        bondage = ZapBridge(_zapCoor).getContract("BONDAGE");
        dispatch = ZapBridge(_zapCoor).getContract("DISPATCH");
        zapToken = ZapBridge(_zapCoor).getContract("ZAP_TOKEN");
    }

    function createPredict(bytes32 _coin, uint256 _price, uint256 _time, uint256 _side) external payable nonReentrant{
        address newPredict = new PricePredict(_coin,_price,_time,_side);
        bytes32 id = keccak256(abi.encodePacked(msg.sender,newPredict,_coin,_price,_time));
        Predict(newPredict).setId(id);
        db.setAddress(keccak256(abi.encodePacked(id)),newPredict);
        db.pushBytesArray(keccak256(abi.encodePacked("AllPredicts")),id);
        emit PredictCreated(id,_coin,_price,_time);
    }

    function joinPrediction(address _predict, uint256 _side) external nonReentrant {
        bool join = Predict(_predict).joinPrediction(_side);
        emit JoinPredict(msg.sender,_side,msg.value, join);
    }

    /**
    Anyone can call settle and spend gas on executing this
   this call is to query Provider , it doesnt guarantee that the prediction will be settled,
   Depends on the settle time, condition, the query will be called and when oracle call callback methods on the prediction methods
   that's when the
    */
    function settlePrediction(address _predict) external nonReentrant{
        uint256 queryId = Predict(_predict).settlePrediction();
        emit SettlingPrediction(_predict,queryId);
    }

    function getPredictInfo(address _predict) public view{
        return Predict(_predict).getInfo();
    }

    function getPredictAddress(bytes32 id) public view returns(address){
        return db.getAddress(id);
    }

    function getPredictId(address _predict) public view returns(uint256){
        return Predict(_predict).getId();
    }

    function getAllBets() public view returns (bytes32[]){
        return db.getBytesArray(keccak256(abi.encodePacked("AllPredicts")));
    }

    function emitSettled(bytes32 _id, uint256 _price, uint256 _winAmount, uint256 _lostAmount) internal {
        emit Settled(_id,_price, _winAmount, _lostAmount);
    }

}
