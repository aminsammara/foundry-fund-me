// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// .t.sol is a solidity convention for naming test files
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // DeployFundMe deployFundMe = new DeployFundMe();
    DeployFundMe deployFundMe;
    FundMe fundMe;
    // we'll use another Foundry Test Cheatcode to be able to easily tell and control which address calls which functions/creates what contracts
    // the cheatcode is called prank and makeAddr is another forge-sd (i.e. not vm.makeAddr()) that helps create new addresses
    // makeAddr takes in a name (string) and returns a new address.
    // We need to fund this new address with some ETH. For that we'll use another cheatcode

    address USER = makeAddr("amin");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant START_BALANCE = SEND_VALUE * 10;
    uint256 constant GAS_PRICE = 1;

    // setUp() always runs first (of all other functions in the test file)
    // we use it to deploy our contract
    function setUp() external {
        deployFundMe = new DeployFundMe();
        vm.deal(USER, START_BALANCE); // gives our fake users a balance of START_BALANCE eth.
        fundMe = deployFundMe.run();
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        // FundMeTest contract is what actually deployts the FundMe contract.
        // Therefore, fundMe.i_owner() = FundMeTest = address(this)
        // msg.sender() remains the user which deployed FundMeTest().
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // function testPriceFeedVersionIsFour() public {
    //     uint256 version = fundMe.getVersion();
    //     assertEq(version, 4);
    // }

    /* 
    1. Unit
        - Testing a specific part of our code
    2. Integration
        - Testing how our code works with other parts of our code
            i.e. a testing a function which calls another function (potentially on some other contract)
    3. Forked
        - Testing our code in a simulated environment
        - We do this in foundry by adding --fork-url option
        - Foundry will spin up a local anvil chain but will "read" stuff from the blockchain RPC specified in the option.
        - Doing so for example, allows us to test our fund() function with non-Sepolia ETH since it will spin up local accounts
        - But will read the values (of chainlink's price feed) from the Sepolia testnet
    4. Staging
        - Testing our code in a real environment that isn't prod
    */

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // expectRevert() is a Forge cheatcode. More cheatcodes on their website.
        // hey the next line should revert.<=> assert("this fails")
        fundMe.fund(); // we're not sending value so this should fail. if we were to send value, fundMe.fund{value: }()
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq( // what about gas cost spent?
            // for anvil, gas spent defaults to zero
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawWithMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // 1. vm.prank(someaddress) -> 2. vm.deal(someaddress)
            // hoax() is from forge-std and does 1 + 2 combined
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert

        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // 1. vm.prank(someaddress) -> 2. vm.deal(someaddress)
            // hoax() is from forge-std and does 1 + 2 combined
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert

        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }
}
