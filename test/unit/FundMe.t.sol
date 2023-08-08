// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";
import {FundMe} from "src/FundMe.sol";

contract FundMeTest is Test {

    FundMe fundMe;
    address user = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant GAS_PRICE = 1;

    modifier funded() {
        vm.prank(user);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(user, STARTING_BALANCE);
    }

    function test_MinimumDollarIsFive() external {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function test_OwnerIsMsgSender() external {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function test_PriceFeedVersionIsAccurate() external {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function test_RevertWhen_FundWithoutEnoughEth() external {
        vm.expectRevert();
        fundMe.fund();
    }

    function test_FundUpdatesFundedDataStructure() external funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(user);
        assertEq(amountFunded, SEND_VALUE);
    }

    function test_AddsFunderToArrayOfFunders() external funded {
        address funder = fundMe.getFunder(0);
        assertEq(user, funder);
    }

    function test_RevertWhen_OwnerDoesNotWithdraw() external funded {
        vm.expectRevert();
        vm.prank(user);
        fundMe.withdraw();
    }

    function test_WithdrawWithSingleFunder() external funded {
        // Arrange
        uint256 initialOwnerBalance = fundMe.getOwner().balance;
        uint256 initialFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 finalOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(initialFundMeBalance + initialOwnerBalance, finalOwnerBalance);
    }

    function test_WithdrawFromMultipleFunders() external funded {
        // Arrange
        uint8 numberOfFunders = 10;
        uint8 startingFunderIndex = 2;

        for (uint8 i = startingFunderIndex; i <= numberOfFunders; i++) {
            hoax(address(uint160(i)), SEND_VALUE); // prank + deal
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 initialOwnerBalance = fundMe.getOwner().balance;
        uint256 initialFundMeBalance = address(fundMe).balance;

        // Act
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // uint256 gasEnd = gasleft();

        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        // Assert
        uint256 finalOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(initialFundMeBalance + initialOwnerBalance, finalOwnerBalance);
    }

    function test_WithdrawFromMultipleFundersCheaper() external funded {
        // Arrange
        uint8 numberOfFunders = 10;
        uint8 startingFunderIndex = 2;

        for (uint8 i = startingFunderIndex; i <= numberOfFunders; i++) {
            hoax(address(uint160(i)), SEND_VALUE); // prank + deal
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 initialOwnerBalance = fundMe.getOwner().balance;
        uint256 initialFundMeBalance = address(fundMe).balance;

        // Act
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        // uint256 gasEnd = gasleft();

        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        // Assert
        uint256 finalOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(initialFundMeBalance + initialOwnerBalance, finalOwnerBalance);
    }
}
