# Product Contract Documentation

## Overview

The `Product` contract is an implementation of an ERC1155 token representing products that users can deploy and subscribe to. This contract includes features for product deployment, pricing configuration, token subscription, and ERC20-based payment processing. Additionally, it supports discounts and includes access control, safety mechanisms, and pausing functionality through a linked `ProductManager` contract.

## Contract Details

- **License**: MIT
- **js Version**: ^0.8.24
- **Contract Type**: Implementation
- **Inheritances**:
  - `ERC1155`
  - `ERC1155URIStorage`
  - `ReentrancyGuard`
  - `AccessControl`

## Import Statements

```js
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ProductManager.sol";
import "./IProductManager.sol";
```

## Access Control Roles

```js
bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
DEFAULT_ADMIN_ROLE // Inherited from AccessControl
```

- **MANAGER_ROLE**: Allows management of specific product configuration.
- **DEFAULT_ADMIN_ROLE**: Grants full administrative privileges and control over access control mechanisms.

## Data Structures

### Price
```js
struct Price {
    IERC20 token;
    uint96 price;
}
```
Defines the pricing configuration for each product, specifying the ERC20 token and price per product.

## State Variables

```js
IProductManager public config;                    // Address of the ProductManager contract for configurations
bool public transfersAllowed;                     // Flag to allow or prevent transfers
string public productURI;                         // Metadata URI for the product collection
uint256 public ProductCounter;                    // Counter for unique token IDs

mapping(address => uint256) public creatorToToken; // Maps creators to their token IDs
mapping(uint256 => address) public tokenToCreator; // Maps token IDs to their creators
mapping(uint256 => mapping(IERC20 => uint)) public price; // Mapping of token prices per product
mapping(uint256 => string) public tokenToHash;     // Maps token IDs to their unique hashes
mapping(string => uint256) public hashToToken;     // Maps unique hashes to token IDs
mapping(uint256 => IERC20[]) public tokensForProduct; // List of approved tokens for each product
```

## Events

```js
event DeployProduct(address indexed creator, string hash, uint256 tokenId);
event UpdatePrice(address indexed creator, uint256 tokenId, IERC20 indexed token, uint256 newPrice);
event Subscribe(address indexed subscriber, uint256 indexed tokenID);
```

## Core Functions

### Constructor

```js
constructor(address _ProductManager, string memory _ProductUri, string memory _name, string memory _symbol)
```

Initializes the `Product` contract and connects it to the specified `ProductManager` contract, setting the initial product URI, name, symbol and counter.

**Parameters:**
- `_ProductManager`: Address of the `ProductManager` contract that manages the product configuration.
- `_ProductUri`: The unique product metadata URI.
- `_name`: The unique NFT collection name for the deployed product.
- `_symbol`: The unique NFT collection symbol for the deployed product.

### Product Deployment and Subscription

#### `deployProduct`

```js
function deployProduct(string memory ProductHash, Price[] calldata prices) external returns (uint256)
```

Deploys a new product by creating a new token, assigning a unique hash and URI, and configuring the pricing for the token.

**Parameters:**
- `ProductHash`: Unique identifier for the product.
- `prices`: Array of `Price` structs specifying token and pricing details.

**Returns:** `tokenId`: The unique ID of the newly created token.

**Requirements:**
- Deployment cost should be set in the `ProductManager`.
- ERC20 tokens used must be approved.

**Emits:** `DeployProduct`

#### `updatePrice`

```js
function updatePrice(uint256 tokenId, Price[] calldata newPrices) external
```

Allows a creator to update the pricing for an existing product token.

**Parameters:**
- `tokenId`: ID of the token being updated.
- `newPrices`: Array of `Price` structs defining the new pricing details.

**Emits:** `UpdatePrice`

### Token Purchase

#### `subscribe`

```js
function subscribe(IERC20 paymentToken, uint256 tokenID) external
```

Allows users to subscribe (purchase) a product by paying with a specified ERC20 token.

**Parameters:**
- `paymentToken`: ERC20 token used for payment.
- `tokenID`: ID of the product token to be purchased.

**Requirements:**
- Payment token must be approved.
- Token ID must be valid and available for subscription.

**Emits:** `Subscribe`

### View Functions

#### `getTokenPrices`

```js
function getTokenPrices(uint256 tokenId) external view returns (Price[] memory)
```

Returns the pricing information for a given token ID.

**Parameters:**
- `tokenId`: ID of the token whose pricing information is requested.

**Returns:** Array of `Price` structs with ERC20 token and price details.

#### `getHashByTokenId`

```js
function getHashByTokenId(uint256 tokenId) external view returns (string memory)
```

Returns the hash associated with a given token ID.

**Parameters:**
- `tokenId`: The ID of the token.

**Returns:** The unique hash as a string.

#### `getTokenIdByHash`

```js
function getTokenIdByHash(string memory hash) external view returns (uint256)
```

Returns the token ID associated with a given hash.

**Parameters:**
- `hash`: Unique identifier hash of the product.

**Returns:** Token ID as an unsigned integer.

### System Control Functions

#### `setConfigAddress`

```js
function setConfigAddress(address newConfigAddress) external
```

Updates the ProductManager address for configuration settings.

**Parameters:**
- `newConfigAddress`: Address of the new `ProductManager` contract.

**Requirements:**
- Only accessible by users with the `DEFAULT_ADMIN_ROLE`.

### Token Transfer Overrides

The following functions include transfer restrictions based on the `ProductManager` configuration:

- `safeTransferFrom`
- `safeBatchTransferFrom`

Transfers are only allowed if `tokenTransferAllowed` is set to true in the `ProductManager`.

## Security Considerations

1. **Access Control**
   - Functions are restricted to roles as needed.
   - Only creators can modify their products.

2. **Discount and Deployment Costs**
   - Discount eligibility checks are implemented.
   - Deployment and discount costs are enforced through secure ERC20 transfers.

3. **Reentrancy Protection**
   - `nonReentrant` modifier is used on functions with external calls.

4. **Token Safety**
   - Approved tokens are validated through `ProductManager`.
   - `safeTransferFrom` methods are used for all ERC20 transfers.

## Error Cases

- **Unauthorized Access**: Role-protected functions are restricted.
- **Invalid Token Approval**: Unapproved tokens cannot be used.
- **Paused State Restrictions**: Actions are restricted when the `ProductManager` is paused.

## Testing Recommendations

1. **Role-Based Access**
   - Validate proper role assignments and restrictions.
   - Test with unapproved tokens and invalid roles.

2. **Deployment and Subscription Testing**
   - Test product deployment with approved and unapproved tokens.
   - Validate subscription payments and event emissions.

3. **Discount Eligibility Testing**
   - Verify discount application based on token balances.
   - Confirm deployment costs with and without discounts.

4. **Pause/Unpause Functionality**
   - Ensure all state variables and flags work as expected when paused.
