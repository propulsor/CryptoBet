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
    bytes32 public id;

    int greater = 1;
    int smaller = -1;
    int equal=0;

    struct Oracle{
        address provider;
        bytes32 endpoint;
    }

    modifier validSide(int256 _side){
        require(_side==1 || _side==0 || _side==-1);
        _;
    }

    mapping (int => address[]) sides;
    mapping (address => uint256) players;
    address creator;
    string coin;
    uint256 price; //eth bet amount
    uint256 time;
    uint256 totalAmount;
    bool settle;
    uint256 resultPrice;
    uint256 queryId;
    address settler;
    Oracle oracle;
    IpredictFactory factory;



    constructor(address _creator,string _coin, uint256 _price, uint256 _time, int _side, address _oracle, bytes32 _endpoint) public payable{
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

    function joinPrediction(int side) external payable {
        require(side==1 || side==0 || side==-1, "invalid side");
        require(msg.sender != creator,"maker cant take");
        require(msg.value>0,"Need to include eth to take the bet");
        require(players[msg.sender] != 0,"already anticipated");
        players[msg.sender] = msg.value;
        sides[side].push(msg.sender);
    }

    function getInfo() public view returns (string,uint256,uint256,uint256,address,bool) {
        return (coin,price,time,address(this).balance, oracle.provider,settle);
    }

    function getId() public view returns (bytes32){
        return id;
    }

    function setId(bytes32 _id) public {
        id = _id;
    }

    function getParticipants() public view  returns (address[], address[], address[]){
        return (sides[-1],sides[0],sides[1]);
    }


    function getParticipantsNumber() public view returns(uint256){
        uint256 size = sides[-1].length + sides[0].length + sides[1].length;
        return size;
    }



    function refund(int256 side) private validSide(side) {
        address[] memory pars = sides[side];
        for(uint i=0; i<pars.length; i++){
            pars[i].transfer(players[pars[i]]);
        }
        return;

    }

    //Anyone can call settle and spend gas on executing this
    /**
    Case1 : single player that created the prediction -> refund
    Case2 : more than 1 players  but all in 1 sides -> refund
    Case3 : more than 1 players, more than 1 sides:
     - Contract needs to have 1 dot bonded through delegateBond to settle, if not - > revert
     - call oracle to get data to settle, whoever call to query provider will have rewards as part of settlement
    */
    function settlePrediction(address _bondage, address _dispatch) external  returns (uint256){
        //this case is impossible to come across
        require(address(this).balance>0,"no eth balance in this contract, cant settle");
        require(!settle,"already settled");
        require(time<now,"Its not settle time yet");
        uint256  pars = getParticipantsNumber();
        //case 1
        if(pars<=1){
            creator.transfer(address(this).balance);
            //todo kill contract?
            return 0;
        }
        else{
            (address[] memory greatorSide, address[] memory equalSide, address[] memory smallerSide) = getParticipants();
            int singleSide;
            if(pars==smallerSide.length)
                singleSide = -1 ;
            else if(pars==equalSide.length)
                singleSide = 0;
            else if(pars==greatorSide.length)
                singleSide = 1;
            else
                singleSide= 2;

            //check if case 2
            if(singleSide<10){
                refund(singleSide);
                return 0;
            }
            else{
                uint256 bonded = ZapBridge(_bondage).getBoundDots(address(this),dataOracle, oracle.endpoint);
                require(bonded>=1, "Need at least 1 dots bonded to settle");
                bytes32[] memory params = new bytes32[](1);
                params[0] = bytes32(time);
                queryId = ZapBridge(_dispatch).query(oracle.provider,coin,oracle.endpoint,params);
                return queryId;
            }
        }
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
                uint256 winAmount = players[winner].add(players[winner].div(totalAmountWinside).mul(totalAmountLostside));
                require(winner.send(winAmount),"fail to send to this winner, possible code attempted to execute");
            }
            require(address(this).balance==0,"not fully distributed");
        }
        factory.emitSettled(address(this),resultPrice,totalAmountWinside,totalAmountLostside);
    }
}
