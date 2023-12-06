// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

contract Milotto is ERC20, ReentrancyGuard {
    INonfungiblePositionManager private positionManager;
    address public WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public positionManagerAddress =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    mapping(address => uint256) public lastAccumulatedEtherPerToken;
    uint256 public totalAccumulatedEtherPerToken;

    uint256 public Supply = 1000000;

    event Deposite(address indexed account, uint256 amount);
    event Redeem(address indexed account, uint256 amount);

    constructor() payable ERC20("Milady Lottery", "MLT") {
        require(
            msg.value >= 0.1 ether,
            "Initial deposit can't be less than 0.1 ether"
        );

        positionManager = INonfungiblePositionManager(positionManagerAddress);

        _mint(msg.sender, 100000 * 10 ** decimals());
        _mint(address(this), 900000 * 10 ** decimals());

        TransferHelper.safeApprove(
            address(this),
            positionManagerAddress,
            900000 * 10 ** decimals()
        );

        IWETH9(WETH9).deposit{value: 0.1 ether}();
        TransferHelper.safeApprove(
            address(this),
            positionManagerAddress,
            0.1 ether
        );

        uint256 amountTokenDesired = 900000 * 10 ** decimals();
        uint256 amountETHDesired = 0.1 ether;

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: address(this),
                token1: WETH9,
                fee: 3000,
                tickLower: TickMath.MIN_TICK,
                tickUpper: TickMath.MAX_TICK,
                amount0Desired: amountTokenDesired,
                amount1Desired: amountETHDesired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: msg.sender,
                deadline: block.timestamp + 15
            });

        positionManager.mint(params);
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
