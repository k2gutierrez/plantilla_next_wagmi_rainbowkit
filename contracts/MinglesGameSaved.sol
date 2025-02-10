// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

////////////////////// Custom Errors //////////////////////

error NftGame__NotOwner();
error NftGame__GameHasStarted();
error NftGame__GameHasNotStarted();
error NftGame__NoNftPrizeSet();
error NftGame__NftPrizeSet();
error NftGame__NftNotOwned();
error NftGame__NftIdRegistered();
error NftGame__NftIsDead();
error NftGame__NoSurvivors();
error NftGame__NoUsersRegistered();
error NftGame__NoNFTsPlayersAddress();
error NftGame__MingleNotOwned();
error NftGame__GameIsPaused();
error NftGame__AlreadyASurvivor();
error NftGame__MingleCannotRevive();
error NftGame__IncorrectAmount();
error NftGame__NextRoundNotAvailable();
error NftGame__GameMustBePaused();

contract NftGame {

    ////////////////////// Variables //////////////////////
    // Owner of contract address
    address private immutable i_owner;

    // Cost of registry
    uint256 private gameCost;

    // bool variables, GAME STATUS AND GAME PAUSED
    bool private gameStatus;
    bool private gamePaused;
    bool private nextRoundAvailable;
    
    // Adress of NFTS that are playing - we use the mingles nft
    address private nftAddressPlayer;
    
    // mapping to user struct
    mapping(uint256 => User) private users;

    // Arrays for final battle, registered and lost players
    uint256[] private finalBattle;
    uint256[] private mingles;
    uint256[] private registros;
    uint256[] private jugadoresPerdidos;

    // Address and id of prize nft
    address private nftAddress;
    uint256 private nftId;

    ////////////////////// Events //////////////////////

    event BalanceWithdrawn(uint256 amount);
    event GameStarted();
    event GameEnded();
    event Survivors(uint256[]);
    event WinnerSelected(uint256 winner);
    event NFTPrizeSet(address nftAddress, uint256 nftId);
    event NFTsSetForPlay(address nftAddressPlayer);
    event FailedAdventure();
    event MayahuelRevivedYou(uint256);

    ////////////////////// Game Struct: User //////////////////////

    struct User {
        uint256 nftId;
        bool status;
        bytes32 location;
        uint256 wormLvl;
        uint256 stage;
        bool revive;
    }

    ////////////////////// creation of contract to set the Owner //////////////////////
    constructor() {
        i_owner = msg.sender;
    }

    ////////////////////// Modifiers //////////////////////
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NftGame__NotOwner();
        _;
    }

    modifier gameHasStarted() {
        if (gameStatus == false) revert NftGame__GameHasNotStarted();
        _;
    }

    modifier notPaused(){
        if (gamePaused == true) revert NftGame__GameIsPaused();
        _;
    }

    modifier noContract { // this won't allow external contracts to interact with this contract
        require(tx.origin == msg.sender, "No contracts allowed");
        _;
    }

    //////////////////////////////////////////////////////////////////////
    ////////////////////// OnlyOwner Game Functions //////////////////////

    ////////////////////// Start game function
    function gameStarted(address _nftAddress, uint256 _nftId, address _nftAddressPlayer, uint256 _gameCost) external  onlyOwner noContract {
        if (gameStatus == true) revert NftGame__GameHasStarted();
        if (nftAddress != address(0)) revert NftGame__NftPrizeSet();
        if (ERC721(_nftAddress).ownerOf(_nftId) != i_owner) revert NftGame__NftNotOwned();

        gameCost = _gameCost;
        nftAddress = _nftAddress;
        nftId = _nftId;
        nftAddressPlayer = _nftAddressPlayer;
        ERC721 nft = ERC721(nftAddress);
        nft.transferFrom(msg.sender, address(this), _nftId);
        gameStatus = true;

        emit GameStarted();
        emit NFTPrizeSet(nftAddress, nftId);
        emit NFTsSetForPlay(nftAddressPlayer);
    }

    ////////////////////// Activate Pause Game
    function pauseGame() external onlyOwner noContract {
        gamePaused = !gamePaused;
    }

    ////////////////////// Activate or pause Next round
    function ToggleNextRound() external onlyOwner noContract {
        nextRoundAvailable = !nextRoundAvailable;
    }

    ////////////////////// Activate Failed Adventure/Mision
    function ActiveAdventureFailed() external onlyOwner noContract {
        require(gamePaused == true, "Game must be paused");
        
        ERC721 nft = ERC721(nftAddress);
        nft.transferFrom(address(this), i_owner, nftId);

        emit FailedAdventure();

        for (uint256 i; i < registros.length; i++) {
            users[registros[i]].status = true;
            users[registros[i]].revive = true;
            users[registros[i]].stage = 0;
            users[registros[i]].location = "";
        }

        delete finalBattle;
        delete registros;
        delete jugadoresPerdidos;
        delete mingles;
        gamePaused = false;
        nftAddress = address(0);
        nftId = 0;
        gameStatus = false;
        nftAddressPlayer = address(0);
        
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////// Registry and NextGame functions - Users/Gamers //////////////////////

    ////////////////////// New registry
    function register(uint256 _nft, uint256 _wormLvl, bytes32 _location) external payable gameHasStarted notPaused noContract returns (bool) {
        if (ERC721(nftAddressPlayer).ownerOf(_nft) != msg.sender) revert NftGame__NftNotOwned();
        if (users[_nft].nftId == _nft && users[_nft].status == true) revert NftGame__NftIdRegistered();
        if (users[_nft].nftId == _nft && users[_nft].status == false) revert NftGame__NftIsDead();
        if (msg.value < gameCost) revert  NftGame__IncorrectAmount();

        User memory user = User(_nft, true, _location, _wormLvl, 0, true);
        users[_nft] = user;
        registros.push(_nft);
        return true;
    }
    
    ////////////////////// Check if the registry must be new or give a life to the Mingle to play another game
    function nextRound(uint256 _nft, uint256 _wormLvl, bytes32 _location) external payable gameHasStarted notPaused noContract returns (bool) {
        if (nextRoundAvailable == false) revert NftGame__NextRoundNotAvailable();
        if (ERC721(nftAddressPlayer).ownerOf(_nft) != msg.sender) revert NftGame__NftNotOwned();
        if (msg.value < gameCost) revert  NftGame__IncorrectAmount();

        User memory user = users[_nft];
        if (user.nftId == 0) {
            User memory newUser = User(_nft, true, _location, _wormLvl, 0, true);
            users[_nft] = newUser;
            registros.push(_nft);
            return true;
        }
        users[_nft].location = _location;
        registros.push(_nft);
        return true;
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////// Get game information functions //////////////////////


    function getOwner() external view returns (address) {
        return i_owner;
    }

    ////////////////////// Get the user by Mingle ID
    function getUser(uint256 _nft) external view returns (User memory) {
        return users[_nft];
    }

    ////////////////////// Get number of the dead Mingles
    function getCaidos() external view returns (uint256) {
        return jugadoresPerdidos.length;
    }

    function getNftsOfFallenMingles() external view returns (uint256[] memory) {
        return jugadoresPerdidos;
    }

    ////////////////////// Get Game Status
    function getGameStatus() external view returns (bool) {
        return gameStatus;
    }

    ////////////////////// Get Game Status
    function getGamePausedStatus() external view returns (bool) {
        return gamePaused;
    }

    ////////////////////// Get Game Status
    function getNextRoundAvailable() external view returns (bool) {
        return nextRoundAvailable;
    }

    ////////////////////// Get NFT Prize contract and ID
    function getPrizeInfo() external view returns (address, uint256) {
        if (nftAddress == address(0)) revert NftGame__NoNftPrizeSet();
        if (nftId == 0) revert NftGame__NoNftPrizeSet();
        return (nftAddress, nftId);
    }

    ////////////////////// Get the address of the NFTs playing
    function getPlayingNFTsAddress() external view gameHasStarted returns (address) {
        if (nftAddressPlayer == address(0)) revert NftGame__NoNFTsPlayersAddress();
        return nftAddressPlayer;
    }

    ////////////////////// Get all registered users
    function getAllRegisteredUsers() external view gameHasStarted returns (uint256[] memory) {
        if (registros.length == 0) revert NftGame__NoUsersRegistered();
        return registros;
    }

    ////////////////////// Get the amount of users registered
    function getAmountOfRegisteredUsers() external view gameHasStarted returns (uint256) {
        if (registros.length == 0) revert NftGame__NoUsersRegistered();
        return registros.length;
    }

    ////////////////////// Get the array of survivors who enter the raffle for NFT prize
    function getSurvivors() external view gameHasStarted returns (uint256[] memory) {
        if (finalBattle.length == 0) revert NftGame__NoSurvivors();
        return finalBattle;
    }

    ////////////////////// Get the length of the survivors array - Number of participants in th raffle
    function getSurvivorsLength() external view gameHasStarted returns (uint256) {
        return finalBattle.length;
    }

    ////////////////////// Get the array of survivors who enter the raffle for NFT prize
    function getMinglesForRaffle() external view gameHasStarted returns (uint256[] memory) {
        if (finalBattle.length == 0) revert NftGame__NoSurvivors();
        return mingles;
    }

    ////////////////////// Get the length of the survivors array - Number of participants in th raffle
    function getMinglesForRaffleLength() external view gameHasStarted returns (uint256) {
        return mingles.length;
    }

    ////////////////////////////////////////////////////////////////////
    ////////////////////// Revive Mingle function //////////////////////

    ////////////////////// Trigger random chance to revive
    function reviveMingle(uint256 _nft) private gameHasStarted returns (bool) {
        if (ERC721(nftAddressPlayer).ownerOf(_nft) != msg.sender) revert NftGame__MingleNotOwned();
        if (users[_nft].revive == false) revert NftGame__MingleCannotRevive();

        bytes32 deadLocation = 0x6465616400000000000000000000000000000000000000000000000000000000;
        User storage mingle = users[_nft];
        uint256 yourChanceToRevive = mingle.wormLvl;
        uint256 decition = randomchoices() + 1;
        if (decition <= yourChanceToRevive) {
            mingle.status = true;
            mingle.revive = false;
            emit MayahuelRevivedYou(_nft);
            return true;
        } else {
            mingle.revive = false;
            mingle.status = false;
            mingle.location = deadLocation;
            jugadoresPerdidos.push(_nft);
            return false;
        }
        
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////// Battle to dead Mingle function //////////////////////

    ////////////////////// Trigger random choice to survive
    function choice(uint256 _nft, bytes32 _location, uint256 num) external gameHasStarted notPaused noContract returns (bool){
        if (ERC721(nftAddressPlayer).ownerOf(_nft) != msg.sender) revert NftGame__MingleNotOwned();
        if (users[_nft].status = false) revert NftGame__NftIsDead();
        if (users[_nft].stage == 6) revert NftGame__AlreadyASurvivor();

        User storage mingle = users[_nft];
        bytes32 deadLocation = 0x6465616400000000000000000000000000000000000000000000000000000000;
        uint256 randomNumber = randomchoices() + 1; 
        if (randomNumber > num) {
            mingle.status = true;
            mingle.location = _location;
            mingle.stage ++;

            if (mingle.stage == 6){
                finalBattle.push(_nft);
            }
            return true;
        } else if (randomNumber <= num && mingle.revive == true) {

            return reviveMingle(_nft);

        } else if (randomNumber <= num && mingle.revive == false) {
            mingle.status = false;
            mingle.location = deadLocation;
            jugadoresPerdidos.push(_nft);
            return false;
        }
        return false;
        
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////// Battle to dead Mingle function //////////////////////

    ////////////////////// Trigger random choice to survive
    function escapeChoice(uint256 _nft, bytes32 _location) external gameHasStarted noContract returns (bool){
        if (ERC721(nftAddressPlayer).ownerOf(_nft) != msg.sender) revert NftGame__MingleNotOwned();
        if (users[_nft].status = false) revert NftGame__NftIsDead();
        require(gamePaused == true, "Game must be paused");

        uint256 percentageToDie = 70;
        User storage mingle = users[_nft];
        bytes32 deadLocation = 0x6465616400000000000000000000000000000000000000000000000000000000;
        uint256 randomNumer = randomchoices() + 1;
        if (randomNumer > percentageToDie) {
            mingle.status = true;
            mingle.location = _location;
            mingle.stage ++;

            mingles.push(_nft);

            return true;

        } else if (randomNumer <= percentageToDie && mingle.revive == true) {
                
            return reviveMingle(_nft);

        } else if (randomNumer <= percentageToDie && mingle.revive == false) {

            mingle.status = false;
            jugadoresPerdidos.push(_nft);
            mingle.location = deadLocation;
            return false;

        }
        return false;
        
    }

    ////////////////////// Trigger random choice to compare with "dead" function
    function randomchoices() private view returns (uint256) {
        uint256 num = 100;
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp,
                        num
                    )
                )
            ) % num;
    }

    ///////////////////////////////////////////////////////////////////////
    ////////////////////// Final Step game functions //////////////////////

    ////////////////////// Mingle defeated the raven, enters to the survivors chamber for raffle, 
    /*function survivor(uint256 _nft) private gameHasStarted notPaused returns (bool) {
        finalBattle.push(_nft);

        return true;
    }

    ////////////////////// Mingles will try to escape to earn prize 
    function escape(uint256 _nft) private gameHasStarted returns (bool) {
        mingles.push(_nft);

        return true;
    }*/

    ////////////////////// Select a winner and send prize (NFT) automatically to winner address
    function selectWinner() external gameHasStarted onlyOwner noContract returns (uint256) { //payable?
        require(gamePaused == true, "Game must be paused");
        if (mingles.length == 0) revert NftGame__NoSurvivors();

        ERC721 playerNft = ERC721(nftAddressPlayer);
        ERC721 prizeNft = ERC721(nftAddress);

        if (mingles.length == 1) {
            address onlyWinner = playerNft.ownerOf(mingles[0]);
            prizeNft.transferFrom(address(this), onlyWinner, nftId);
            uint256 winner1 = mingles[0];
            emit WinnerSelected(winner1);

            return winner1;
        }

        uint256 winnerIndex = random() % mingles.length;
        uint256 winner = mingles[winnerIndex];
        address winnerAddress = playerNft.ownerOf(winner);
        prizeNft.transferFrom(address(this), winnerAddress, nftId);

        emit WinnerSelected(winner);

        
        return winner;
    }

    ////////////////////// Random choice to trigger in winner function
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp,
                        mingles.length
                    )
                )
            );
    }

    ////////////////////// Reset game
    function resetGame() external gameHasStarted onlyOwner noContract {
        require(gamePaused == true, "Game must be paused");

        for (uint256 i; i < registros.length; i++) {
            users[registros[i]].status = true;
            users[registros[i]].revive = true;
            users[registros[i]].stage = 0;
            users[registros[i]].location = "";
        }

        delete finalBattle;
        delete jugadoresPerdidos;
        delete registros;
        delete mingles;
        gamePaused = false;
        nftAddress = address(0);
        nftId = 0;
        gameStatus = false;
        nftAddressPlayer = address(0);
    }
    
    ////////////////////// If no survivors left the game end as a failed adventure
    /*
    function AdventureFailed() external gameHasStarted onlyOwner {
        require(gamePaused == true, "Game must be paused");
        
        nft.transferFrom(address(this), i_owner, nftId);

        for (uint256 i = 0; i < registros.length; i++) {
            users[registros[i]].status = false;
            users[registros[i]].stage = 0;
        }

        delete finalBattle;
        delete registros;
        caidos = 0;
        nftAddress = address(0);
        nftId = 0;
        gameStatus = false;
        nftAddressPlayer = address(0);
        emit FailedAdventure();
    }*/

    //////////////////////////////////////////////////////////////////////////
    ////////////////////// OnlyOwner contract functions //////////////////////

    function withdrawBalance() external onlyOwner {
        require(address(this).balance > 0, "No Balance to withdraw");
        payable(i_owner).transfer(address(this).balance);
        emit BalanceWithdrawn(address(this).balance);
    }

    ////////////////////////////////////////////////////////////////
    ////////////////////// Contract functions //////////////////////

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    ////////////////////////////////////////////////////////////////
    ////////////////////// Receive and Fallback //////////////////////
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}