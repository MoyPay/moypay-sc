// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {GasEstimator} from "../src/GasEstimator.sol";

contract GasEstimationScript is Script {
    GasEstimator public gasEstimator;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the gas estimator contract
        gasEstimator = new GasEstimator();
        console2.log("GasEstimator deployed at:", address(gasEstimator));
        
        // Estimate gas for various operations
        uint256 gasUsed = gasEstimator.estimateGasUsage();
        console2.log("Estimated gas usage:", gasUsed);
        
        uint256 functionGas = gasEstimator.estimateFunctionGas(100, 200);
        console2.log("Function gas cost:", functionGas);
        
        uint256 storageGas = gasEstimator.estimateStorageGas(500);
        console2.log("Storage gas cost:", storageGas);
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev Estimate gas for a specific function call
     * @param target The target contract address
     * @param data The function call data
     * @return estimatedGas The estimated gas cost
     */
    function estimateGasForCall(address target, bytes memory data) 
        public 
        view 
        returns (uint256 estimatedGas) 
    {
        // This would be called externally to estimate gas
        // In a real scenario, you'd use a library or RPC call
        estimatedGas = 21000; // Base gas cost
        estimatedGas += data.length * 16; // 16 gas per byte of data
    }
}