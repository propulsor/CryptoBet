pragma solidity ^0.4.0;
import "../Ownable.sol";
import "../ReentrancyGuard.sol";
import "../SafeMath.sol";
import "../zap/ZapBridge.sol";


contract Predict is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address private bondage;
    address private zapToken;
    address private dispatch;
    address private coordinator;
    address public dataOracle;
    uint256 public minimumBetAmount;

    enum Side {greater, smaller, equal}

    struct Player{
        address owner;
        uint256 side;
        uint256 amount;
    }

    struct Oracle{
        address provider;
        bytes32 endpoint;
    }


    mapping (address=>Player) players;
    address creator;
    bytes32 coin;
    uint256 price; //eth bet amount
    uint256 time;
    uint256 totalAmount;
    bool settle;
    uint256 resultPrice;
    uint256 queryId;
    Oracle oracle;



    constructor(bytes32 _coin, uint256 _price, uint256 _time, uint256 _side, address _oracle, bytes32 _endpoint) internal payable{
        require(msg.value>0,"Need to send eth to bet to create");
        require(_side==Side.greater | _side == Side.equal | _side == Side.smaller,"invalid side");
        require(time>now,"time has to be in the future");
        coin=_coin;
        price = _price;
        time = _time;
        creator = msg.sender;
        totalAmount = msg.value;
        oracle = Oracle(_oracle,_endpoint);
        players[msg.sender] = Player(msg.sender,_side,msg.value);
    }

    function joinPrediction(uint256 _side) internal {
        require(msg.sender != creator,"maker cant take");
        require(msg.value>0,"Need to include eth to take the bet");
        require(!players[mag.sender],"already anticipated");
        players[msg.sender] = Player(msg.sender,_side,msg.value);
    }

    function getInfo() public view {
        return (coin,price,time,balance(this),players, oracle,settle);
    }

    //Anyone can call settle and spend gas on executing this
    /**
    Case1 : single player that created the prediction -> auto win
    Case2 : more than 1 players ->
     - Contract needs to have 1 dot bonded through delegateBond to settle, if not - > revert
     - call oracle to get data to settle
    */
    function settlePrediction(address _bondage, address _dispatch) internal {
        if(players.length==1){
            players[0].transfer(balance(this));
            //kill contract?
            return;
        }
        require(!settle,"already settled");
        require(time<now,"Its not settle time yet");
        uint256 bonded = ZapBridge(_bondage).getBoundDots(address(this),dataOracle, coin);
        require(bonded>=1, "Need at least 1 dots bonded to settle");
        bytes32[] memory params = new bytes32[](1);
        params[0] = bytes32(time);
        queryId = ZapBridge(dispatchAddress).query(oracle.provider,coin,oracle.endpoint,params);
    }

    /**
    - call back from provider, settle and distribute
    */
    function callback(uint256 _id, int[] _response) external {
        require(msg.sender==oracle.provider, "result is not from correct oracle");
        require(_id == queryId,"not matching id queried");
        resultPrice = uint256(_response[0]);
        if(resultPrice>price){

        }
        else if(resultPrice<price){

        }
        else{
        }
    }
}
