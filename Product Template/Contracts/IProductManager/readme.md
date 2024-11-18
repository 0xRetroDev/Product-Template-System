# IProductManager Interface

## Overview

`IProductManager` is an interface for managing product deployment configurations, fees, and discounts. It allows external contracts or accounts to configure deployment parameters, manage approved ERC20 tokens for payments, and retrieve information about deployment costs and discount settings.

## Key Features

- **Deployment Configuration**: Set and retrieve parameters for product deployment, including costs and accepted ERC20 tokens.
- **Fee Management**: Configure fee settings for liquidity and fee destination.
- **Discount Configuration**: Define discounted rates for product deployment based on specific ERC20 tokens.
- **Token Approval Management**: Approve or disapprove ERC20 tokens for transactions.
- **Status Queries**: Check the contract's paused status and whether token transfers are currently allowed.

---

## Functions

### Configuration Functions

1. **`setDeploymentConfig`**
   - **Purpose**: Sets the deployment cost and token to be used for payments.
   - **Parameters**:
     - `cost`: Deployment cost in specified ERC20 tokens.
     - `token`: ERC20 token address to be used for payments.

2. **`setFeeConfig`**
   - **Purpose**: Configures the fee details for deployments.
   - **Parameters**:
     - `liquidityFeePercentage`: Percentage of the fee for liquidity.
     - `feeAddress`: Address to receive the fee.

3. **`setDiscountConfig`**
   - **Purpose**: Sets discount parameters based on specific ERC20 tokens.
   - **Parameters**:
     - `token`: ERC20 token used to apply the discount.
     - `deploymentCost`: Discounted deployment cost.
     - `feePercentage`: Reduced fee percentage for discounted deployments.

### View Functions

1. **`tokenTransferAllowed`**
   - **Returns**: A boolean indicating if token transfers are currently allowed.

2. **`deploymentConfig`**
   - **Returns**: The current deployment configuration (`DeploymentConfig` struct).

3. **`feeConfig`**
   - **Returns**: The current fee configuration (`FeeConfig` struct).

4. **`discountConfig`**
   - **Returns**: The current discount configuration (`DiscountConfig` struct).

5. **`approvedTokens`**
   - **Purpose**: Checks if an ERC20 token is approved for use.
   - **Parameters**: `token`: The address of the ERC20 token.
   - **Returns**: A boolean indicating if the token is approved.

6. **`isPaused`**
   - **Returns**: `true` if the contract is paused, `false` otherwise.

### Token Approval Management

1. **`approveToken`**
   - **Purpose**: Approves an ERC20 token for usage in transactions.
   - **Parameters**: `token`: Address of the ERC20 token.

2. **`disapproveToken`**
   - **Purpose**: Removes approval for an ERC20 token.
   - **Parameters**: `token`: Address of the ERC20 token.
