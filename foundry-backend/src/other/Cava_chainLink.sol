//Checks, effects, interactions

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ReentrancyGuard} from "../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

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

    struct TequilaToken {
        uint256 contractBoundId; // if a token is purchased without a mingle it will remain as 0
        uint256 stage; // Have the stage as index of s_IpfsUri to know the Uri data
    }

    address private immutable i_owner; // Owner address
    address private immutable i_boundContract; // Bounded contract - in this case mingles
    uint256 private immutable i_maxContractSupply;

    uint256 private constant REPOSADO_TIME = 16 weeks;
    uint256 private constant ANEJO_TIME = 36 weeks;
    
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
    string[] s_IpfsUri = [ // Metadata information for each stage of the NFT on IPFS.
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
    mapping(uint256 => bool) private s_NFTexists; // Mapping to check if nfts has been claimed
    mapping(uint256 => TequilaToken) private s_tokenInfo; // Mapping from token id to an Info Struct

    constructor(address _contract, uint256 _supply, uint256 _externalSupply, uint256 _mintPrice)
        ERC721("CavaNFT", "TequilaNFT")
    {
        i_owner = msg.sender;
        i_boundContract = _contract;
        i_maxContractSupply = _supply;
        s_mintPrice = _mintPrice;
        s_startingTimeStamp = block.timestamp;
        s_ExternalBottleSupply = _externalSupply;
    }

    event TokenTransfered(address from, address to, uint256 tokenId);

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Cava__OnlyOwnerFunction();
        _;
    }

    function checkUpkeep(bytes calldata /* checkData */ )
        external
        view
        returns (bool upkeepNeeded/*, bytes memory  performData */ )
    {
        upkeepNeeded = (block.timestamp - s_startingTimeStamp) > REPOSADO_TIME;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        uint256 stage = s_tequilaStage;
        if (stage == 0 && (block.timestamp - s_startingTimeStamp) >= REPOSADO_TIME) {
            updateAllTokens();
            s_startingTimeStamp = block.timestamp;
            s_tequilaStage ++;
        } 
        
        if (stage == 1 && (block.timestamp - s_startingTimeStamp) >= ANEJO_TIME){
            updateAllTokens();
            s_tequilaStage ++;
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }

    function safeMint(address to) public onlyOwner nonReentrant {
        uint256 externalTokenId = s_ExternaltokenCounter++;
        if (externalTokenId > s_ExternalBottleSupply) revert Cava__NoExternalTokensLeft();
        uint256 tokenId = s_tokenIds++;
        if (tokenId > (i_maxContractSupply + s_ExternalBottleSupply)) revert Cava__NoTokensLeft();
        uint256 tequilaStage = s_tequilaStage;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, s_IpfsUri[tequilaStage]);
        emit TokenTransfered(address(this), to, tokenId);
        s_tokenInfo[tokenId].stage = tequilaStage;
    }

    function safeMintWithContractToken(address to, uint256 _contractToken) private {
        uint256 tokenId = s_tokenIds++;
        if (tokenId > i_maxContractSupply) revert Cava__NoTokensLeft();
        uint256 tequilaStage = s_tequilaStage;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, s_IpfsUri[tequilaStage]);
        emit TokenTransfered(address(this), to, tokenId);
        s_registeredMingles.push(_contractToken);
        s_NFTexists[_contractToken] == true;
        s_tokenInfo[tokenId].stage = tequilaStage;
        s_tokenInfo[tokenId].contractBoundId = _contractToken;
    }

    /**
     * @dev Allows the owner to withdraw a specified amount of an ERC‑20 token from this contract.
     * @param NFTs The array of NFTs and user has
     */
    function blancoTransferToken(uint256[] memory NFTs) external nonReentrant {
        if (NFTs.length == 0) revert Cava__NoNFTs();
        if (NFTs.length == 1) {
            if (ERC721(i_boundContract).ownerOf(NFTs[0]) != msg.sender) revert Cava__NotOwnerOfNft();
            if (s_NFTexists[NFTs[0]] == true) revert Cava__AlreadyRegisteredNFT(NFTs[0]);
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

    function SetTokenReposadoToSellStage(uint256 _tokenId) public {
        if (ERC721(address(this)).ownerOf(_tokenId) != msg.sender) revert Cava__NotOwnerOfToken();
        if (tequilaStageUriIndex(_tokenId) != 1) revert Cava__NotReposadoToken();
        // reposado for sale is index 3
        uint256 reposadoSaleStage = 3;
        string memory newUri = s_IpfsUri[reposadoSaleStage];
        // Update the URI
        _setTokenURI(_tokenId, newUri);
        s_tokenInfo[_tokenId].stage = reposadoSaleStage;
    }

    function SetTokenReposadoToBottleStage(uint256 _tokenId) public {
        if (ERC721(address(this)).ownerOf(_tokenId) != msg.sender) revert Cava__NotOwnerOfToken();
        if (tequilaStageUriIndex(_tokenId) != 1) revert Cava__NotReposadoToken();
        // reposado for bottle is index 4
        uint256 reposadoBottleStage = 4;
        string memory newUri = s_IpfsUri[reposadoBottleStage];
        // Update the URI
        _setTokenURI(_tokenId, newUri);
        s_tokenInfo[_tokenId].stage = reposadoBottleStage;
    }

    function SetTokenAnejoToSellStage(uint256 _tokenId) public {
        if (ERC721(address(this)).ownerOf(_tokenId) != msg.sender) revert Cava__NotOwnerOfToken();
        if (tequilaStageUriIndex(_tokenId) != 2) revert Cava__NotAnejoToken();
        // añejo for sale is index 5
        uint256 anejoSaleStage = 5;
        string memory newUri = s_IpfsUri[anejoSaleStage];
        // Update the URI
        _setTokenURI(_tokenId, newUri);
        s_tokenInfo[_tokenId].stage = anejoSaleStage;
    }

    function SetTokenAnejoToBottleStage(uint256 _tokenId) public {
        if (ERC721(address(this)).ownerOf(_tokenId) != msg.sender) revert Cava__NotOwnerOfToken();
        if (tequilaStageUriIndex(_tokenId) != 2) revert Cava__NotAnejoToken();
        // añejo for bottle is index 6
        uint256 anejoBottleStage = 6;
        string memory newUri = s_IpfsUri[anejoBottleStage];
        // Update the URI
        _setTokenURI(_tokenId, newUri);
        s_tokenInfo[_tokenId].stage = anejoBottleStage;
    }

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
        for(uint256 i=1; i <= counter; i++){
            changeTequilaProcessStage(i);
        }
    }

    // determine the stage of the flower growth
    function tequilaStageUriIndex(uint256 _tokenId) public view returns (uint256) {
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

    /*
     ********************
     * HELPER FUNCTIONS *
     ********************
     */
    // helper function to compare strings
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
