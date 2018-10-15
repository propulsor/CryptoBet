## Decentralized Prediction Market Factory
- This Project is to provide a decentralized prediction protocol
- The goal is to create a rewarding system for all the parties that help the prediction happens
- ie . Settler , data provider using zap dot bonding protocol
- The winning is unfair, creating a competitive sides to join //todo explain better
#### Ideas :
//todo flow diagram
### Prediction info : 
- Sides :  equal, smaller, greater (than the price predicted)
- totalAmount : total amount of eth in the contract
- creator : first anticipant to set the predicted price
- players : all addresses of anticipants
- oracle : data provider that is set by the creator to provide the accurate result price 
- settler : address that execute bonding and query provider to get result
- winners : the addresses that win the prediction
### Anticipants 
1. Creator : the first anticipants to create a prediction, as a reward for gas cost, creator earn extra 1% odd in his/her bet
2. Players : everyone wants to join the prediction   
3. Settler : anyone can be settler and earn % of winning. Settler has to bond zap token and query oracle 
4. Oracle : data provider to deliver the accurate price at the predicted time, oracle is chosen by creator and players can choose to join the prediction or not based on the reputation of the oracle

### Distribution  
The winning/refund distribution is calculated as follow : 
1. If no one anticipate the prediction beside creator :  Prediction contract will be destroyed and fund will be returned to creator
2. If the winning result has no players : all the eth will be refunded to the players minus the rewards for settler
3. If the winning result has players : 
Winning distribution : 
winAmount = stake + ((stake/totalWinSide)*totalLostSide)-settlerReward

#DEVELOPMENT
### Structure :
- Database : Saving all the predictions information
- Prediction Factory :
    + Creating new prediction contracts and proxy all the contract calls. 
    + Emit events for all contracts, Allowing anyone to listen and display information about all predictions
- Prediction :  
    + Created by calling Prediction Factory
    + One time coin-price-time prediction per contract
    + After settled, will be killed
- ZapBridge : 
    + Interface for interacting with Zap contracts
    + Including : Bondage, Token, Dispatch, ZapCoordinator
    
### Setup and testing:
- git clone
- yarn
- yarn test    
     
