pragma solidity ^0.4.0;

contract IpredictFactory {
    function createPredict(bytes32, uint256, uint256, uint256) external payable ;
    function joinPrediction(address, uint256) external;
    function settlePrediction(address) external ;
    function getPredictInfo(address)public view;
    function getPredictAddress(bytes32)public view returns(address);
    function getPredictId(address) public view returns(bytes32);
    function getAllBets() public view returns(bytes32[]);
    function emitSettled(address[], address, uint256, uint256,uint256)external;
    function emitCallback(uint256,uint256,address);
}
