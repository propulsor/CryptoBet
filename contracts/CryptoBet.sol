pragma solidity ^0.4.0;
import "./database/Idatabase.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./ZapBridge.sol";

/** Price betting contract*/
contract CryptoBet is ReentrancyGuard,Ownable, ZapBridge{
    using SafeMath for uint256;

    address private bondage;
    address private zapToken;
    address private dispatch;
    address private coordinator;
    address public dataOracle;
    uint256 public minimumBetAmount;

    //structs

    //Database
    Idatabse public db;

    event BetCreated();

    constructor(address _dbAddress, address _zapCoor){
        assert(_dbAddress != address(0),"db address is required");
        assert(_zapCoor != address(0), "Zap Coordinator address is required");
        db = Idatabase(_dbAddress);
        bondage = ZapBridge(_zapCoor).getContract("BONDAGE");
        dispatch = ZapBridge(_zapCoor).getContract("DISPATCH");
        zapToken = ZapBridge(_zapCoor).getContract("ZAP_TOKEN");
    }

    function setOracle(address _oracle) onlyOwner{
        dataOracle = _oracle;
        db.setBytes32(keccak256(abi.encodePacked("oracle")),bytes32(dataOracle));
    }

    function getOracle() public view returns (address){
        return address(db.getBytes32(keccak256(abi.encodePacked("oracle"))));
    }

    function createBet();
    function takeBet();
    function queryProvider();
    function callback();
}
