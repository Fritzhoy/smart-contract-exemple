// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*Interface mostra todas as funçoes do contrato, ao entar com o endereço do contrato consegue interagir com as
funçoes sem precisar importar o contrato. */

interface IBaseContract {
    function setURI(string memory newuri) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function uri(uint256) external view returns (string memory);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external; 
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    function name() external view returns(string memory);
    function setApprovalForAll(address operator, bool approved) external;
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function mintBatch(address to,uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    function OPERATOR() external view returns(bytes32);
}

contract StoreFunctions is Ownable, Pausable, ReentrancyGuard, PaymentSplitter{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter public itemsSold;
    Counters.Counter private _itemIds;
    using Strings for string;

    struct SellOffer {
        uint256 itemId;
        address seller;
        uint256 price;
        uint64 initialAmount;
        uint64 amount;
        uint256 createTime;
        uint256 IDtoken;
        bool sold;
    }
    struct SoldItem {
        uint256 itemSoldId;
        address seller;
        address buyer;
        uint256 blockId;
        uint256 price;
        uint64 initialAmount;
        uint64 amount;
        uint256 createTime;
        uint256 IDtoken;
    }

    mapping(uint256 => SellOffer) public activeSellOffers;
    mapping(uint256 => SoldItem) public soldOffers;
    mapping(uint256=>SellOffer) public tokensIDs;
    address public addressOf1155;
    uint256 public balanceNFTOffer;
    uint256 public totalNFTOffer;
    

    event ItemSold(uint256 tokenId, address indexed seller, uint256 value, uint64 amount, address indexed buyer, uint256 itemSoldId);
    event NewSellOffer(uint256 tokenId, address indexed seller, uint256 value, uint64 amount);
    event NewBatchSellOffer(uint256 tokenIdLength, address indexed seller, uint256 value, uint256 totalNFTOffer);
    event CancelSellOffer(uint256 tokenId, address indexed seller, uint256 value, uint64 amount);
    event MoneyReceived(address indexed _from, uint _amount);

    modifier tokenOwnerOnly(uint256 tokenId) {
        //require(IBaseContract(addressOf1155).balanceOf(tx.origin, tokenId) != 0, "You don't have any token");
        require(IBaseContract(addressOf1155).balanceOf(msg.sender, tokenId) != 0, "You don't have any token");
        _;
    }

    modifier check(uint256[] memory tokenId) {
        for (uint256 i = 0; i < tokenId.length; i++) {
            require(tokensIDs[tokenId[i]].IDtoken == 0, "Item is already for seller");
        }
        _;
    }

    constructor(address[] memory _payees, uint256[] memory _shares, address  _addr) PaymentSplitter(_payees, _shares) {
        addressOf1155 = _addr;

    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /*function makeSellOffer(uint256 tokenId, uint256 price, uint64 amount) external whenNotPaused nonReentrant tokenOwnerOnly(tokenId) {
        require(price > 0, "Price must be at least 1 wei");
        require(amount > 0, "You can't sell 0 tokens");

        uint256 itemId = _itemIds.current();
        _itemIds.increment();
        activeSellOffers[itemId] = SellOffer({itemId: itemId, seller : msg.sender, price : price, initialAmount: amount, amount: amount, createTime: block.timestamp, IDtoken: tokenId, sold: false});
        emit NewSellOffer(tokenId, msg.sender, price, amount);
    }*/

    function batchSellOffer(uint256[] memory tokenId, uint64[] memory amounts, uint256 price) external whenNotPaused nonReentrant check(tokenId) {    
        for ( uint256 i=0; i < tokenId.length; i++) {
            require(price > 0, "Price must be at least 1 wei");
            require(amounts[i] > 0, "You can't sell 0 tokens");
            require(IBaseContract(addressOf1155).balanceOf(msg.sender, tokenId[i]) >= amounts[i], "You don't have sufficient balance");
            uint256 itemId = _itemIds.current();
            activeSellOffers[itemId] = SellOffer({itemId: itemId, seller : msg.sender, price : price, initialAmount: amounts[i], amount: amounts[i], createTime: block.timestamp, IDtoken: tokenId[i], sold: false});
            tokensIDs[tokenId[i]] = activeSellOffers[itemId];
            _itemIds.increment();
        }
        totalNFTOffer += tokenId.length;
        balanceNFTOffer += tokenId.length; 
        emit NewBatchSellOffer(tokenId.length, msg.sender, price, totalNFTOffer);
    }

    function buyToken(uint64 amount) external payable whenNotPaused nonReentrant returns (SellOffer memory) {
        SellOffer storage offer = activeSellOffers[itemsSold.current()];
        require(msg.value >= offer.price, "1##You can't send less than the offer price!");
        require(amount > 0, "2##You can't buy 0 tokens!");
        require(offer.amount > 0, "3##This offer is no valid!");
        require(offer.amount >= amount, "4##You are trying to buy more than the offer amount!");
        require((amount * offer.price) <= msg.value, "5##You can pay less than the buy value!");
        require(offer.sold == false, "6##This offer already sold!");
        emit MoneyReceived(msg.sender, msg.value);
        uint256 itemSoldId = itemsSold.current();
        itemsSold.increment();
        balanceNFTOffer = totalNFTOffer - itemsSold.current();
        soldOffers[itemSoldId] = SoldItem({
            itemSoldId: itemSoldId,
            seller: offer.seller,
            buyer: msg.sender,
            blockId: block.number,
            price: offer.price,
            initialAmount: offer.initialAmount,
            amount: amount,
            createTime: block.timestamp,
            IDtoken: offer.IDtoken
        });
        emit ItemSold(offer.IDtoken, offer.seller, offer.price, amount, msg.sender, itemSoldId);
        uint64 rest = offer.amount - amount;
        activeSellOffers[itemSoldId] = SellOffer({
            itemId: offer.itemId,
            seller : offer.seller,
            price : offer.price,
            initialAmount: offer.initialAmount,
            amount: rest,
            createTime: offer.createTime,
            IDtoken: offer.IDtoken,
            sold: (rest == 0)
        });
        IBaseContract(addressOf1155).safeTransferFrom(offer.seller, address(msg.sender), offer.IDtoken, amount, "0x");
        return offer;
    }
    
    function fetchMarketItems(uint256 _pageNumber, uint256 _resultsPerPage) external view returns (SellOffer[] memory) {
        //First, it creates the items array
        uint256 itemCount = _itemIds.current();
        uint256 currentIndex = 0;

        SellOffer[] memory items = new SellOffer[](itemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = activeSellOffers[i].itemId;
            SellOffer storage currentItem = activeSellOffers[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        //return items;
        //Second, returns only the requested page with its items.
        uint256 _itemIndexToStart = _resultsPerPage * _pageNumber - _resultsPerPage;

        if(
            items.length == 0 ||
            _itemIndexToStart > items.length -1
        ){
            return new SellOffer[](0);
        }

        SellOffer[] memory _itemsInThePage = new SellOffer[](_resultsPerPage);

        uint256 _returnCounter = 0;

        for(
            _itemIndexToStart; 
            _itemIndexToStart < _resultsPerPage * _pageNumber;
            _itemIndexToStart++
        ){
            if(_itemIndexToStart <= items.length - 1){
                _itemsInThePage[_returnCounter] = items[_itemIndexToStart];
            } else {
                SellOffer memory offer;
                _itemsInThePage[_returnCounter] = offer ;
            }

            _returnCounter++;
        }

        return _itemsInThePage;
    }

    function withdrawRemainingFundsAfterRelease() public onlyOwner nonReentrant {
        //function to be called after both payees have released to themselves.
        payable(msg.sender).transfer(address(this).balance);
    }

    function balanceOf(address account, uint256 id) external view returns (uint256) {
        return IBaseContract(addressOf1155).balanceOf(account, id);
    }

    function uri() external view returns(string memory){
        return IBaseContract(addressOf1155).uri(0);
    }

    function balance() external view returns (uint256){
        return address(this).balance;
    }
}