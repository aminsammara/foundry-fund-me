//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // anything before vm.startBroadcast() -> it won't send as a real tx and instead will simulate it in a simulated environment == saves gas
        HelperConfig helperConfig = new HelperConfig();

        // anything after vm.startBroadcast() is a real tx
        // remember that contracts deployed inside a startBroadcast() get created by msg.sender (not by contract that deployed them)
        vm.startBroadcast();
        FundMe fundMe = new FundMe(helperConfig.activeNetworkConfig());
        vm.stopBroadcast();
        return fundMe;
    }
}
