// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {U512Harness} from "../examples/U512Harness.sol";

contract DeployU512Harness is Script {
    function run() external returns (U512Harness harness) {
        vm.startBroadcast();
        harness = new U512Harness();
        vm.stopBroadcast();
    }
}
