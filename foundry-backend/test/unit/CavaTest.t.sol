// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "lib/forge-std/src/Test.sol";
import {DeployCava} from "script/DeployCava.s.sol";
import {Cava} from "src/Cava.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {NFT} from "src/other/NFT.sol";
import {MockPyth} from "lib/pyth-sdk-solidity/MockPyth.sol";

contract CavaTest is Test, CodeConstants {
    Cava public cava;
    HelperConfig public helperConfig;

    address _contract;
    uint256 _supply;
    uint256 _externalSupply;
    uint256 _mintPrice;
    address _priceFeedContract;

    MockPyth pyth;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether; 

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

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

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function setUp() external {
        DeployCava deployer = new DeployCava();
        (cava, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        pyth = MockPyth(config._priceFeedContract);

        _contract = config._contract;
        _supply = config._supply;
        _externalSupply = config._externalSupply;
        _mintPrice = config._mintPrice;
        _priceFeedContract = config._priceFeedContract;

        if (block.chainid == LOCAL_CHAIN_ID) {
            setEthPrice(100);
        }

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function createEthUpdate(
        int64 ethPrice
    ) private view returns (bytes[] memory) {
        bytes[] memory updateData = new bytes[](1);
        updateData[0] = pyth.createPriceFeedUpdateData(
            ETH_PRICE_FEED_ID,
            ethPrice * 100000, // price
            10 * 100000, // confidence
            -5, // exponent
            ethPrice * 100000, // emaPrice
            10 * 100000, // emaConfidence
            uint64(block.timestamp) // publishTime
        );

        return updateData;
    }

    function setEthPrice(int64 ethPrice) private {
        bytes[] memory updateData = createEthUpdate(ethPrice);
        uint value = pyth.getUpdateFee(updateData);
        vm.deal(address(this), value);
        pyth.updatePriceFeeds{value: value}(updateData);
    }

    function testPythPriceCall() public view {
        uint256 price = cava.getEthUsdPrice();
        console2.log("Eth to usd Price: ", price);
        assert(price > 0);
    }

}
