// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ProductManager.sol";
import "./IProductManager.sol";

/**
* @title Product
* @dev This contract represents a Product that users can deploy and subscribe to.
*/
contract Product is ERC1155, ERC1155URIStorage, ReentrancyGuard, AccessControl {
   using SafeERC20 for IERC20;

   /**
    * @dev Struct to hold the price configuration for a Product.
    * @param token The ERC20 token used for payment.
    * @param price The price of the Product in the specified token.
    */
   struct Price {
       IERC20 token;
       uint96 price;
   }

   bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

   IProductManager public config;
   bool public transfersAllowed;

   string public productURI;
   string public name;
   string public symbol;

   uint256 public ProductCounter;



   mapping(address => uint256) public creatorToToken;
   mapping(uint256 => address) public tokenToCreator;
   mapping(uint256 => mapping(IERC20 => uint)) public price;
   mapping(uint256 => string) public tokenToHash;
   mapping(string => uint256) public hashToToken;
   mapping(uint256 => IERC20[]) public tokensForProduct;

   event DeployProduct(address indexed creator, string hash, uint256 tokenId);
   event UpdatePrice(address indexed creator, uint256 tokenId, IERC20 indexed token, uint256 newPrice);
   event Subscribe(address indexed subscriber, uint256 indexed tokenID);

   /**
    * @dev Initializes the Product contract with the ProductManager contract address and Product URI.
    * @param _ProductManager The address of the ProductManager contract.
    * @param _ProductUri The Metadata for this unique product.
    */
   constructor(address _ProductManager, string memory _ProductUri, string memory _name, string memory _symbol) ERC1155(_ProductUri) {
       config = IProductManager(_ProductManager);
       ProductCounter = 1;
       productURI = _ProductUri;
       name = _name;
       symbol = _symbol;
   }

    modifier onlyCreator(uint256 tokenId) {
        require(tokenToCreator[tokenId] == msg.sender, "Not the token creator");
        _;
    }

    modifier onlyApprovedToken(IERC20 token) {
    require(config.approvedTokens(address(token)), "Token not approved");
    _;
}

    /**
     * @notice Ensures the contract is not paused in the ProductManager.
     * @dev Checks the `isPaused` function in the ProductManager contract.
     */
    modifier whenNotPaused() {
        require(!config.isPaused(), "Product actions are currently paused");
        _;
    }

/**
 * @notice Deploys a new Product by creating a new token and assigning it a unique hash and URI.
 * @dev This function creates a new ERC1155 token, sets its pricing, and assigns a URI for its metadata.
 * The caller must pay the deployment cost set in the deploymentConfig.
 * @param ProductHash Unique identifier for the Product.
 * @param prices Array of Price structs defining the pricing for the token.
 * @return tokenId The ID of the newly created token.
 */
function deployProduct(
    string memory ProductHash,
    Price[] calldata prices
) external nonReentrant whenNotPaused returns (uint256) {
    require(config.deploymentConfig().cost > 0, "Deployment cost not set");

    uint256 costToDeduct = config.deploymentConfig().cost;
    IERC20 tokenToUse = config.deploymentConfig().token;

    // Check if the discount token is in the prices[] array and meets the balance requirement
    bool discountEligible = false;
    IERC20 discountToken = config.discountConfig().token;

    for (uint256 i = 0; i < prices.length; i++) {
        if (address(prices[i].token) == address(discountToken)) {
            // Check that user holds enough of the discount token to qualify for the discount
            if (discountToken.balanceOf(msg.sender) >= config.discountConfig().deploymentCost) {
                discountEligible = true;
            }
            break;
        }
    }

    // Apply discounted cost if discount eligibility is confirmed
    if (discountEligible) {
        costToDeduct = config.discountConfig().deploymentCost;
    }

    // Transfer the required deployment cost
    tokenToUse.safeTransferFrom(msg.sender, config.feeConfig().feeAddress, costToDeduct);

    uint256 tokenId = ProductCounter++;
    tokenToHash[tokenId] = ProductHash;
    hashToToken[ProductHash] = tokenId;

    // Set prices and add tokens to list for the new Product
    for (uint256 i = 0; i < prices.length; i++) {
        require(config.approvedTokens(address(prices[i].token)), "One or more tokens are not approved");

        price[tokenId][prices[i].token] = prices[i].price;

        if (!isTokenInList(tokenId, prices[i].token)) {
            tokensForProduct[tokenId].push(prices[i].token);
        }
    }

    creatorToToken[msg.sender] = tokenId;
    tokenToCreator[tokenId] = msg.sender;

    emit DeployProduct(msg.sender, ProductHash, tokenId);

    return tokenId;
}


/**
 * @notice Allows the creator to update the pricing for their token.
 * @param tokenId The ID of the token for which the pricing is being updated.
 * @param newPrices Array of Price structs defining the new pricing for the token.
 */
function updatePrice(
    uint256 tokenId,
    Price[] calldata newPrices
) external nonReentrant whenNotPaused onlyCreator(tokenId) {
    // Clear existing prices and token list for the tokenId
    delete tokensForProduct[tokenId];
    
    for (uint256 i = 0; i < newPrices.length; i++) {
        require(config.approvedTokens(address(newPrices[i].token)), "One or more tokens are not approved");

        // Update the price mapping and add the token to tokensForProduct list
        price[tokenId][newPrices[i].token] = newPrices[i].price;
        tokensForProduct[tokenId].push(newPrices[i].token);

        emit UpdatePrice(msg.sender, tokenId, newPrices[i].token, newPrices[i].price);
    }
}


    /**
     * @notice Retrieves the pricing information for a given token ID.
     * @param tokenId The ID of the token for which pricing information is requested.
     * @return An array of Price structs, each containing an ERC20 token and its associated price.
     */
    function getTokenPrices(uint256 tokenId) external view returns (Price[] memory) {
        IERC20[] memory tokens = tokensForProduct[tokenId];
        Price[] memory pricesArray = new Price[](tokens.length);

for (uint256 i = 0; i < tokens.length; i++) {
    IERC20 token = tokens[i];
    uint96 tokenPrice_96 = uint96(price[tokenId][token]);
    pricesArray[i] = Price(token, tokenPrice_96);
}

        return pricesArray;
    }

    /**
     * @notice Mints a token for the sender by paying with an ERC20 token.
     * @param paymentToken The ERC20 token used for payment.
     * @param tokenID The ID of the token to be purchased.
     */
function subscribe(IERC20 paymentToken, uint256 tokenID) external nonReentrant whenNotPaused {
    require(isTokenInList(tokenID, paymentToken), "Payment token not valid for this product");

    uint256 subscriptionPrice = price[tokenID][paymentToken];
    require(config.approvedTokens(address(paymentToken)), "Payment token not approved");

    if (subscriptionPrice > 0) {
        uint256 feePercentageToUse = config.feeConfig().liquidityFeePercentage;

        // Check if the user is using the discount token
        if (address(config.discountConfig().token) != address(0) && address(paymentToken) == address(config.discountConfig().token)) {
            feePercentageToUse = config.discountConfig().feePercentage;
        }

        // Calculate the fee amount
        uint256 feeAmount = (subscriptionPrice * feePercentageToUse) / 100;

        // Transfer fee and remainder
        paymentToken.safeTransferFrom(msg.sender, config.feeConfig().feeAddress, feeAmount);
        paymentToken.safeTransferFrom(msg.sender, tokenToCreator[tokenID], subscriptionPrice - feeAmount);
    }

    // Mint the ERC1155 token
    _mint(msg.sender, tokenID, 1, "");
    
    // Emit event
    emit Subscribe(msg.sender, tokenID);
}

    /**
     * @notice Gets the hash (identifier) for a given token ID.
     * @param tokenId The ID of the token.
     * @return The hash associated with the given token ID.
     */
    function getHashByTokenId(uint256 tokenId) external view returns (string memory) {
        return tokenToHash[tokenId];
    }

    /**
     * @notice Gets the tokenId for a given hash (identifier)
     * @param hash the hash of the token
     * @return The tokenId associated with the given hash.
     */
    function getTokenIdByHash(string memory hash) external view returns (uint256) {
        return hashToToken[hash];
    }

       /**
    * @dev Sets the product URI.
    * @param newURI The new URI to set.
    */
   function setProductURI(string memory newURI) external onlyRole(MANAGER_ROLE) {
       productURI = newURI;
   }

    /**
     * @dev Override the uri function to return the collection-level URI.
     * @return The URI for the collection metadata.
     */
    function uri(uint256 /*tokenId*/) public view virtual override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return productURI;
    }

    /**
     * @notice Overrides supportsInterface to include AccessControl support.
     * @param interfaceId The interface identifier.
     * @return True if the contract supports the given interface identifier, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /**
     * @notice Checks if an ERC20 token is already in the list of tokens for a specific Product ID.
     * @param tokenId The ID of the Product.
     * @param token The ERC20 token to check.
     * @return True if the token is in the list, false otherwise.
     */
    function isTokenInList(uint256 tokenId, IERC20 token) internal view returns (bool) {
        IERC20[] memory tokens = tokensForProduct[tokenId];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Overrides the safeTransferFrom function to include transfer restriction
     * @dev This function will revert if transfers are not allowed
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param id Token ID to transfer
     * @param amount Amount of tokens to transfer
     * @param data Additional data with no specified format
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(config.tokenTransferAllowed(), "Transfers are currently not allowed");
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice Overrides the safeBatchTransferFrom function to include transfer restriction
     * @dev This function will revert if transfers are not allowed
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param ids Array of token IDs to transfer
     * @param amounts Array of amounts of tokens to transfer
     * @param data Additional data with no specified format
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(config.tokenTransferAllowed(), "Transfers are currently not allowed");
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }


    /**
 * @notice Updates the ProductManager address for configuration settings.
 * @dev This function allows the admin to change the ProductManager address, in case it needs to be updated.
 * @param newConfigAddress The address of the new ProductManager contract.
 */
function setConfigAddress(address newConfigAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(newConfigAddress != address(0), "New config address is zero");
    config = IProductManager(newConfigAddress);
}
}
