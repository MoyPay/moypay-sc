// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {GasEstimator} from "../src/GasEstimator.sol";

contract GasEstimatorTest is Test {
    GasEstimator public gasEstimator;
    
    function setUp() public {
        gasEstimator = new GasEstimator();
    }
    
    function testEstimateGasUsage() public {
        uint256 gasUsed = gasEstimator.estimateGasUsage();
        console2.log("Gas used for operation:", gasUsed);
        
        // Verify gas was used
        assertTrue(gasUsed > 0, "Gas usage should be greater than 0");
    }
    
    function testEstimateFunctionGas() public {
        uint256 gasCost = gasEstimator.estimateFunctionGas(10, 20);
        console2.log("Gas cost for function:", gasCost);
        
        assertTrue(gasCost > 0, "Gas cost should be greater than 0");
    }
    
    function testEstimateStorageGas() public {
        uint256 gasCost = gasEstimator.estimateStorageGas(100);
        console2.log("Gas cost for storage operation:", gasCost);
        
        assertTrue(gasCost > 0, "Storage gas cost should be greater than 0");
    }
    
    function testGasEstimationWithFuzz(uint256 param1, uint256 param2) public {
        vm.assume(param1 < type(uint256).max / 2);
        vm.assume(param2 < type(uint256).max / 2);
        
        uint256 gasCost = gasEstimator.estimateFunctionGas(param1, param2);
        console2.log("Fuzzed gas cost:", gasCost);
        
        assertTrue(gasCost > 0, "Gas cost should be greater than 0");
    }
}