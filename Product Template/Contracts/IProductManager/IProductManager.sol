// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IProductManager
 * @dev This contract interface provides the functionality for managing the product deployment process.
 */
interface IProductManager {
    /**
     * @dev Struct to hold the deployment configuration parameters.
     * @param cost The cost of deploying a {ProductNameHere}.
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

    /**
     * @dev Sets the deployment configuration parameters.
     * @param cost The cost of deploying a {ProductNameHere}.
     * @param token The ERC20 token used for payment.
     */
    function setDeploymentConfig(uint96 cost, IERC20 token) external;

    /**
     * @dev Sets the fee configuration parameters.
     * @param liquidityFeePercentage The percentage of the deployment cost that goes to the fee address.
     * @param feeAddress The address that receives the fee.
     */
    function setFeeConfig(uint32 liquidityFeePercentage, address feeAddress) external;

    /**
     * @dev Sets the discount configuration parameters.
     * @param token The ERC20 token used for the discount.
     * @param deploymentCost The discounted deployment cost.
     * @param feePercentage The discounted fee percentage.
     */
    function setDiscountConfig(IERC20 token, uint96 deploymentCost, uint32 feePercentage) external;

    /**
     * @dev Checks if token transfers are allowed.
     * @return A boolean indicating if token transfers are allowed.
     */
    function tokenTransferAllowed() external view returns (bool);

    /**
     * @dev Returns the deployment configuration.
     * @return The deployment configuration struct.
     */
    function deploymentConfig() external view returns (DeploymentConfig memory);

    /**
     * @dev Returns the fee configuration.
     * @return The fee configuration struct.
     */
    function feeConfig() external view returns (FeeConfig memory);

    /**
     * @dev Returns the discount configuration.
     * @return The discount configuration struct.
     */
    function discountConfig() external view returns (DiscountConfig memory);

    /**
     * @dev Approves an ERC20 token for use in the contract.
     * @param token The ERC20 token to approve.
     */
    function approveToken(IERC20 token) external;

    /**
     * @dev Disapproves an ERC20 token for use in the contract.
     * @param token The ERC20 token to disapprove.
     */
    function disapproveToken(IERC20 token) external;

    /**
     * @dev Checks if an ERC20 token is approved for use in the contract.
     * @param token The ERC20 token to check.
     * @return A boolean indicating if the token is approved.
     */
    function approvedTokens(address token) external view returns (bool);

    /**
     * @notice Checks if the ProductManager is paused.
     * @return bool True if the contract is paused, false otherwise.
     */
    function isPaused() external view returns (bool);
}
