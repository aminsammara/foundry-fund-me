//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {PriceConverter} from "./PriceConverter.sol";

// it is customary to name errors as `ContractName__ErrorName` with two underscores. This way you know which contracts led to errors.
error FundMe__NotOwner();

// Required funcitonality
// Get funds from usrs
// Withdraw funds
// Set a minimum funding amount in USD

contract FundMe {
    // so we can use functions in PriceConverter library like this x.getPrice() where x is any uint256
    using PriceConverter for uint256;

    // we convert minimumUSD to an 18 decimal number because getConversionRate returns an 18 decimal number that represents USD value.
    // a `constant` is more gas efficient. It no longer takes a storage spot.
    // it is convention to caps all constants
    uint256 public constant MINIMUM_USD = 5e18;

    address[] private s_funders;
    address private priceFeedAddress;

    mapping(address funders => uint256 balance) private s_balances;

    // for vars that get set once but in a different line than where they're defined - we use `immutable` keyword.
    // similar cost savings to `constant` keyword. It is customary to prepend `i_` before immutable variables.
    // `constant` and `immutable` variables are stored in the bytecode of the contract rather than in a storage slot, leading to gas savings.

    address private immutable i_owner;

    constructor(address _priceFeedAddress) {
        i_owner = msg.sender;
        priceFeedAddress = _priceFeedAddress;
    }

    function fund() public payable {
        // Allow users to send $
        // Have a minimum $ sent
        require(
            msg.value.getConversionRate(priceFeedAddress) >= MINIMUM_USD,
            "Please send at least $5"
        ); // 1e18 = 1 ETH = 1 * 10 **18
        s_funders.push(msg.sender);
        s_balances[msg.sender] += msg.value;
        // What is a revert?
        // Undo any actions that have been done, and send the remaining gas back
    }

    function cheaperWithdraw() public onlyOwner {
        // the length of arrays is stored in storage typically and takes a full slot (32 bytes)
        // the cost to read from storage (sload) is 33 times more expensive than the cost to read from memory (mload)
        // variables defined inside function scopes get stored in memory and not storage and therefore we should not
        // be repeatedly reading/writing to/from storage. (like we were in the for loop of the below withdraw function)
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_balances[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(
            callSuccess,
            "Call failed, unable to withdraw using cheapWithdraw function"
        );
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_balances[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);
        // withdraw funds
        // three options: transfer, send, call

        //1. transfer: if transfer failed, throw error
        // msg.sender = address
        // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);

        // 2. send: if transfer failed, returns false
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        //3. call: lower level: can call any function in ETH without ABI
        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        // since we're not calling a function, we don't need the dataReturned
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // when the modifier is added to a function, solidity executes the modifier first before calling the function
    // the underscore says "then add whatever it is you want to do in the function"
    // if we had the underscore first, then solidity would execute the funciton then whatever is in the modifier
    modifier onlyOwner() {
        // this is more efficient than reverting with a string, because we no longer have to store strings.
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        // require(msg.sender == i_owner, "Sender is not owner");
        _;
    }

    // What happens if someone sends this contract ETH without calling the fund function?

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * View / Pure functions (Getters)
     *
     */

    function getAddressToAmountFunded(
        address _fundingAddresss
    ) external view returns (uint256) {
        return s_balances[_fundingAddresss];
    }

    function getFunder(uint256 _index) external view returns (address) {
        return s_funders[_index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
