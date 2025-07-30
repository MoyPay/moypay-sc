// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title GasOptimizationExample
 * @dev Demonstrates gas optimization techniques and estimation
 */
contract GasOptimizationExample {
    
    // Events for gas-efficient logging
    event UserRegistered(address indexed user, uint256 timestamp);
    event BalanceUpdated(address indexed user, uint256 newBalance, uint256 gasUsed);
    
    // Storage variables
    mapping(address => uint256) public balances;
    mapping(address => bool) public isRegistered;
    
    // Gas tracking
    uint256 public totalGasUsed;
    
    /**
     * @dev Gas-optimized user registration
     * @param user The user address to register
     */
    function registerUser(address user) public {
        uint256 gasBefore = gasleft();
        
        require(!isRegistered[user], "User already registered");
        isRegistered[user] = true;
        balances[user] = 0;
        
        uint256 gasUsed = gasBefore - gasleft();
        totalGasUsed += gasUsed;
        
        emit UserRegistered(user, block.timestamp);
    }
    
    /**
     * @dev Gas-optimized balance update with batching
     * @param users Array of user addresses
     * @param amounts Array of amounts to add
     */
    function batchUpdateBalances(
        address[] memory users,
        uint256[] memory amounts
    ) public {
        require(users.length == amounts.length, "Arrays length mismatch");
        
        uint256 gasBefore = gasleft();
        
        for (uint256 i = 0; i < users.length; i++) {
            require(isRegistered[users[i]], "User not registered");
            balances[users[i]] += amounts[i];
        }
        
        uint256 gasUsed = gasBefore - gasleft();
        totalGasUsed += gasUsed;
    }
    
    /**
     * @dev Gas-optimized single balance update
     * @param user The user address
     * @param amount The amount to add
     */
    function updateBalance(address user, uint256 amount) public {
        require(isRegistered[user], "User not registered");
        
        uint256 gasBefore = gasleft();
        
        balances[user] += amount;
        
        uint256 gasUsed = gasBefore - gasleft();
        totalGasUsed += gasUsed;
        
        emit BalanceUpdated(user, balances[user], gasUsed);
    }
    
    /**
     * @dev Estimate gas for balance update
     * @param user The user address
     * @param amount The amount to add
     * @return estimatedGas The estimated gas cost
     */
    function estimateBalanceUpdateGas(address user, uint256 amount) 
        public 
        view 
        returns (uint256 estimatedGas) 
    {
        require(isRegistered[user], "User not registered");
        
        uint256 gasBefore = gasleft();
        
        // Simulate the operation without modifying state
        uint256 tempBalance = balances[user] + amount;
        
        uint256 gasAfter = gasleft();
        estimatedGas = gasBefore - gasAfter;
        
        // Add event emission cost (approximate)
        estimatedGas += 375 + 32 * 8; // Event base cost + data cost
    }
    
    /**
     * @dev Estimate gas for batch operation
     * @param userCount Number of users in batch
     * @return estimatedGas The estimated gas cost
     */
    function estimateBatchGas(uint256 userCount) 
        public 
        view 
        returns (uint256 estimatedGas) 
    {
        uint256 gasBefore = gasleft();
        
        // Simulate batch operation
        for (uint256 i = 0; i < userCount; i++) {
            // Simulate balance update
            uint256 temp = 0;
            temp += 100;
        }
        
        uint256 gasAfter = gasleft();
        estimatedGas = gasBefore - gasAfter;
    }
    
    /**
     * @dev Get gas efficiency metrics
     * @return totalOperations Total number of operations
     * @return averageGasPerOperation Average gas per operation
     */
    function getGasMetrics() public view returns (uint256 totalOperations, uint256 averageGasPerOperation) {
        // This would typically track actual operation counts
        // For demonstration, we'll use a fixed number
        totalOperations = 100;
        averageGasPerOperation = totalGasUsed / totalOperations;
    }
    
    /**
     * @dev Gas-optimized view function
     * @param user The user address
     * @return balance The user's balance
     */
    function getUserBalance(address user) public view returns (uint256 balance) {
        return balances[user];
    }
    
    /**
     * @dev Gas-optimized bulk balance check
     * @param users Array of user addresses
     * @return userBalances Array of user balances
     */
    function getBulkBalances(address[] memory users) 
        public 
        view 
        returns (uint256[] memory userBalances) 
    {
        userBalances = new uint256[](users.length);
        
        for (uint256 i = 0; i < users.length; i++) {
            userBalances[i] = balances[users[i]];
        }
    }
}