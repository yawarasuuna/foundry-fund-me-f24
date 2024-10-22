// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe; // v2 // in order to call MINIMUM_USD test(or other tests), we need access to fundMe, and since earlier it was scoped in the function setUp, we had to make it a state variable

    address USER = makeAddr("user"); // only test
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // v1 FundMe fundMe = new FundMe();
        // v2 fundMe = new FundMe(); // our fundMe variable, of type FundMe, is going to be a new FundMe contract;
        DeployFundMe deployFundMe = new DeployFundMe(); // v3
        fundMe = deployFundMe.run(); // run will return a FundMe contract from the script DeployFundMe.s.sol
        vm.deal(USER, STARTING_BALANCE); // gives USER, 10 ether STARTING_BALANCE to run vm.prank
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testIfOwnerIsMsgSender() public view {
        // v3 console.log(fundMe.i_owner());
        console.log(fundMe.getOwner()); // v4
        console.log(msg.sender);
        // v1 assertEq(fundMe.i_owner(), msg.sender);  // msg.sender is our anvil acc, whereas fundMe variable was called by this contract, FundMeTest, when function setUp was called
        // v2 assertEq(fundMe.i_owner(), address(this)); // in this case, fundMe owner is this onttract, which is checked against this contractscs address
        // v3 assertEq(fundMe.i_owner(), msg.sender); // v3, this contract is no longer deploying FundMe directly
        assertEq(fundMe.getOwner(), msg.sender); // v4 i_owner is now private, so we can use getter instead
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // cheatcode; Next line should revert
        fundMe.fund{value: 1}(); // if we wanted to send value, use fundMe.fund{value: #####}();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        // vm.prank(USER); // next tx will be sent by USER; prank only in foundry
        // fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}(); // instead of running these lines everytime, we can use a modifier instead, seen that funded has already been tested earlier;
        vm.expectRevert(); // expectRevert ignores vm, so it will expect to revert on the next line
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft(); // helps us know how much gas was spent; gasleft() built it function in solidity, tells how much gas is left after a transaction call
        vm.txGasPrice(GAS_PRICE); //
        vm.prank(fundMe.getOwner()); // onlyOwner can withdrawk
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // built it to solidity, tells current gasprice
        console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        // after 0.8.0, cant cast explicitly from address to uint256, needs to use uint160 which has same bytes as an actual address;
        uint160 numberOfFunders = 10; // if we want numbers to generate addresses, uint160 required after solidity 0.8.0
        uint160 startingFunderIndex = 1; // avoid starting at 0 address during test

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // set up prank from address that has some ether, basically vm.deal+vm.prank;
            fundMe.fund{value: SEND_VALUE}();
        }
        // Act

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank;
        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        // after 0.8.0, cant cast explicitly from address to uint256, needs to use uint160 which has same bytes as an actual address;
        uint160 numberOfFunders = 10; // if we want numbers to generate addresses, uint160 required after solidity 0.8.0
        uint160 startingFunderIndex = 1; // avoid starting at 0 address during test

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // set up prank from address that has some ether, basically vm.deal+vm.prank;
            fundMe.fund{value: SEND_VALUE}();
        }
        // Act

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank;
        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
