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
    address zapToken;
    address bondage;
    address dispatch;

    //events
    event JoinPredict(address indexed player, int256 indexed side, uint256 indexed amount);
    event SettlingPrediction(address indexed predict, uint256 indexed queryId);
    event PredictCreated(bytes32 indexed id, string indexed coin, uint256 indexed price, uint256 time);
    event Settled(bytes32 indexed id, uint256 indexed resultPrice, uint256 winAmount, uint256 lostAmount);

    constructor(address _dbAddress, address _zapCoor) public{
        require(_dbAddress != address(0),"db address is required");
        require(_zapCoor != address(0), "Zap Coordinator address is required");
        db = Idatabase(_dbAddress);
        db.setStorageContract(address(this),true);
        bondage = ZapBridge(_zapCoor).getContract("BONDAGE");
        dispatch = ZapBridge(_zapCoor).getContract("DISPATCH");
        zapToken = ZapBridge(_zapCoor).getContract("ZAP_TOKEN");
    }

    function createPredict(string _coin, uint256 _price, uint256 _time, int256 _side, address _oracle, bytes32 _endpoint) external payable nonReentrant{
        PricePredict newPredict = new PricePredict(msg.sender,_coin,_price,_time,_side, _oracle, _endpoint);
        bytes32 id = keccak256(abi.encodePacked(msg.sender,newPredict,_coin,_price,_time));
        newPredict.setId(id);
        db.setAddress(keccak256(abi.encodePacked(id)),newPredict);
        db.pushBytesArray(keccak256(abi.encodePacked("AllPredicts")),id);
        emit PredictCreated(id,_coin,_price,_time);
    }

    function joinPrediction(address _predict, int _side) external payable nonReentrant {
        PricePredict(_predict).joinPrediction(_side);
        emit JoinPredict(msg.sender,_side,msg.value);
    }

    /**
    Anyone can call settle and spend gas on executing this
   this call is to query Provider , it doesnt guarantee that the prediction will be settled,
   Depends on the settle time, condition, the query will be called and when oracle call callback methods on the prediction methods
   that's when the
    */
    function settlePrediction(address _predict) external nonReentrant{
        uint256 queryId = PricePredict(_predict).settlePrediction(bondage,dispatch);
        emit SettlingPrediction(_predict,queryId);
    }

    function getPredictInfo(address _predict) public view returns(string, uint, uint, uint, address, bool){
        return PricePredict(_predict).getInfo();
    }

    function getPredictAddress(bytes32 id) public view returns(address){
        return db.getAddress(id);
    }

    function getPredictId(address _predict) public view returns(bytes32){
        return PricePredict(_predict).getId();
    }

    function getAllBets() public view returns (bytes32[]){
        return db.getBytesArray(keccak256(abi.encodePacked("AllPredicts")));
    }

    function emitSettled(bytes32 _id, uint256 _price, uint256 _winAmount, uint256 _lostAmount) external {
        emit Settled(_id,_price, _winAmount, _lostAmount);
    }

}
