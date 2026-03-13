// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";
contract DeployLottery is Script {
    function run() external {
        vm.startBroadcast();
        Lottery lottery = new Lottery();
        console.log("Lottery deployed:", address(lottery));
        vm.stopBroadcast();
    }
}
