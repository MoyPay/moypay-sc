// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
// import {MockUSDC} from "../src/Mocks/MockUSDC.sol";
import {Factory} from "../src/Factory.sol";
import {Organization} from "../src/Organization.sol";
import {EarnStandard} from "../src/EarnStandard.sol";
import {MockVault} from "../src/Mocks/MockVault.sol";

contract MoyPayScript is Script {
    address public mockUSDC = 0x0440d45A296fBD5d41D5B37DEF75DE710177b819;
    // MockUSDC public mockUSDC;
    Factory public factory;
    Organization public organization;
    EarnStandard public earnStandard;
    MockVault public mockVault;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("etherlink_testnet"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        // mockUSDC = new MockUSDC();
        console.log("export const mockUSDC = ", address(mockUSDC));

        factory = new Factory();
        console.log("export const factory = ", address(factory));

        organization = new Organization(address(mockUSDC), address(factory), vm.envAddress("ADDRESS"), "MoyPay");
        console.log("export const organization = ", address(organization));

        earnStandard = new EarnStandard();
        console.log("export const earnStandard = ", address(earnStandard));

        mockVault = new MockVault("MORPHO");
        factory.addEarnProtocol(address(mockVault));
        console.log("export const mockVaultMorpho = ", address(mockVault));

        mockVault = new MockVault("COMPOUND");
        factory.addEarnProtocol(address(mockVault));
        console.log("export const mockVaultCompound = ", address(mockVault));

        mockVault = new MockVault("CENTUARI");
        factory.addEarnProtocol(address(mockVault));
        console.log("export const mockVaultCentuari = ", address(mockVault));

        mockVault = new MockVault("TUMBUH");
        factory.addEarnProtocol(address(mockVault));
        console.log("export const mockVaultTumbuh = ", address(mockVault));

        mockVault = new MockVault("CAER");
        factory.addEarnProtocol(address(mockVault));
        console.log("export const mockVaultCaer = ", address(mockVault));

        mockVault = new MockVault("AAVE");
        factory.addEarnProtocol(address(mockVault));
        console.log("export const mockVaultAave = ", address(mockVault));

        factory.setEarnStandard(address(earnStandard));

        vm.stopBroadcast();
    }

    // RUN
    // forge script MoyPayScript --broadcast -vvv --verify
}
