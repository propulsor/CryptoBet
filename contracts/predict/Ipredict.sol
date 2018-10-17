pragma solidity ^0.4.24;

contract Ipredict {
    function joinPrediction(address,int256) public payable;
    function getInfo() public view returns(string, uint, uint, uint, address, bool);
    function getId() public view returns(bytes32);
    function getOracle() public view returns(address,bytes32);
    function canSettle() public view returns(bool);
    function getParticipants() public view returns(address[],address[],address[]);
    function getSide(int _side) public view returns (address[]);
    function settlePrediction() public returns (uint256);
    function callback( uint256, int[]) external;
    function distribute(uint8) private;
}
