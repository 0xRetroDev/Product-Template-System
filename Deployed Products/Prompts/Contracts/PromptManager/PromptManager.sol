// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
* @title PromptManager
* @dev This contract manages the deployment and configuration of prompts.
*/
contract PromptManager is AccessControl, Pausable {
   bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

   /**
    * @dev Struct to hold the deployment configuration parameters.
    * @param cost The cost of deploying a prompt.
    * @param token The ERC20 token used for payment.
    */
   struct DeploymentConfig {
       uint96 cost;
       IERC20 token;
   }

   /**
    * @dev Struct to hold the fee configuration parameters.
    * @param liquidityFeePercentage The percentage of the deployment cost that goes to the fee address.
    * @param feeAddress The address that receives the fee.
    */
   struct FeeConfig {
       uint32 liquidityFeePercentage;
       address feeAddress;
   }

   /**
    * @dev Struct to hold the discount configuration parameters.
    * @param token The ERC20 token used for the discount.
    * @param deploymentCost The discounted deployment cost.
    * @param feePercentage The discounted fee percentage.
    */
   struct DiscountConfig {
       IERC20 token;
       uint96 deploymentCost;
       uint32 feePercentage;
   }

   DeploymentConfig public deploymentConfig;
   FeeConfig public feeConfig;
   DiscountConfig public discountConfig;

   bool private _tokenTransferAllowed;

   mapping(address => bool) public approvedTokens;

   event DeploymentConfigUpdated(uint96 cost, IERC20 token);
   event FeeConfigUpdated(uint32 liquidityFeePercentage, address feeAddress);
   event DiscountConfigSet(IERC20 token, uint96 deploymentCost, uint32 feePercentage);
   event TokenApproved(IERC20 token);
   event TokenRemoved(IERC20 token);

   /**
    * @dev Initializes the contract with the admin address.
    * @param admin The address to grant the DEFAULT_ADMIN_ROLE and MANAGER_ROLE to.
    */
   constructor(address admin) {
       _grantRole(DEFAULT_ADMIN_ROLE, admin);
       _grantRole(MANAGER_ROLE, admin);
   }

   /**
    * @dev Sets the deployment configuration parameters.
    * @param cost The cost of deploying a prompt.
    * @param token The ERC20 token used for payment.
    */
   function setDeploymentConfig(uint96 cost, IERC20 token) external onlyRole(MANAGER_ROLE) {
       deploymentConfig = DeploymentConfig(cost, token);
       emit DeploymentConfigUpdated(cost, token);
   }

   /**
    * @dev Sets the fee configuration parameters.
    * @param liquidityFeePercentage The percentage of the deployment cost that goes to the fee address.
    * @param feeAddress The address that receives the fee.
    */
   function setFeeConfig(uint32 liquidityFeePercentage, address feeAddress) external onlyRole(MANAGER_ROLE) {
       require(feeAddress != address(0), "Invalid fee address");
       feeConfig = FeeConfig(liquidityFeePercentage, feeAddress);
       emit FeeConfigUpdated(liquidityFeePercentage, feeAddress);
   }

   /**
    * @dev Sets the discount configuration parameters.
    * @param token The ERC20 token used for the discount.
    * @param deploymentCost The discounted deployment cost.
    * @param feePercentage The discounted fee percentage.
    */
   function setDiscountConfig(IERC20 token, uint96 deploymentCost, uint32 feePercentage) external onlyRole(MANAGER_ROLE) {
       discountConfig = DiscountConfig(token, deploymentCost, feePercentage);
       emit DiscountConfigSet(token, deploymentCost, feePercentage);
   }

   /**
    * @dev Checks if token transfers are allowed.
    * @return A boolean indicating if token transfers are allowed.
    */
   function tokenTransferAllowed() external view returns (bool) {
       return _tokenTransferAllowed;
   }

   /**
    * @dev Sets whether token transfers are allowed.
    * @param allowed A boolean indicating if token transfers should be allowed.
    */
   function setTokenTransferAllowed(bool allowed) external onlyRole(MANAGER_ROLE) {
       _tokenTransferAllowed = allowed;
   }

   /**
    * @notice Adds a token to the list of approved tokens.
    * @param token The ERC20 token to approve.
    */
   function approveToken(IERC20 token) external onlyRole(MANAGER_ROLE) {
       approvedTokens[address(token)] = true;
       emit TokenApproved(token);
   }

   /**
    * @notice Removes a token from the list of approved tokens.
    * @param token The ERC20 token to disapprove.
    */
   function disapproveToken(IERC20 token) external onlyRole(MANAGER_ROLE) {
       approvedTokens[address(token)] = false;
       emit TokenRemoved(token);
   }

       /**
     * @dev Pauses contract activity.
     * @notice This function pauses contract activity, preventing users from registering, rating
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses contract activity.
     * @notice This function unpauses contract activity, allowing users to register, rate models
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Checks if the contract is currently paused.
     * @return bool True if the contract is paused, false otherwise.
     */
    function isPaused() external view returns (bool) {
        return paused();
    }
}