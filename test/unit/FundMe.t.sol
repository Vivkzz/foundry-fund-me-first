// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

// below  we import console to print statements during debugging
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 public constant SENDING_VALUE = 0.1 ether;
    uint256 public constant STARTING_VALUE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        vm.deal(USER, STARTING_VALUE);
    }

    function testDemo() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwner() public view {
        // console.log(fundMe.i_owner());
        // console.log(msg.sender);
        // console.log(address(this));
        assertEq(fundMe.getOwner(), msg.sender);

        // use -vv for logs
    }

    function testVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // it will expect the txn at next line will fail if pass then generate error
        fundMe.fund(); // sends 0 requires 5  (this will pass)
        // uint256 cat = 1; // this will fail
    }

    function testFund() public {
        vm.prank(USER);
        fundMe.fund{value: SENDING_VALUE}();

        uint256 amount_Funded = fundMe.getAdddressToAmountFunded(USER);
        assertEq(amount_Funded, SENDING_VALUE);
    }

    function testAddFundToArray() public {
        vm.prank(USER);
        fundMe.fund{value: SENDING_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testWithdraw() public {
        vm.prank(USER);
        fundMe.fund{value: SENDING_VALUE}();

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testSingleWithdraw() public {
        vm.prank(USER);
        fundMe.fund{value: SENDING_VALUE}();

        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundmeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundmeBalance = address(fundMe).balance;

        //bcz all amount is transfer to owner
        assertEq(endingFundmeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundmeBalance,
            endingOwnerBalance
        );
    }

    function testMultipleWithdraw() public {
        uint160 numberOfFunders = 10;
        uint160 startingFundingIndex = 1;

        for (uint160 i = startingFundingIndex; i <= numberOfFunders; i++) {
            hoax(address(i), SENDING_VALUE);
            fundMe.fund{value: SENDING_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundmeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert

        assert(address(fundMe).balance == 0);
        assert(
            startingFundmeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testMultipleWithdrawCheaper() public {
        uint160 numberOfFunders = 10;
        uint160 startingFundingIndex = 1;

        for (uint160 i = startingFundingIndex; i <= numberOfFunders; i++) {
            hoax(address(i), SENDING_VALUE);
            fundMe.fund{value: SENDING_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundmeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert

        assert(address(fundMe).balance == 0);
        assert(
            startingFundmeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
    // check gas using forge snapshot
    
}
