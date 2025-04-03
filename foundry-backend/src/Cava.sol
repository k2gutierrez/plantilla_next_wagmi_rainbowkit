// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IPyth} from "pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "pyth-sdk-solidity/PythStructs.sol";

/**
 * @title A Tequila Cava managing contract
 * @author Carlos Gutiérrez / github: k2gutierrez / X: CarlosDappsDev.eth
 * @notice This contract is for managing tequila bottles in different processes
 * @dev Looking forward to implement pyth for price feeds / we might add automation oracle compatible for apechain
 */
contract Cava is ERC721URIStorage, ReentrancyGuard {
    error Cava__OnlyOwnerFunction();
    error Cava__NoNFTs();
    error Cava__NoNFTsOwned();
    error Cava__NotOwnerOfNft();
    error Cava__NotOwnerOfToken();
    error Cava__AlreadyRegisteredNFT(uint256 ContractToken);
    error Cava__NoTokensLeft();
    error Cava__NoExternalTokensLeft();
    error Cava__NotReposadoToken();
    error Cava__NotAnejoToken();
    error Cava__NoApeIsBeingTranferred();
    error Cava__InvalidTokenAmount(uint256 _amount);
    error Cava__NoTokensEntered();
    error Cava__ReposadoPriceNotSet();
    error Cava__AnejoPriceNotSet();
    error Cava__NotReposadoSaleToken();
    error Cava__NotAnejoSaleToken();
    error Cava__InsufficientBlancoFunds();
    error Cava__InsufficientReposadoFunds();
    error Cava__InsufficientAnejoFunds();
    error Cava__NotEnoughTokens(uint256 _tokensArrayLength);
    error Cava__NotReposadoBottleToken();
    error Cava__NotAnejoBottleToken();
    error Cava__NegativePrice();

    struct TequilaToken {
        uint256 contractBoundId; // if a token is purchased without a mingle it will remain as 0
        uint256 stage; // Have the stage as index of s_IpfsUri to know the Uri data
    }

    IPyth pyth;

    address private immutable i_owner; // Owner address
    address private immutable i_boundContract; // Bounded contract - in this case mingles
    uint256 private immutable i_maxContractSupply;

    string private constant NAME = "MinglesCavaNFT";
    string private constant SYMBOL = "TequilaNFT";
    string private constant BLANCO_BALANCE = "blancoBalance";
    string private constant REPOSADO_BALANCE = "reposadoBalance";
    string private constant ANEJO_BALANCE = "anejoBalance";
    uint256 private constant REPOSADO_TIME = 16 weeks;
    uint256 private constant ANEJO_TIME = 36 weeks;
    uint256 private constant PRICE_ADJUSTMENT = 1e18; // ceros for eth

    bytes32 public immutable i_price_feed_id;

    /**
     * @dev We have different options for the NFT to point to Uri depending on the stage we want the token to be.
     * @dev Index 0 = Tequila blanco
     * @dev Index 1 = Tequila reposado
     * @dev Index 2 = Tequila añejo
     * @dev Index 3 = Tequila reposado sale
     * @dev Index 4 = Tequila reposado bottle
     * @dev Index 5 = Tequila añejo sale
     * @dev Index 6 = Tequila añejo bottle
     */
    string[7] private s_IpfsUri = [
        // Metadata information for each stage of the NFT on IPFS.
        "https://ipfs.io/ipfs/QmYaTsyxTDnrG4toc8721w62rL4ZBKXQTGj9c9Rpdrntou/seed.json",
        "https://ipfs.io/ipfs/QmYaTsyxTDnrG4toc8721w62rL4ZBKXQTGj9c9Rpdrntou/purple-sprout.json",
        "https://ipfs.io/ipfs/QmYaTsyxTDnrG4toc8721w62rL4ZBKXQTGj9c9Rpdrntou/purple-blooms.json",
        "https://ipfs.io/ipfs/QmYaTsyxTDnrG4toc8721w62rL4ZBKXQTGj9c9Rpdrntou/purple-blooms.json",
        "https://ipfs.io/ipfs/QmYaTsyxTDnrG4toc8721w62rL4ZBKXQTGj9c9Rpdrntou/purple-blooms.json",
        "https://ipfs.io/ipfs/QmYaTsyxTDnrG4toc8721w62rL4ZBKXQTGj9c9Rpdrntou/purple-blooms.json",
        "https://ipfs.io/ipfs/QmYaTsyxTDnrG4toc8721w62rL4ZBKXQTGj9c9Rpdrntou/purple-blooms.json"
    ];

    uint256 private s_startingTimeStamp;
    uint256 private s_ExternalBottleSupply;
    uint256 private s_tokenIds;
    uint256 private s_ExternaltokenCounter; // For external sales
    uint256 private s_mintPrice;
    uint256[] private s_registeredMingles; // array to hold NFT_IDs registered to trade for Blanco Token
    uint256 s_tequilaStage;
    uint256 s_reposadoPrice;
    uint256 s_anejoPrice;
    mapping(uint256 => bool) private s_NFTexists; // Mapping to check if nfts has been claimed
    mapping(uint256 => TequilaToken) private s_tokenInfo; // Mapping from token id to an Info Struct

    uint256[] private s_reposadoIdSale;
    uint256[] private s_anejoIdSale;
    uint256[] private s_reposadoIdBottle;
    uint256[] private s_anejoIdBottle;

    mapping(string => uint256) private balance;

    event TokenTransferred(
        address from,
        address indexed to,
        uint256 indexed tokenId
    );
    event ReposadoMoneyTransferredToContract(uint256 amount);
    event AnejoMoneyTransferredToContract(uint256 amount);
    event ApeClaimedFromReposadoToken(address indexed holder, uint256 amount);
    event ApeClaimedFromAnejoToken(address indexed holder, uint256 amount);
    event BottleClaimedFromReposadoToken(address);
    event BottleClaimedFromAnejoToken(address);

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Cava__OnlyOwnerFunction();
        _;
    }

    constructor(
        address _contract,
        uint256 _supply,
        uint256 _externalSupply,
        uint256 _mintPrice,
        address pythContract,
        bytes32 _priceFeed
    ) ERC721(NAME, SYMBOL) {
        i_owner = msg.sender;
        i_boundContract = _contract;
        i_maxContractSupply = _supply;
        s_mintPrice = _mintPrice;
        s_startingTimeStamp = block.timestamp;
        s_ExternalBottleSupply = _externalSupply;
        i_price_feed_id = _priceFeed;

        pyth = IPyth(pythContract);
    }

    receive() external payable {
        transferReposadoMoneyToContract();
    }

    fallback() external payable {
        transferReposadoMoneyToContract();
    }

    // external
    function performTequilaStageChange() external onlyOwner nonReentrant {
        uint256 stage = s_tequilaStage;
        if (
            stage == 0 &&
            (block.timestamp - s_startingTimeStamp) >= REPOSADO_TIME
        ) {
            updateAllTokens();
            s_startingTimeStamp = block.timestamp;
            s_tequilaStage++;
        }

        if (
            stage == 1 && (block.timestamp - s_startingTimeStamp) >= ANEJO_TIME
        ) {
            updateAllTokens();
            s_tequilaStage++;
        }
    }

    function safeMintOwner(address to) external onlyOwner nonReentrant {
        uint256 externalTokenId = s_ExternaltokenCounter++;
        if (externalTokenId > s_ExternalBottleSupply)
            revert Cava__NoExternalTokensLeft();
        uint256 tokenId = s_tokenIds++;
        if (tokenId > (i_maxContractSupply + s_ExternalBottleSupply))
            revert Cava__NoTokensLeft();
        uint256 tequilaStage = s_tequilaStage;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, s_IpfsUri[tequilaStage]);
        emit TokenTransferred(address(this), to, tokenId);
        s_tokenInfo[tokenId].stage = tequilaStage;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        s_mintPrice = _mintPrice;
    }

    function setReposadoPrice(uint256 _price) external onlyOwner {
        s_reposadoPrice = _price;
    }

    function setAnejoPrice(uint256 _price) external onlyOwner {
        s_anejoPrice = _price;
    }

    function purchaseBlancoTokens(
        uint256 _amount
    ) external payable nonReentrant {
        if (_amount <= 0) revert Cava__InvalidTokenAmount(_amount);
        uint256 price = getEthUsdPrice();
        if (msg.value <= 0) revert Cava__InsufficientBlancoFunds();
        uint256 cost = ((price * PRICE_ADJUSTMENT) * msg.value) /
            PRICE_ADJUSTMENT;
        if (cost < s_mintPrice) revert Cava__InsufficientBlancoFunds();
        if (_amount == 1) {
            safeMint(msg.sender);
        } else {
            for (uint256 i; i < _amount; i++) {
                safeMint(msg.sender);
            }
        }
        balance[BLANCO_BALANCE] += msg.value;
    }

    /**
     * @dev Allows the owner to withdraw a specified amount of an ERC‑721 token from this contract.
     * @param NFTs The array of NFTs and user has
     */
    function blancoTransferToken(uint256[] memory NFTs) external nonReentrant {
        if (NFTs.length == 0) revert Cava__NoNFTs();
        if (NFTs.length == 1) {
            if (ERC721(i_boundContract).ownerOf(NFTs[0]) != msg.sender)
                revert Cava__NotOwnerOfNft();
            if (s_NFTexists[NFTs[0]] == true)
                revert Cava__AlreadyRegisteredNFT(NFTs[0]);
            safeMintWithContractToken(msg.sender, NFTs[0]);
        } else {
            for (uint256 i; i < NFTs.length; i++) {
                if (ERC721(i_boundContract).ownerOf(NFTs[i]) == msg.sender) {
                    if (s_NFTexists[NFTs[i]] == false) {
                        safeMintWithContractToken(msg.sender, NFTs[i]);
                    }
                }
            }
        }
    }

    // public
    function withdraw() public onlyOwner {
        balance[REPOSADO_BALANCE] = 0;
        balance[ANEJO_BALANCE] = 0;
        balance[BLANCO_BALANCE] = 0;
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function transferReposadoMoneyToContract() public payable {
        if (msg.value <= 0) revert Cava__NoApeIsBeingTranferred();
        balance[REPOSADO_BALANCE] += msg.value;
        emit ReposadoMoneyTransferredToContract(msg.value);
    }

    function transferAnejoMoneyToContract() public payable {
        if (msg.value <= 0) revert Cava__NoApeIsBeingTranferred();
        balance[ANEJO_BALANCE] += msg.value;
        emit AnejoMoneyTransferredToContract(msg.value);
    }

    function SetTokenReposadoToSellStage(uint256 _tokenId) public {
        if (ERC721(address(this)).ownerOf(_tokenId) != msg.sender)
            revert Cava__NotOwnerOfToken();
        if (tequilaStageUriIndex(_tokenId) != 1)
            revert Cava__NotReposadoToken();
        // reposado for sale is index 3
        uint256 reposadoSaleStage = 3;
        string memory newUri = s_IpfsUri[reposadoSaleStage];
        // Update the URI
        _setTokenURI(_tokenId, newUri);
        s_tokenInfo[_tokenId].stage = reposadoSaleStage;
        s_reposadoIdSale.push(_tokenId);
    }

    function setMultipleTokensReposadoToSellStage(
        uint256 _amount,
        uint256[] memory _tokens
    ) public {
        if (_amount < 1) revert Cava__InvalidTokenAmount(_amount);
        if (_tokens.length == 0) revert Cava__NoTokensEntered();
        for (uint256 i; i < _amount; i++) {
            SetTokenReposadoToSellStage(_tokens[i]);
        }
    }

    function SetTokenReposadoToBottleStage(uint256 _tokenId) public {
        if (ERC721(address(this)).ownerOf(_tokenId) != msg.sender)
            revert Cava__NotOwnerOfToken();
        if (tequilaStageUriIndex(_tokenId) != 1)
            revert Cava__NotReposadoToken();
        // reposado for bottle is index 4
        uint256 reposadoBottleStage = 4;
        string memory newUri = s_IpfsUri[reposadoBottleStage];
        // Update the URI
        _setTokenURI(_tokenId, newUri);
        s_tokenInfo[_tokenId].stage = reposadoBottleStage;
        s_reposadoIdBottle.push(_tokenId);
    }

    function setMultipleTokensReposadoToBottleStage(
        uint256 _amount,
        uint256[] memory _tokens
    ) public {
        if (_amount < 1) revert Cava__InvalidTokenAmount(_amount);
        if (_tokens.length == 0) revert Cava__NoTokensEntered();
        for (uint256 i; i < _amount; i++) {
            SetTokenReposadoToBottleStage(_tokens[i]);
        }
    }

    function SetTokenAnejoToSellStage(uint256 _tokenId) public {
        if (ERC721(address(this)).ownerOf(_tokenId) != msg.sender)
            revert Cava__NotOwnerOfToken();
        if (tequilaStageUriIndex(_tokenId) != 2) revert Cava__NotAnejoToken();
        // añejo for sale is index 5
        uint256 anejoSaleStage = 5;
        string memory newUri = s_IpfsUri[anejoSaleStage];
        // Update the URI
        _setTokenURI(_tokenId, newUri);
        s_tokenInfo[_tokenId].stage = anejoSaleStage;
        s_anejoIdSale.push(_tokenId);
    }

    function setMultipleTokensAnejoToSaleStage(
        uint256 _amount,
        uint256[] memory _tokens
    ) public {
        if (_amount < 1) revert Cava__InvalidTokenAmount(_amount);
        if (_tokens.length == 0) revert Cava__NoTokensEntered();
        for (uint256 i; i < _amount; i++) {
            SetTokenAnejoToSellStage(_tokens[i]);
        }
    }

    function SetTokenAnejoToBottleStage(uint256 _tokenId) public {
        if (ERC721(address(this)).ownerOf(_tokenId) != msg.sender)
            revert Cava__NotOwnerOfToken();
        if (tequilaStageUriIndex(_tokenId) != 2) revert Cava__NotAnejoToken();
        // añejo for bottle is index 6
        uint256 anejoBottleStage = 6;
        string memory newUri = s_IpfsUri[anejoBottleStage];
        // Update the URI
        _setTokenURI(_tokenId, newUri);
        s_tokenInfo[_tokenId].stage = anejoBottleStage;
        s_anejoIdBottle.push(_tokenId);
    }

    function setMultipleTokensAnejoToBottleStage(
        uint256 _amount,
        uint256[] memory _tokens
    ) public {
        if (_amount < 1) revert Cava__InvalidTokenAmount(_amount);
        if (_tokens.length == 0) revert Cava__NoTokensEntered();
        for (uint256 i; i < _amount; i++) {
            SetTokenAnejoToBottleStage(_tokens[i]);
        }
    }

    function claimReposadoApe(uint256 tokenId) public {
        if (balance[REPOSADO_BALANCE] < s_reposadoPrice)
            revert Cava__InsufficientReposadoFunds();
        if (s_reposadoPrice <= 0) revert Cava__ReposadoPriceNotSet();
        if (ERC721(address(this)).ownerOf(tokenId) != msg.sender)
            revert Cava__NotOwnerOfToken();
        if (s_tokenInfo[tokenId].stage != 3)
            revert Cava__NotReposadoSaleToken();
        uint256 reposadoPrice = s_reposadoPrice;
        _burn(tokenId);
        emit ApeClaimedFromReposadoToken(msg.sender, reposadoPrice);
        balance[REPOSADO_BALANCE] -= reposadoPrice;
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = msg.sender.call{value: reposadoPrice}("");
        require(success);
    }

    function claimMultipleReposadoTokens(
        uint256 _amount,
        uint256[] memory _tokens
    ) public {
        if (_amount > _tokens.length)
            revert Cava__NotEnoughTokens(_tokens.length);
        for (uint256 i; i < _amount; i++) {
            claimReposadoApe(_tokens[i]);
        }
    }

    function claimAnejoApe(uint256 tokenId) public {
        if (balance[ANEJO_BALANCE] < s_anejoPrice)
            revert Cava__InsufficientAnejoFunds();
        if (s_anejoPrice <= 0) revert Cava__AnejoPriceNotSet();
        if (ERC721(address(this)).ownerOf(tokenId) != msg.sender)
            revert Cava__NotOwnerOfToken();
        if (s_tokenInfo[tokenId].stage != 5) revert Cava__NotAnejoSaleToken();
        uint256 anejoPrice = s_anejoPrice;
        _burn(tokenId);
        emit ApeClaimedFromAnejoToken(msg.sender, anejoPrice);
        balance[ANEJO_BALANCE] -= anejoPrice;
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = msg.sender.call{value: anejoPrice}("");
        require(success);
    }

    function claimMultipleAnejoTokens(
        uint256 _amount,
        uint256[] memory _tokens
    ) public {
        if (_amount > _tokens.length)
            revert Cava__NotEnoughTokens(_tokens.length);
        for (uint256 i; i < _amount; i++) {
            claimAnejoApe(_tokens[i]);
        }
    }

    function claimReposadoBottle(uint256 tokenId) public {
        if (ERC721(address(this)).ownerOf(tokenId) != msg.sender)
            revert Cava__NotOwnerOfToken();
        if (s_tokenInfo[tokenId].stage != 4)
            revert Cava__NotReposadoBottleToken();
        _burn(tokenId);
        emit BottleClaimedFromReposadoToken(msg.sender);
    }

    function claimAnejoBottle(uint256 tokenId) public {
        if (ERC721(address(this)).ownerOf(tokenId) != msg.sender)
            revert Cava__NotOwnerOfToken();
        if (s_tokenInfo[tokenId].stage != 6) revert Cava__NotAnejoBottleToken();
        _burn(tokenId);
        emit BottleClaimedFromAnejoToken(msg.sender);
    }

    // internal
    function changeTequilaProcessStage(uint256 _tokenId) internal {
        if (tequilaStageUriIndex(_tokenId) >= 2) {
            return;
        }
        // Get the current stage of the tequila process and add 1
        // 0 = Blanco -> Starting value
        // 1 = Reposado -> only available after 16 weeks from blanco
        // 2 = añejo -> available after 36 weeks from reposado
        uint256 newVal = tequilaStageUriIndex(_tokenId) + 1;
        // store the new URI
        string memory newUri = s_IpfsUri[newVal];
        // Update the URI
        _setTokenURI(_tokenId, newUri);
        s_tokenInfo[_tokenId].stage = newVal;
    }

    function updateAllTokens() internal {
        uint counter = s_tokenIds;
        for (uint256 i = 1; i <= counter; i++) {
            changeTequilaProcessStage(i);
        }
    }

    // private
    function safeMint(address to) private nonReentrant {
        uint256 externalTokenId = s_ExternaltokenCounter++;
        if (externalTokenId > s_ExternalBottleSupply)
            revert Cava__NoExternalTokensLeft();
        uint256 tokenId = s_tokenIds++;
        if (tokenId > (i_maxContractSupply + s_ExternalBottleSupply))
            revert Cava__NoTokensLeft();
        uint256 tequilaStage = s_tequilaStage;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, s_IpfsUri[tequilaStage]);
        emit TokenTransferred(address(this), to, tokenId);
        s_tokenInfo[tokenId].stage = tequilaStage;
    }

    function safeMintWithContractToken(
        address to,
        uint256 _contractToken
    ) private {
        uint256 tokenId = s_tokenIds++;
        if (tokenId > i_maxContractSupply) revert Cava__NoTokensLeft();
        uint256 tequilaStage = s_tequilaStage;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, s_IpfsUri[tequilaStage]);
        emit TokenTransferred(address(this), to, tokenId);
        s_registeredMingles.push(_contractToken);
        s_NFTexists[_contractToken] == true;
        s_tokenInfo[tokenId].stage = tequilaStage;
        s_tokenInfo[tokenId].contractBoundId = _contractToken;
    }

    // internal & private view & pure functions
    // helper function to compare strings
    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // external & public view & pure functions
    // Get the current ETH/USD price
    function getEthUsdPrice() public view returns (uint256) {
        PythStructs.Price memory price = pyth.getPriceUnsafe(i_price_feed_id); //getPriceNoOlderThan(i_price_feed_id, 60);
        int256 fullPrice = int256(price.price);
        if (fullPrice < 0) revert Cava__NegativePrice();

        return uint256(fullPrice);
    }

    // determine the stage of the tequila bottle
    function tequilaStageUriIndex(
        uint256 _tokenId
    ) public view returns (uint256) {
        string memory _uri = tokenURI(_tokenId);
        uint256 value;
        // Blanco
        if (compareStrings(_uri, s_IpfsUri[0])) {
            value = 0;
        }
        // Reposado
        if (compareStrings(_uri, s_IpfsUri[1])) {
            value = 1;
        }
        // Añejo
        if (compareStrings(_uri, s_IpfsUri[2])) {
            value = 2;
        }
        // Reposado for sale
        if (compareStrings(_uri, s_IpfsUri[3])) {
            value = 3;
        }
        // Reposado for bottling
        if (compareStrings(_uri, s_IpfsUri[4])) {
            value = 4;
        }
        // Añejo for sale
        if (compareStrings(_uri, s_IpfsUri[5])) {
            value = 5;
        }
        // Añejo for bottling
        if (compareStrings(_uri, s_IpfsUri[6])) {
            value = 6;
        }
        return value;
    }

    function getBlancoBalance() public view returns (uint256) {
        return balance[BLANCO_BALANCE];
    }

    function getReposadoBalance() public view returns (uint256) {
        return balance[REPOSADO_BALANCE];
    }

    function getAnejoBalance() public view returns (uint256) {
        return balance[ANEJO_BALANCE];
    }

    function getTequilaTokenInfo(
        uint256 _token
    ) public view returns (TequilaToken memory) {
        return s_tokenInfo[_token];
    }

    // The following function is an overrides required by Solidity.
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function getTotalBalance() external view returns (uint256) {
        return getBlancoBalance() + getReposadoBalance() + getAnejoBalance();
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getIpfsUri() external view returns (string[7] memory) {
        return s_IpfsUri;
    }

    function getTequilaStage() external view returns (uint256, bytes32) {
        bytes32 currentStageString;
        uint256 currentStage = s_tequilaStage;
        if (currentStage == 1) {
            return (currentStage, currentStageString = "reposado");
        } else if (currentStage == 2) {
            return (currentStage, currentStageString = "anejo");
        } else {
            return (currentStage, currentStageString = "blanco");
        }
    }

    function getMaxContractBoundSupply() external view returns (uint256) {
        return i_maxContractSupply;
    }

    function getContractBoundAddress() external view returns (address) {
        return i_boundContract;
    }

    function getMintedTokens() external view returns (uint256) {
        return s_tokenIds;
    }

    function getExternalTokensMinted() external view returns (uint256) {
        return s_ExternaltokenCounter;
    }

    function externalBottleSupply() external view returns (uint256) {
        return s_ExternalBottleSupply;
    }

    function getMintPrice() external view returns (uint256) {
        return s_mintPrice;
    }

    function registeredMingles() external view returns (uint256[] memory) {
        return s_registeredMingles;
    }

    function checkIfNftIsRegistered(
        uint256 _token
    ) external view returns (bool) {
        return s_NFTexists[_token];
    }

    function getReposadoPrice() external view returns (uint256) {
        return s_reposadoPrice;
    }

    function getAnejoPrice() external view returns (uint256) {
        return s_anejoPrice;
    }

    function getReposadoSaleIds() external view returns (uint256[] memory) {
        return s_reposadoIdSale;
    }

    function getAnejoSaleIds() external view returns (uint256[] memory) {
        return s_anejoIdSale;
    }

    function getReposadoBottleIds() external view returns (uint256[] memory) {
        return s_reposadoIdBottle;
    }

    function getAnejoBottleIds() external view returns (uint256[] memory) {
        return s_anejoIdBottle;
    }
}

// For tests: Checks, effects, interactions

// Layout of Contract:
// version *
// imports *
// errors *
// interfaces, libraries, contracts *
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
