pragma solidity ^0.4.0;

contract Ipredict {
    function joinPrediction(uint256) internal;
    function getInfo() public view;
    function getParticipants() public view;
    function settlePrediction(address, address) internal returns (uint256);
    function callback( uint256, int[]) external;
    function distribute(uint8) private;
}
