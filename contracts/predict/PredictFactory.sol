pragma solidity ^0.4.24;
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
    event PredictCreated(bytes32 indexed id, uint256 indexed price, uint256 indexed ti, string coin,address newPredict);
    event Settled(address[] winners, address predict, uint256 resultPrice, uint256 winAmount, uint256 lostAmount);
    event Callback(uint256 id, uint256 response, address sender);

    constructor(address _dbAddress, address _zapCoor) public{
        require(_dbAddress != address(0),"db address is required");
        require(_zapCoor != address(0), "Zap Coordinator address is required");
        db = Idatabase(_dbAddress);
        bondage = ZapBridge(_zapCoor).getContract("BONDAGE");
        dispatch = ZapBridge(_zapCoor).getContract("DISPATCH");
        zapToken = ZapBridge(_zapCoor).getContract("ZAP_TOKEN");
    }

    function createPredict(string memory _coin, uint256 _price, uint256 _time, int256 _side, address _oracle, bytes32 _endpoint)  payable nonReentrant returns(address){
        address newPredict = (new PricePredict).value(msg.value)(msg.sender,_coin,_price,_time,_side, _oracle, _endpoint,bondage,dispatch);
        bytes32 id = keccak256(abi.encodePacked(msg.sender,newPredict,_coin,_price,_time));
        PricePredict(newPredict).setId(id);
        db.setAddress(id,newPredict);
        db.pushBytesArray(keccak256(abi.encodePacked("AllPredicts")),id);
        emit PredictCreated(id,_price,_time,_coin,newPredict);
        return newPredict;
    }

    function joinPrediction(address _predict, int _side) external payable nonReentrant {
        (Ipredict(_predict).joinPrediction).value(msg.value)(msg.sender,_side);
        emit JoinPredict(_predict,_side,msg.value);
    }

    /**
    Anyone can call settle and spend gas on executing this
   this call is to query Provider , it doesnt guarantee that the prediction will be settled,
   Depends on the settle time, condition, the query will be called and when oracle call callback methods on the prediction methods
   that's when the
    */
    function settlePrediction(address _predict) external nonReentrant returns(uint256){
        require(Ipredict(_predict).canSettle(),"this predict cant be settled at the moment");
        uint256 queryId = PricePredict(_predict).settlePrediction();
        emit SettlingPrediction(_predict,queryId);
        return queryId;
    }

    function getPredictInfo(address _predict) public view returns(string, uint, uint, uint, address, bool){
        return Ipredict(_predict).getInfo();
    }

    function getZapBridge() public view returns (address, address){
        return (dispatch,bondage);
    }
    function getOracle(address _predict) public view returns (address,bytes32){
        return Ipredict(_predict).getOracle();
    }

    function getPredictAddress(bytes32 id) public view returns(address){
        return db.getAddress(id);
    }

    function getPredictId(address _predict) public view returns(bytes32){
        bytes32 id =  Ipredict(_predict).getId();
        return id;
    }

    function getAllBets() public view returns (bytes32[]){
        return db.getBytesArray(keccak256(abi.encodePacked("AllPredicts")));
    }

    function getParticipants(address _predict) public view returns (address[],address[],address[]){
        return Ipredict(_predict).getParticipants();
    }
    function getSide(address _predict,int _side) public view returns(address[]){
        return  Ipredict(_predict).getSide(_side);
    }

    function emitSettled(address[] winner,address predict, uint256 _price, uint256 _winAmount, uint256 _lostAmount) external {
        emit Settled(winner,predict,_price, _winAmount, _lostAmount);
    }

    function emitCallback(uint256 id, uint256 response,address sender){
        emit Callback(id,response,sender);
    }
}
