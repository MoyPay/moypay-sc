// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IMockVault} from "./intefaces/IMockVault.sol";

contract EarnStandard is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Events
    event EarnExecuted(
        address indexed protocol, address indexed token, address indexed user, uint256 amount, uint256 shares
    );
    event EarnWithdrawn(
        address indexed protocol, address indexed token, address indexed user, uint256 amount, uint256 shares
    );

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // ** GENERALIZE ALL EARN PROTOCOL
    function execEarn(address _protocol, address _token, address _user, uint256 _amount)
        public
        nonReentrant
        returns (uint256)
    {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        IERC20(_token).approve(_protocol, _amount);
        uint256 shares = IMockVault(_protocol).deposit(_token, _amount, _user);
        emit EarnExecuted(_protocol, _token, _user, _amount, shares);
        return shares;
    }

    function withdrawEarn(address _protocol, address _token, address _user, uint256 _shares)
        public
        nonReentrant
        returns (uint256)
    {
        uint256 amount = IMockVault(_protocol).withdraw(_token, _shares, _user);

        IERC20(_token).approve(msg.sender, amount);
        IERC20(_token).safeTransfer(msg.sender, amount);
        emit EarnWithdrawn(_protocol, _token, _user, amount, _shares);
        return amount;
    }
}
