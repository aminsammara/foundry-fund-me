// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        address priceFeedAddress
    ) internal view returns (uint256) {
        // Address : 0x694AA1769357215DE4FAC081bf1f309aDC325306 ETH/USD data feed on Sepolia
        // ABI : This is what we're going to use the interface for
        // the alternative to using th`e interface is to include the code so we could compile at runtime and obtain ABI

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        // ETH price in USD
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // it is a whole number but checking AggregatorV3Interface.decimal() we can see there's meant to be 8 decimal places
        // we multiple by 1e10 so that getPrice and ethAmount both have 18 decimals
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        address priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // both nums have 18 decimal places so we divide by 1,000,000,000,000,000,000
        // the returned amount below is the value in USD of ethAmount expressed as a 18 decimal number
        return (ethAmount * ethPrice) / 1e18;
    }
}
