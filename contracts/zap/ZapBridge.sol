pragma solidity ^0.4.24;


contract ZapBridge{
    //event
    event Transfer(address indexed from, address indexed to, uint256 value);
    function getContract(string contractName) public view returns (address); //coordinator
    function calcZapForDots(address, bytes32, uint256) external view returns (uint256); //bondage
    function delegateBond(address holderAddress, address oracleAddress, bytes32 endpoint, uint256 numDots) external returns (uint256 boundZap); //bondage
    function query(address, string, bytes32, bytes32[]) external returns (uint256); //dispatch
    function respondIntArray(uint256, string) external returns (bool); //dispatch
    function balanceOf(address who) public constant returns (uint256); //Token
    function transfer(address to, uint256 value) public returns (bool); //Token



}
