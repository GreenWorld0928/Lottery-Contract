// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IBlotto.sol";

contract Lottery is ReentrancyGuard {
    uint256 public dailyPool;
    uint256 public weeklyPool;
    uint256 public monthlyPool;

    address[] public dailyParticipants;
    address[] public weeklyParticipants;
    address[] public monthlyParticipants;

    mapping(address => bool) public dailyContributors;
    mapping(address => bool) public weeklyContributors;
    mapping(address => bool) public monthlyContributors;

    uint256 private dailySelectionTime;
    uint256 private weeklySelectionTime;
    uint256 private monthlySelectionTime;

    address payable public megaJackpot;
    IBlotto public blottoDistributor;
    address payable public constant teamAddress1 =
        payable(0xcE8d4889CbDD8fD33B3632F7163EE47B1A641EC7);
    address payable public constant teamAddress2 =
        payable(0x7950d7cA3C7E49401F0591D77CA5166Afc2343b9);

    event Contribution(
        address indexed contributor,
        uint256 amount,
        string drawType
    );

    event WinnerSelection(
        address indexed winner,
        uint256 amount,
        string drawType
    );

    constructor(address _megaJackpot, address _blottoDistributor) {
        megaJackpot = payable(_megaJackpot);
        blottoDistributor = IBlotto(_blottoDistributor);
        dailySelectionTime = block.timestamp;
        weeklySelectionTime = block.timestamp;
        monthlySelectionTime = block.timestamp;
    }

    modifier selectionDue(string memory drawType) {
        if (
            keccak256(abi.encodePacked(drawType)) ==
            keccak256(abi.encodePacked("daily"))
        ) {
            require(
                block.timestamp >= dailySelectionTime + 1 days,
                "The daily selection is not due yet"
            );
            require(dailyParticipants.length > 0, "No participants yet.");
            require(dailyPool > 0, "No pool yet.");
            _;
            dailySelectionTime = block.timestamp;
        } else if (
            keccak256(abi.encodePacked(drawType)) ==
            keccak256(abi.encodePacked("weekly"))
        ) {
            require(
                block.timestamp >= weeklySelectionTime + 1 weeks,
                "The weekly selection is not due yet"
            );
            require(weeklyParticipants.length > 0, "No participants yet.");
            require(weeklyPool > 0, "No pool yet.");
            _;
            weeklySelectionTime = block.timestamp;
        } else if (
            keccak256(abi.encodePacked(drawType)) ==
            keccak256(abi.encodePacked("monthly"))
        ) {
            require(
                block.timestamp >= monthlySelectionTime + 30 days,
                "The monthly selection is not due yet"
            );
            require(monthlyParticipants.length > 0, "No participants yet.");
            require(monthlyPool > 0, "No pool yet.");
            _;
            monthlySelectionTime = block.timestamp;
        }
    }

    function contributeDaily() external payable {
        require(msg.value > 0, "Invalid amount");
        dailyPool += msg.value;
        if (!dailyContributors[msg.sender]) {
            dailyParticipants.push(msg.sender);
            dailyContributors[msg.sender] = true;
        }
        emit Contribution(msg.sender, msg.value, "daily");
    }

    function contributeWeekly() external payable {
        require(msg.value > 0, "Invalid amount");
        weeklyPool += msg.value;
        if (!weeklyContributors[msg.sender]) {
            weeklyParticipants.push(msg.sender);
            weeklyContributors[msg.sender] = true;
        }
        emit Contribution(msg.sender, msg.value, "weekly");
    }

    function contributeMonthly() external payable {
        require(msg.value > 0, "Invalid amount");
        monthlyPool += msg.value;
        if (!monthlyContributors[msg.sender]) {
            monthlyParticipants.push(msg.sender);
            monthlyContributors[msg.sender] = true;
        }
        emit Contribution(msg.sender, msg.value, "monthly");
    }

    function selectDailyWinner() external selectionDue("daily") {
        address winner = dailyParticipants[
            uint256(
                keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
            ) % dailyParticipants.length
        ];
        distributePrize(winner, "daily");
        emit WinnerSelection(winner, dailyPool, "daily");
    }

    function selectWeeklyWinner() external selectionDue("weekly") {
        address winner = weeklyParticipants[
            uint256(
                keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
            ) % weeklyParticipants.length
        ];
        distributePrize(winner, "weekly");
        emit WinnerSelection(winner, weeklyPool, "weekly");
    }

    function selectMonthlyWinner() external selectionDue("monthly") {
        address winner = monthlyParticipants[
            uint256(
                keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
            ) % monthlyParticipants.length
        ];
        distributePrize(winner, "monthly");
        emit WinnerSelection(winner, monthlyPool, "monthly");
    }

    function distributePrize(
        address winner,
        string memory draw
    ) internal nonReentrant {
        uint256 amount;
        uint256 remaining;
        if (
            keccak256(abi.encodePacked(draw)) ==
            keccak256(abi.encodePacked("daily"))
        ) {
            amount = (dailyPool * 90) / 100;
            remaining = dailyPool - amount;
            dailyPool = 0;
            resetParticipants("daily");
        } else if (
            keccak256(abi.encodePacked(draw)) ==
            keccak256(abi.encodePacked("weekly"))
        ) {
            amount = (weeklyPool * 90) / 100;
            remaining = weeklyPool - amount;
            weeklyPool = 0;
            resetParticipants("weekly");
        } else if (
            keccak256(abi.encodePacked(draw)) ==
            keccak256(abi.encodePacked("monthly"))
        ) {
            amount = (monthlyPool * 95) / 100;
            remaining = monthlyPool - amount;
            monthlyPool = 0;
            resetParticipants("monthly");
        }

        if (amount > 0) {
            payable(winner).transfer(amount);
        }
        if (remaining > 0) {
            megaJackpot.transfer((remaining * 25) / 100);
            blottoDistributor.deposite{value: (remaining * 50) / 100}();
            teamAddress1.transfer((remaining * 25 * 75) / 10000);
            teamAddress2.transfer((remaining * 25 * 25) / 10000);
        }
    }

    function resetParticipants(string memory draw) internal {
        if (
            keccak256(abi.encodePacked(draw)) ==
            keccak256(abi.encodePacked("daily"))
        ) {
            for (uint i = 0; i < dailyParticipants.length; i++) {
                dailyContributors[dailyParticipants[i]] = false;
            }
            delete dailyParticipants;
        } else if (
            keccak256(abi.encodePacked(draw)) ==
            keccak256(abi.encodePacked("weekly"))
        ) {
            for (uint i = 0; i < weeklyParticipants.length; i++) {
                weeklyContributors[weeklyParticipants[i]] = false;
            }
            delete weeklyParticipants;
        } else if (
            keccak256(abi.encodePacked(draw)) ==
            keccak256(abi.encodePacked("monthly"))
        ) {
            for (uint i = 0; i < monthlyParticipants.length; i++) {
                monthlyContributors[monthlyParticipants[i]] = false;
            }
            delete monthlyParticipants;
        }
    }
}
