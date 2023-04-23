        // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.19;

    import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
    import {ERC1155Burnable} from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
    import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
    import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
    import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";


    contract ImpactCards_Gen1 is ERC1155, Ownable, ReentrancyGuard, ERC1155Burnable {
        struct Card {
            string name;
            string description;
            uint256 season;
        }

        bool public isPaused;

        string public _uri = "https://impactcards.io/api/cards/";
        string public _baseExtension = ".json";
        uint16 public bulkBuyLimit = 5;
        uint256 public constant MAX_CARDS = 60;
        uint256 public constant MAX_SUPPLY = 2023;
        uint256 public mintPrice = 5 * 10 ** 15; // 0.005 ETH
        uint256 public currentSeason = 1;

        mapping(uint256 => uint256) private _totalMinted;
        mapping(uint256 => address[2]) private _payee;
        mapping(uint256 => uint256[2]) private _shares;
        mapping(address => uint256) private _totalReceived;
        mapping(uint256 => uint256[2]) private _accumulatedFunds;

        mapping(uint256 => Card) private _cards;

        uint8[] public seasonCardCounts = [15, 14, 14, 13];
        uint8[] public hiddenCardIds = [57, 58, 59, 60];

        event CardMinted(uint256 tokenId, uint256 amount, address minter);
        event CardsBatchMinted(uint256[] tokenIds, uint256[] amounts, address minter);

        constructor() ERC1155("https://impactcards.io/api/cards/{id}.json") {
            isPaused = true;
        }

        modifier isNotPaused() {
            require(!isPaused, "Contract is paused");
            _;
        }

        modifier withinLimit(uint256 amount) {
            require(amount <= bulkBuyLimit, "Exceeds bulk buy limit");
            _;
        }

        modifier onlyPayee(uint256 tokenId, uint8 payeeIndex) {
            require(payeeIndex == 0 || payeeIndex == 1, "Invalid payee index");
            require(msg.sender == _payee[tokenId][payeeIndex], "Not authorized");
            _;
        }

        function mint(uint256 tokenId, uint256 amount) external payable nonReentrant isNotPaused withinLimit(amount) {
            require(tokenId >= 1 && tokenId <= 56, "Invalid tokenId");
            require(_isMintable(tokenId), "Token not mintable in the current season");
            require(amount > 0 && amount <= MAX_SUPPLY - _totalMinted[tokenId], "Invalid amount");

            uint256 totalPrice = mintPrice * amount;
            require(msg.value >= totalPrice, "Insufficient payment");
            uint256 shareOfPay = msg.value / 2;
            _accumulatedFunds[tokenId][0] += shareOfPay;
            _accumulatedFunds[tokenId][1] += shareOfPay;

            _totalMinted[tokenId] += amount;
            _mint(msg.sender, tokenId, amount, "");

            emit CardMinted(tokenId, amount, msg.sender);
        }

        function mintBatch(uint256[] calldata tokenId, uint256[] calldata amount) external payable nonReentrant isNotPaused {
            require(tokenId.length == amount.length, "Invalid input");
            uint256 totalPrice = 0;
            for (uint256 i = 0; i < tokenId.length; i++) {
                require(tokenId[i] >= 1 && tokenId[i] <= MAX_CARDS, "Invalid tokenId");
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

        function mintHiddenCard(uint256 tokenId, uint256 amount, bytes calldata proof)
            public
            payable
            nonReentrant
            isNotPaused
            withinLimit(amount)
        {
            require(tokenId >= 57 && tokenId <= MAX_CARDS, "Invalid tokenId");
            require(_isMintable(tokenId), "Token not mintable in the current season");
            require(amount > 0 && amount <= MAX_SUPPLY - _totalMinted[tokenId], "Invalid amount");

            uint256 totalPrice = mintPrice * amount;
            require(msg.value >= totalPrice, "Insufficient payment");
            uint256 shareOfPay = msg.value / 2;
            _accumulatedFunds[tokenId][0] += shareOfPay;
            _accumulatedFunds[tokenId][1] += shareOfPay;

            _totalMinted[tokenId] += amount;
            _mint(msg.sender, tokenId, amount, proof);

            emit CardMinted(tokenId, amount, msg.sender);
        }

        function setCardProperties(uint256 tokenId, string calldata name, string calldata description, uint256 season)
            external
            onlyOwner
        {
            require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
            _cards[tokenId] = Card(name, description, season);
        }

        function getCardProperties(uint256 tokenId) external view returns (Card memory) {
            require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
            return _cards[tokenId];
        }

        function setPayees(uint256 tokenId, address[2] calldata payees, uint256[2] calldata shares) external onlyOwner {
            require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
            require(shares[0] + shares[1] == 100, "Shares should add up to 100%");
            require(payees[0] != address(0) && payees[1] != address(0), "Payees cannot be zero address");
            require(payees[0] != payees[1], "Payees cannot be the same");
            require(payees.length == 2 && shares.length == 2, "Invalid payees or shares");
            _payee[tokenId] = payees;
            _shares[tokenId] = shares;
        }

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
        }

        function nextSeason() external onlyOwner {
            require(currentSeason < 4, "All seasons have been activated");
            currentSeason++;
        }

        function setMintPrice(uint256 price) external onlyOwner {
            mintPrice = price;
        }

        function setBulkBuyLimit(uint16 limit) external onlyOwner {
            require(limit > 0, "Limit cannot be zero");
            require(limit <= 100, "Limit cannot be more than 100");
            bulkBuyLimit = limit;
        }

        function setBaseURI(string calldata newuri) external onlyOwner {
            _uri = newuri;
        }

        function setBaseExtension(string calldata newExtension) external onlyOwner {
            _baseExtension = newExtension;
        }

        function emergencyWithdraw() external onlyOwner {
            payable(msg.sender).transfer(address(this).balance);
        }

        function togglePaused() external onlyOwner {
            isPaused = !isPaused;
        }

        function getPayees(uint256 tokenId) external view returns (address[2] memory) {
            require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
            return _payee[tokenId];
        }

        function getShares(uint256 tokenId) external view returns (uint256[2] memory) {
            require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
            return _shares[tokenId];
        }

        function getAccumulatedFunds(uint256 tokenId) external view returns (uint256[2] memory) {
            require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
            return _accumulatedFunds[tokenId];
        }

        function totalReleased(address payee) external view returns (uint256) {
            require(payee != address(0), "Invalid address");
            return _totalReceived[payee];
        }

        function totalReleasedToPayee(address payee) external view returns (uint256) {
            require(payee != address(0), "Invalid address");
            return _totalReceived[payee];
        }

        function totalSupply(uint256 tokenId) external view returns (uint256) {
            require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
            return _totalMinted[tokenId];
        }

        function isMintable(uint256 tokenId) external view returns (bool) {
            return _isMintable(tokenId);
        }

        function uri(uint256 tokenId)
            public
            view
            virtual
            override
            returns (string memory)
        {
            require(tokenId >= 1 && tokenId <= MAX_CARDS, "Invalid tokenId");
            return string(abi.encodePacked(_uri, Strings.toString(tokenId), _baseExtension));
        }

        function _isMintable(uint256 tokenId) private view returns (bool) {
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

        function _isMintableHidden(uint256 tokenId, bytes calldata proof) private view returns (bool) {
            for (uint8 i = 0; i < hiddenCardIds.length; i++) {
                if (tokenId == hiddenCardIds[i]) {
                    return true;
                }
            }
            return false;
        }

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
