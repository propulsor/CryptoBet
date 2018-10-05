pragma solidity ^0.4.0;
import "../Ownable.sol";
import "../ReentrancyGuard.sol";
import "../SafeMath.sol";
import "../zap/ZapBridge.sol";
import "./IpredictFactory.sol";
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

    int greater = 1;
    int smaller = -1;
    int equal=0;

    struct Oracle{
        address provider;
        bytes32 endpoint;
    }


    mapping (int => address[]) sides;
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
    IpredictFactory factory;



    constructor(address _creator,bytes32 _coin, uint256 _price, uint256 _time, int _side, address _oracle, bytes32 _endpoint) internal payable{
        require(msg.value>0,"Need to send eth to bet to create");
       // require(_side==Side.greater || _side == Side.equal || _side == Side.smaller,"invalid side");
        require(time>now,"time has to be in the future");
        coin=_coin;
        price = _price;
        time = _time;
        creator = _creator;
        oracle = Oracle(_oracle,_endpoint);
        sides[_side].push(creator);
        players[creator] = msg.value;
        factory = IpredictFactory(msg.sender);
    }

    function joinPrediction(int side) internal {
        require(side==1 || side==0 || side==-1, "invalid side");
        require(msg.sender != creator,"maker cant take");
        require(msg.value>0,"Need to include eth to take the bet");
        require(players[msg.sender] != 0,"already anticipated");
        players[msg.sender] = msg.value;
        sides[side].push(msg.sender);
    }

    function getInfo() public view returns (bytes32,uint256,uint256,uint256,address,bool) {
        return (coin,price,time,address(this).balance, oracle.provider,settle);
    }

    function getParticipants() public view  returns (address[]){
        address[] par;
        par.push(sides[-1]);
        par.push(sides[1]);
        par.push(sides[0]);
        return par;
    }

    //Anyone can call settle and spend gas on executing this
    /**
    Case1 : single player that created the prediction -> auto win
    Case2 : more than 1 players ->
     - Contract needs to have 1 dot bonded through delegateBond to settle, if not - > revert
     - call oracle to get data to settle, whoever call to query provider will have rewards as part of settlement
    */
    function settlePrediction(address _bondage, address _dispatch) internal  returns (uint256){
        //this case is impossible to come across
        require(address(this).balance>0,"no eth balance in this contract, cant settle");
        address[] memory pars = getParticipants();
        if(pars.length==1){
            pars[0].transfer(address(this).balance);
            //kill contract?
            return;
        }
        require(!settle,"already settled");
        require(time<now,"Its not settle time yet");
        uint256 bonded = ZapBridge(_bondage).getBoundDots(address(this),dataOracle, coin);
        require(bonded>=1, "Need at least 1 dots bonded to settle");
        bytes32[] memory params = new bytes32[](1);
        params[0] = bytes32(time);
        queryId = ZapBridge(_dispatch).query(oracle.provider,coin,oracle.endpoint,params);
        return queryId;
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
        require(resultPrice>0,"price cant be 0");
        if(resultPrice>price){
            distribute(greater);
        }
        else if(resultPrice<price){
            distribute(smaller);
        }
        else{
            distribute(equal);
        }
    }

    function distribute(int _side) private nonReentrant{
        address[] memory winners = sides[_side];
        uint256 totalAmountWinside = 0;
        for(uint i=0; i<winners.length; i++){
            totalAmountWinside += players[winners[i]];
        }
        uint256 totalAmountLostside = address(this).balance - totalAmountWinside;
        if(totalAmountLostside<=0){
            //this should never happen
        }else{
            for(uint j=0; j<winners.length; j++){
                address winner = winners[j];
                uint256 winAmount = players[winner].add(players[winners].div(totalAmountWinside).mul(totalAmountLostside));
                require(winner.send(winAmount),"fail to send to this winner, possible code attempted to execute");
            }
            require(address(this).balance==0,"not fully distributed");
        }
        factory.emitSettle(address(this),resultPrice,totalAmountWinside,totalAmountLostside);
    }
}
