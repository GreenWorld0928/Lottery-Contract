// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Blotto is ERC20, ReentrancyGuard {
    mapping(address => uint256) public lastAccumulatedEtherPerToken;
    uint256 public totalAccumulatedEtherPerToken;

    uint256 public Supply = 1000000;

    event Deposite(address indexed account, uint256 amount);
    event Redeem(address indexed account, uint256 amount);

    constructor() ERC20("Blotto", "BLT") {
        _mint(msg.sender, Supply * 10 ** decimals());
    }

    function deposite() external payable nonReentrant {
        totalAccumulatedEtherPerToken += msg.value / Supply;
        emit Deposite(msg.sender, msg.value);
    }

    function getRedeemableAmountOf(
        address account
    ) public view returns (uint256) {
        return
            (balanceOf(account) / 10 ** decimals()) *
            (totalAccumulatedEtherPerToken -
                lastAccumulatedEtherPerToken[msg.sender]);
    }

    function redeemEther() external nonReentrant {
        uint256 redeemableEther = getRedeemableAmountOf(msg.sender);
        require(redeemableEther > 0, "There is no available ETH for redeeming");
        lastAccumulatedEtherPerToken[
            msg.sender
        ] = totalAccumulatedEtherPerToken;

        payable(msg.sender).transfer(redeemableEther);
        emit Redeem(msg.sender, redeemableEther);
    }
}
