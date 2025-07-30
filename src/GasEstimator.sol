// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title GasEstimator
 * @dev Demonstrates various methods for gas estimation in Solidity
 */
contract GasEstimator {
    
    // Storage variable to track gas usage
    uint256 public gasUsed;
    
    /**
     * @dev Estimates gas usage for a specific operation
     * @return The amount of gas used
     */
    function estimateGasUsage() public returns (uint256) {
        uint256 gasBefore = gasleft();
        
        // Simulate some operation
        uint256 result = 0;
        for (uint256 i = 0; i < 100; i++) {
            result += i;
        }
        
        uint256 gasAfter = gasleft();
        gasUsed = gasBefore - gasAfter;
        
        return gasUsed;
    }
    
    /**
     * @dev Estimates gas for external contract calls
     * @param target The address of the target contract
     * @param data The calldata to send
     * @return estimatedGas The estimated gas cost
     */
    function estimateExternalCallGas(address target, bytes memory data) 
        public 
        view 
        returns (uint256 estimatedGas) 
    {
        uint256 gasBefore = gasleft();
        
        // Use staticcall to estimate without modifying state
        (bool success, ) = target.staticcall(data);
        require(success, "External call failed");
        
        uint256 gasAfter = gasleft();
        estimatedGas = gasBefore - gasAfter;
    }
    
    /**
     * @dev Estimates gas for a function with parameters
     * @param param1 First parameter
     * @param param2 Second parameter
     * @return gasCost The gas cost for the operation
     */
    function estimateFunctionGas(uint256 param1, uint256 param2) 
        public 
        returns (uint256 gasCost) 
    {
        uint256 gasBefore = gasleft();
        
        // Your function logic here
        uint256 result = param1 + param2;
        result = result * 2;
        
        uint256 gasAfter = gasleft();
        gasCost = gasBefore - gasAfter;
    }
    
    /**
     * @dev View function to estimate gas without state changes
     * @param input Input parameter
     * @return result The result of the computation
     */
    function estimateViewFunctionGas(uint256 input) 
        public 
        view 
        returns (uint256 result) 
    {
        // View functions can't use gasleft() effectively
        // But you can estimate their gas cost externally
        
        result = input * 2 + 10;
        return result;
    }
    
    /**
     * @dev Calculates gas cost for storage operations
     * @param value Value to store
     * @return gasCost The gas cost for storage
     */
    function estimateStorageGas(uint256 value) 
        public 
        returns (uint256 gasCost) 
    {
        uint256 gasBefore = gasleft();
        
        // Storage operation
        gasUsed = value;
        
        uint256 gasAfter = gasleft();
        gasCost = gasBefore - gasAfter;
    }
}