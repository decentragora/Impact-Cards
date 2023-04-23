    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

/// @title ImpactCards_Gen1
/// @author DecentrAgora
/// @notice This contract is for the first generation of the Impact Cards project, a collectible NFT project with a purpose.
/// @dev The contract inherits from OpenZeppelin's ERC1155, Ownable, and ReentrancyGuard contracts.
contract ImpactCards_Gen1 is ERC1155, Ownable, ReentrancyGuard {
    /// @notice Indicates if the contract is currently paused.
    bool public isPaused;
    /// @notice The name of the NFT collection.
    string public name = "Impact Cards";
    /// @notice The symbol of the NFT collection.
    string public symbol = "IMPACT";
    /// @notice The base URI for the metadata of the NFTs.
    string public _uri = "https://impactcards.io/api/cards/";
    /// @notice The file extension for the metadata of the NFTs.
    string public _baseExtension = ".json";
    /// @notice The maximum number of tokens that can be bought in a single transaction.
    uint16 public bulkBuyLimit = 5;
    /// @notice The maximum number of unique cards in the collection.
    uint256 public constant MAX_CARDS = 60;
    /// @notice The maximum supply of each card in the collection.
    uint256 public constant MAX_SUPPLY = 2023;
    /// @notice The price to mint a single card, denominated in gwei (1 ETH = 10**9 gwei).
    uint256 public mintPrice = 5 * 10 ** 15; // 0.005 ETH
    /// @notice The current season of the collection, which determines which cards are mintable.
    uint256 public currentSeason = 1;

    /// @dev Mapping to keep track of the total number of cards minted for each token ID.
    mapping(uint256 => uint256) private _totalMinted;
    /// @dev Mapping to store the two payees for each token ID.
    mapping(uint256 => address[2]) private _payee;
    /// @dev Mapping to store the share percentages for each payee of each token ID.
    mapping(uint256 => uint256[2]) private _shares;
    /// @dev Mapping to store the total accumulated funds released to each address.
    mapping(address => uint256) private _totalReceived;
    /// @dev Mapping to store the accumulated funds for each payee of each token ID.
    mapping(uint256 => uint256[2]) private _accumulatedFunds;

    /// @dev An array containing the number of cards in each season.
    uint8[] public seasonCardCounts = [15, 14, 14, 13];
    /// @dev An array containing the token IDs of the hidden cards.
    uint8[] public hiddenCardIds = [57, 58, 59, 60];

    /// @notice Emitted when a card is minted.
    event CardMinted(uint256 tokenId, uint256 amount, address minter);
    /// @notice Emitted when multiple cards are minted.
    event CardsBatchMinted(uint256[] tokenIds, uint256[] amounts, address minter);
    /// @notice Emitted when the season is changed.
    event SeasonChanged(uint256 season);
    /// @notice Emitted when the payees for a token ID are set.
    event PayeeSet(uint256 tokenId, address[2] payees);
    /// @notice Emitted when the share percentages for a token ID are set.
    event SharesSet(uint256 tokenId, uint256[2] shares);
    /// @notice Emitted when funds are released to a payee.
    event FundsReleased(uint256 tokenId, address payee, uint256 amount);
    /// @notice Emitted when the bulk buy limit is changed.
    event BulkBuyLimitSet(uint16 limit);
    /// @notice Emitted when the mint price is changed.
    event MintPriceSet(uint256 price);
    /// @notice Emitted when the base URI is changed.
    event BaseURIChanged(string baseURI);
    /// @notice Emitted when the base extension is changed.
    event BaseExtensionChanged(string baseExtension);
    /// @notice Emitted when the contract is paused or unpaused.
    event ChangedContractPausedState(bool isPaused);

    /// @notice Initializes the contract with the base URI for token metadata.
    /// @dev The constructor also sets the contract state to paused.
    constructor() ERC1155("https://impactcards.io/api/cards/{id}.json") {
        isPaused = true;
    }

    /// @dev Modifier that requires the contract to not be paused.
    modifier isNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    /// @dev Modifier that requires the given amount to be within the bulk buy limit.
    modifier withinLimit(uint256 amount) {
        require(amount <= bulkBuyLimit, "Exceeds bulk buy limit");
        _;
    }

    /// @dev Modifier that requires the sender to be one of the specified payees for the given tokenId and payeeIndex.
    modifier onlyPayee(uint256 tokenId, uint8 payeeIndex) {
        require(payeeIndex == 0 || payeeIndex == 1, "Invalid payee index");
        require(msg.sender == _payee[tokenId][payeeIndex], "Not authorized");
        _;
    }

    /// @notice Mints a single card for the caller.
    /// @dev The function ensures that the total supply of the card does not exceed the maximum supply.
    /// @param tokenId The ID of the card to be minted.
    function mint(uint256 tokenId, uint256 amount) public payable nonReentrant isNotPaused withinLimit(amount) {
        require(tokenId >= 1 && tokenId <= 56, "Invalid tokenId");
        require(_isMintable(tokenId), "Token not mintable in the current season");
        require(amount > 0 && amount <= MAX_SUPPLY - _totalMinted[tokenId], "Exceeds max supply");

        uint256 totalPrice = mintPrice * amount;
        require(msg.value >= totalPrice, "Insufficient payment");
        uint256 shareOfPay = msg.value / 2;
        _accumulatedFunds[tokenId][0] += shareOfPay;
        _accumulatedFunds[tokenId][1] += shareOfPay;

        _totalMinted[tokenId] += amount;
        _mint(msg.sender, tokenId, amount, "");

        emit CardMinted(tokenId, amount, msg.sender);
    }

    /// @notice Mints multiple cards for the caller.
    /// @param tokenId A array containing the IDs of the cards to be minted.
    /// @param amount A array containing the amounts of each card to be minted.
    /// @dev The function ensures that the bulk buy limit, max supply, and mintable conditions are met.
    /// @dev The function also ensures that the total price is paid and that the funds are distributed correctly.
    function mintBatch(uint256[] calldata tokenId, uint256[] calldata amount) public payable nonReentrant isNotPaused {
        require(tokenId.length == amount.length, "Invalid input");
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < tokenId.length; i++) {
            require(tokenId[i] >= 1 && tokenId[i] <= 56, "Invalid tokenId");
            require(_isMintable(tokenId[i]), "Token not mintable in the current season");
            require(amount[i] > 0 && amount[i] <= MAX_SUPPLY - _totalMinted[tokenId[i]], "Invalid amount");
            require(amount[i] <= bulkBuyLimit, "Exceeds bulk buy limit");
            _totalMinted[tokenId[i]] += amount[i];
            uint256 idPrice = mintPrice * amount[i];
            totalPrice += idPrice;
            uint256 shareOfPay = idPrice / 2;
            _accumulatedFunds[tokenId[i]][0] += shareOfPay;
            _accumulatedFunds[tokenId[i]][1] += shareOfPay;
        }

        require(msg.value >= totalPrice, "Insufficient payment");
        _mintBatch(msg.sender, tokenId, amount, "");
        emit CardsBatchMinted(tokenId, amount, msg.sender);
    }

    // function mintHiddenCard(uint256 tokenId, uint256 amount, bytes calldata proof)
    //     public
    //     payable
    //     nonReentrant
    //     isNotPaused
    //     withinLimit(amount)
    // {
    //     require(tokenId >= 57 && tokenId <= MAX_CARDS, "Invalid tokenId");
    //     require(_isMintable(tokenId), "Token not mintable in the current season");
    //     require(amount > 0 && amount <= MAX_SUPPLY - _totalMinted[tokenId], "Invalid amount");

    //     uint256 totalPrice = mintPrice * amount;
    //     require(msg.value >= totalPrice, "Insufficient payment");
    //     uint256 shareOfPay = msg.value / 2;
    //     _accumulatedFunds[tokenId][0] += shareOfPay;
    //     _accumulatedFunds[tokenId][1] += shareOfPay;

    //     _totalMinted[tokenId] += amount;
    //     _mint(msg.sender, tokenId, amount, proof);

    //     emit CardMinted(tokenId, amount, msg.sender);
    // }

    /// @notice Allows the owner to set a tokenId's payees.
    /// @param tokenId The ID of the card to be updated.
    /// @param payees An array containing the addresses of the payees.
    /// @param shares An array containing the shares of each payee.
    function setPayees(uint256 tokenId, address[2] memory payees, uint256[2] memory shares) public onlyOwner {
        require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
        require(shares[0] + shares[1] == 100, "Shares should add up to 100%");
        require(payees[0] != address(0) && payees[1] != address(0), "Payees cannot be zero address");
        require(payees[0] != payees[1], "Payees cannot be the same");
        require(payees.length == 2 && shares.length == 2, "Invalid payees or shares");
        _payee[tokenId] = payees;
        _shares[tokenId] = shares;
        emit PayeeSet(tokenId, [payees[0], payees[1]]);
        emit SharesSet(tokenId, [shares[0], shares[1]]);
    }

    /// @notice Allows the Payee to withdraw their accumulated funds.
    /// @param tokenId The ID of the card to be updated.
    /// @param payeeIndex The index of the payee to be updated. either 0 or 1.
    /// @dev The function ensures that the tokenId, and payeeIndex are valid, as well as ensuring that the caller is the payee, and has accumulated funds to withdraw.
    /// @dev Only allows payee to withdraw accumulated funds.
    function release(uint256 tokenId, uint8 payeeIndex)
        external
        nonReentrant
        isNotPaused
        onlyPayee(tokenId, payeeIndex)
    {
        require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
        address payee = _payee[tokenId][payeeIndex];
        uint256 amount = _accumulatedFunds[tokenId][payeeIndex];
        require(amount > 0, "No funds to release");

        _accumulatedFunds[tokenId][payeeIndex] = 0;
        _totalReceived[payee] += amount;
        payable(payee).transfer(amount);
        emit FundsReleased(tokenId, payee, amount);
    }

    /// @notice Allows the owner to advanced the season ahead one.
    function nextSeason() external onlyOwner {
        require(currentSeason < 4, "All seasons have been activated");
        currentSeason++;
        emit SeasonChanged(currentSeason);
    }

    /// @notice Allows the owner to set the mint price.
    /// @param price The new mint price.
    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
        emit MintPriceSet(price);
    }

    /// @notice Allows the owner to set the bulk buy limit.
    /// @param limit The new bulk buy limit.
    function setBulkBuyLimit(uint16 limit) external onlyOwner {
        require(limit > 0, "Limit cannot be zero");
        require(limit <= 100, "Limit cannot be more than 100");
        bulkBuyLimit = limit;
        emit BulkBuyLimitSet(limit);
    }

    /// @notice Allows the owner to set the base URI.
    /// @param newuri The new base URI.
    function setBaseURI(string calldata newuri) external onlyOwner {
        _uri = newuri;
        emit BaseURIChanged(newuri);
    }

    /// @notice Allows the owner to set the base extension.
    /// @param newExtension The new base extension.
    function setBaseExtension(string calldata newExtension) external onlyOwner {
        _baseExtension = newExtension;
        emit BaseExtensionChanged(newExtension);
    }

    /// @notice Allows the owner to toggle the paused state of the contract.
    /// @dev if contracts is paused transfers will be disabled.
    function togglePaused() external onlyOwner {
        isPaused = !isPaused;
        emit ChangedContractPausedState(isPaused);
    }

    /// @notice Gets the payees addresses for a given tokenId.
    /// @param tokenId The ID of the card to fetch.
    /// @return An array containing the addresses of the payees.
    function getPayees(uint256 tokenId) external view returns (address[2] memory) {
        require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
        return _payee[tokenId];
    }

    /// @notice Gets the shares for a given tokenId.
    /// @param tokenId The ID of the card to fetch.
    /// @return An array containing the shares of each payee.
    function getShares(uint256 tokenId) external view returns (uint256[2] memory) {
        require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
        return _shares[tokenId];
    }

    /// @notice Gets the accumulated funds for a given tokenId.
    /// @param tokenId The ID of the card to fetch.
    /// @return An array containing the accumulated funds for each payee for the given tokenId.
    function getAccumulatedFunds(uint256 tokenId) external view returns (uint256[2] memory) {
        require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
        return _accumulatedFunds[tokenId];
    }

    /// @notice Gets the total funds released to a given payee.
    /// @param payee The address of the payee to fetch total funds released.
    /// @return The total funds released to the given payee.
    function totalReleasedToPayee(address payee) external view returns (uint256) {
        require(payee != address(0), "Invalid address");
        return _totalReceived[payee];
    }

    /// @notice Gets the total supply of a given tokenId.
    /// @param tokenId The ID of the card to fetch.
    function totalSupply(uint256 tokenId) external view returns (uint256) {
        require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
        return _totalMinted[tokenId];
    }

    /// @notice Checks if a tokenId is currently mintable
    /// @param tokenId The ID of the card to check.
    /// @return A boolean indicating if the card is mintable.
    function isMintable(uint256 tokenId) external view returns (bool) {
        return _isMintable(tokenId);
    }

    /// @notice Gets a tokenIds URI.
    /// @param tokenId The ID of the card to fetch.
    /// @return A string containing the URI of the given tokenId.
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
        return string(abi.encodePacked(_uri, Strings.toString(tokenId), _baseExtension));
    }

    /// @notice internal function to check if a tokenId is mintable
    /// @param tokenId The ID of the card to check.
    /// @dev This function is used by the public isMintable, mint, mintBatch functions.
    /// @return A boolean indicating if the card is mintable.
    function _isMintable(uint256 tokenId) internal view returns (bool) {
        if (currentSeason == 1 && tokenId <= seasonCardCounts[0]) {
            return true;
        } else if (currentSeason == 2 && tokenId <= seasonCardCounts[0] + seasonCardCounts[1]) {
            return true;
        } else if (currentSeason == 3 && tokenId <= seasonCardCounts[0] + seasonCardCounts[1] + seasonCardCounts[2]) {
            return true;
        } else if (currentSeason == 4 && tokenId <= MAX_CARDS - hiddenCardIds.length) {
            return true;
        } else {
            for (uint8 i = 0; i < hiddenCardIds.length; i++) {
                if (tokenId == hiddenCardIds[i]) {
                    return true;
                }
            }
        }
        return false;
    }

    /// @notice internal function that runs before a token transfer.
    /// @param operator The address of the operator.
    /// @param from The address of the sender.
    /// @param to The address of the receiver.
    /// @param ids The ID of the card to transfer.
    /// @param amounts The amount of the card to transfer.
    /// @param data Any additional data to send with the transfer.
    /// @dev This function is used by the public safeTransferFrom, safeBatchTransferFrom, transferFrom functions.
    /// @dev This function will revert if the contract is paused.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) isNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
