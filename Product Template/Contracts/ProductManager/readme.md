# ProductManager Contract Documentation

## Overview

The `ProductManager` contract serves as the central configuration and management system for product deployments. It handles deployment costs, fee structures, token approvals, and access control for the entire product ecosystem.

## Contract Details

- **License**: MIT
- **js Version**: ^0.8.24
- **Contract Type**: Implementation
- **Inheritances**:
  - OpenZeppelin AccessControl
  - OpenZeppelin Pausable

## Import Statements

```js
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
```

## Access Control Roles

```js
bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
DEFAULT_ADMIN_ROLE // Inherited from AccessControl
```

- **MANAGER_ROLE**: Operational permissions for configuration changes
- **DEFAULT_ADMIN_ROLE**: Full administrative access with highest privileges

## Data Structures

### DeploymentConfig
```js
struct DeploymentConfig {
    uint96 cost;      // Base cost for deployment
    IERC20 token;     // Token used for payment
}
```

### FeeConfig
```js
struct FeeConfig {
    uint32 liquidityFeePercentage;  // Fee percentage (basis points)
    address feeAddress;             // Fee recipient address
}
```

### DiscountConfig
```js
struct DiscountConfig {
    IERC20 token;          // Token eligible for discount
    uint96 deploymentCost; // Discounted deployment cost
    uint32 feePercentage;  // Discounted fee percentage
}
```

## State Variables

```js
DeploymentConfig public deploymentConfig;   // Base deployment settings
FeeConfig public feeConfig;                 // Fee configuration
DiscountConfig public discountConfig;       // Discount settings
bool private _tokenTransferAllowed;         // Transfer permission flag
mapping(address => bool) public approvedTokens; // Approved payment tokens
```

## Events

```js
event DeploymentConfigUpdated(uint96 cost, IERC20 token);
event FeeConfigUpdated(uint32 liquidityFeePercentage, address feeAddress);
event DiscountConfigSet(IERC20 token, uint96 deploymentCost, uint32 feePercentage);
event TokenApproved(IERC20 token);
event TokenRemoved(IERC20 token);
```

## Core Functions

### Constructor

```js
constructor(address admin)
```
Initializes the contract and grants admin roles to the specified address.

**Parameters:**
- `admin`: Address to receive DEFAULT_ADMIN_ROLE and MANAGER_ROLE

### Configuration Functions

#### setDeploymentConfig
```js
function setDeploymentConfig(uint96 cost, IERC20 token) external onlyRole(MANAGER_ROLE)
```
Sets the base deployment cost and payment token.

**Parameters:**
- `cost`: Base cost for deployment
- `token`: ERC20 token used for payment

**Access:** MANAGER_ROLE
**Emits:** DeploymentConfigUpdated

#### setFeeConfig
```js
function setFeeConfig(uint32 liquidityFeePercentage, address feeAddress) external onlyRole(MANAGER_ROLE)
```
Configures the fee structure.

**Parameters:**
- `liquidityFeePercentage`: Fee percentage in basis points (e.g., 500 = 5%)
- `feeAddress`: Address to receive fees

**Requirements:**
- feeAddress cannot be zero address

**Access:** MANAGER_ROLE
**Emits:** FeeConfigUpdated

#### setDiscountConfig
```js
function setDiscountConfig(IERC20 token, uint96 deploymentCost, uint32 feePercentage) external onlyRole(MANAGER_ROLE)
```
Sets up discount configuration for specific token holders.

**Parameters:**
- `token`: Token eligible for discount
- `deploymentCost`: Discounted deployment cost
- `feePercentage`: Discounted fee percentage

**Access:** MANAGER_ROLE
**Emits:** DiscountConfigSet

### Token Management Functions

#### approveToken
```js
function approveToken(IERC20 token) external onlyRole(MANAGER_ROLE)
```
Adds a token to the approved payment tokens list.

**Access:** MANAGER_ROLE
**Emits:** TokenApproved

#### disapproveToken
```js
function disapproveToken(IERC20 token) external onlyRole(MANAGER_ROLE)
```
Removes a token from the approved payment tokens list.

**Access:** MANAGER_ROLE
**Emits:** TokenRemoved

### System Control Functions

#### pause/unpause
```js
function pause() public onlyRole(DEFAULT_ADMIN_ROLE)
function unpause() public onlyRole(DEFAULT_ADMIN_ROLE)
```
Emergency controls to pause/unpause contract functionality.

**Access:** DEFAULT_ADMIN_ROLE

## View Functions

```js
function tokenTransferAllowed() external view returns (bool)
function isPaused() external view returns (bool)
```

## Security Considerations

1. **Access Control**
   - All sensitive functions are role-protected
   - Proper role hierarchy must be maintained
   - Admin transitions should be carefully managed

2. **Token Safety**
   - Validate token addresses before approval
   - Ensure token contracts are legitimate
   - Check for zero addresses in configurations

3. **Fee Management**
   - Validate fee percentages are within reasonable ranges
   - Ensure fee recipient address is valid
   - Monitor fee collection and distribution

## Error Cases

- Invalid fee address (zero address)
- Unauthorized access attempts
- Invalid token addresses
- System paused state restrictions

## Gas Optimization

- Uses uint96 for costs to pack structs efficiently
- Uses uint32 for fee percentages
- Efficient storage layout in structs
- Minimal storage operations

## Testing Recommendations

1. **Role Testing**
   - Verify role assignments
   - Test role restrictions
   - Validate role transfers

2. **Configuration Testing**
   - Test all configuration updates
   - Verify event emissions
   - Check edge cases

3. **Token Management**
   - Test token approval/disapproval
   - Verify approved tokens list
   - Test invalid token scenarios

4. **System Control**
   - Test pause/unpause functionality
   - Verify restricted access during pause
   - Test emergency scenarios