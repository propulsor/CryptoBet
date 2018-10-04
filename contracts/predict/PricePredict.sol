pragma solidity ^0.4.0;
import "../Ownable.sol";
import "../ReentrancyGuard.sol";
import "../SafeMath.sol";
import "../zap/ZapBridge.sol";

/**
Simple Price prediction

*/
contract PricePredict is  ReentrancyGuard {
    using SafeMath for uint256;

    address private bondage;
    address private zapToken;
    address private dispatch;
    address private coordinator;
    address public dataOracle;
    uint256 public minimumBetAmount;

    enum Side {greater, smaller, equal}

    struct Oracle{
        address provider;
        bytes32 endpoint;
    }


    mapping (Side => address[]) sides;
    mapping (address => uint256) players;
    address creator;
    bytes32 coin;
    uint256 price; //eth bet amount
    uint256 time;
    uint256 totalAmount;
    bool settle;
    uint256 resultPrice;
    uint256 queryId;
    address settler;
    Oracle oracle;



    constructor(bytes32 _coin, uint256 _price, uint256 _time, uint256 _side, address _oracle, bytes32 _endpoint) internal payable{
        require(msg.value>0,"Need to send eth to bet to create");
        require(_side==Side.greater | _side == Side.equal | _side == Side.smaller,"invalid side");
        require(time>now,"time has to be in the future");
        coin=_coin;
        price = _price;
        time = _time;
        creator = msg.sender;
        oracle = Oracle(_oracle,_endpoint);
        sides[_side].push(msg.sender);
        players[msg.sender] = msg.value;
    }

    function joinPrediction(uint256 _side) internal {
        require(msg.sender != creator,"maker cant take");
        require(msg.value>0,"Need to include eth to take the bet");
        require(!players[msg.sender],"already anticipated");
        players[msg.sender] = msg.value;
        sides[_side].push(msg.sender)
    }

    function getInfo() public view {
        return (coin,price,time,balance(this), oracle,settle);
    }

    function getParticipants() public view  returns memory (address[]){
        address[] memory par;
        par.push(sides[Side.smaller]);
        par.push(sides[Side.greater]);
        par.push(sides[Side.equal]);
        return par;
    }

    //Anyone can call settle and spend gas on executing this
    /**
    Case1 : single player that created the prediction -> auto win
    Case2 : more than 1 players ->
     - Contract needs to have 1 dot bonded through delegateBond to settle, if not - > revert
     - call oracle to get data to settle, whoever call to query provider will have rewards as part of settlement
    */
    function settlePrediction(address _bondage, address _dispatch) internal {
        //this case is impossible to come across
        require(balance(this)>0,"no eth balance in this contract, cant settle");
        address[] pars = getParticipants();
        if(pars.length==1){
            pars[0].transfer(balance(this));
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
    - response is expected to be single number of price
    - count player on each side and calculate distribution of winners
    */
    function callback(uint256 _id, int[] _response) external nonReentrant{
        require(msg.sender==oracle.provider, "result is not from correct oracle");
        require(_id == queryId,"not matching id queried");
        require(_response.length > 0, "no response detected");
        resultPrice = uint256(_response[0]);
        if(resultPrice>price){

        }
        else if(resultPrice<price){

        }
        else{
            //equal price
        }
    }
}
