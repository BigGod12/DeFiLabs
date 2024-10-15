// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "forge-std/Test.sol";
// import "./test/interfaces/IUSDT.sol";
// import "./test/interfaces/ILendingPool.sol";
// import "./test/interfaces/IERC20.sol";

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
interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract ContractTest is Test {
  using SafeMath for uint;
  IERC20 solBTC = IERC20(0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7);
//   USDT usdt = USDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);

  ILendingPool pool =
    ILendingPool(0xc73b6c4B4648B63f037BEbdA5f70f080a990e755);

  address[] assets = [0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7];
  uint256[] amounts = [2700000000000];
  uint256[] modes = [0];

  event Log(string message, uint val);
  function setUp() public {
    vm.createSelectFork("https://rpc.ankr.com/bsc", 40058490);
    deal(address(solBTC), address(this), 5 ether);
  }

  function testColend_Flashloan() public {
    // vm.prank(0x5832f53d147b3d6Cd4578B9CBD62425C7ea9d0Bd);
    // WBTC.transfer(address(this),2470000000);
    emit log_named_uint(
      "Before flashloan, balance of WBTC:",
      solBTC.balanceOf(address(this))
    );
    pool.flashLoan(
      address(this),
      assets,
      amounts,
      modes,
      address(this),
      "0x",
      0
    );
    emit log_named_uint(
      "After flashloan repaid, balance of WBTC:",
       solBTC.balanceOf(address(this))
    );
  }

  function executeOperation(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address initiator,
    bytes memory params
  ) public returns (bool) {
    assets;
    amounts;
    premiums;
    params;
    initiator;
    for (uint i = 0; i < assets.length; i++) {
        emit Log("borrowed", amounts[i]);
        emit Log("fee", premiums[i]);
        uint amountOwing = amounts[i].add(premiums[i]);
        solBTC.approve(address(pool), amountOwing);
    //If don't have insufficient balance, will trigger Reason: SafeERC20: low-level call failed.
    }
    return true;
  }

  receive() external payable {}
}