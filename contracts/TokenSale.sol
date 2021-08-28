pragma solidity >=0.4.2 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSale is Context, Ownable {
  address payable _withdrawalWallet;
  uint256 _rate;
  uint256 _startTime;
  uint256 _endTime;
  bool _initialized = false;
  bool _finalized = false;
  IERC20 _tradeToken;

  modifier onlyWithdrawalAddress() {
    require(
      _msgSender() == _withdrawalWallet,
      "Error: Only organization can call this function"
    );
    _;
  }

  event RateChanged(uint256 newRate);
  event TokenSaleStarted(uint256 startTime, uint256 endTime);
  event TokenSaleExtended(uint256 newEndTime);
  event TokenSaleFinalized(uint256 finalTime);
  event TokenSold(uint256 amount, address buyer);

  constructor(
    address withdrawalWallet_,
    uint256 rate_,
    address token_
  ) public Ownable() {
    _withdrawalWallet = payable(withdrawalWallet_);
    _rate = rate_;
    _tradeToken = IERC20(token_);
  }

  function _setRate(uint256 rate_) private returns (bool) {
    require(rate_ > 0, "Error: Rate must be greater than 0");
    _rate = rate_ * 1 ether;
    emit RateChanged(_rate);
    return true;
  }

  function setRate(uint256 rate_)
    external
    onlyWithdrawalAddress
    returns (bool)
  {
    return _setRate(rate_);
  }

  function beginTokenSale(uint256 daysFromStart)
    external
    onlyWithdrawalAddress
    returns (bool)
  {
    require(!_initialized, "Error: Token sale already begun");
    _startTime = block.timestamp;
    _endTime = block.timestamp + (daysFromStart * 1 days);
    _initialized = true;
    emit TokenSaleStarted(_startTime, _endTime);
  }

  function extendTokenSale(uint256 extension)
    external
    onlyWithdrawalAddress
    returns (bool)
  {
    require(
      !_finalized,
      "Error: Token sale has been finalized and cannot be extended"
    );
    _endTime = block.timestamp + (extension * 1 days);
    emit TokenSaleExtended(_endTime);
    return true;
  }

  function finalizeTokenSale() external onlyWithdrawalAddress returns (bool) {
    require(!_finalized, "Error: Token sale cannot be finalized twice");
    _finalized = true;
    emit TokenSaleFinalized(block.timestamp);
    return true;
  }

  function getRemainingDays() public view returns (uint256) {
    uint256 currentTimestamp = block.timestamp;

    if (_endTime > currentTimestamp) return _endTime - currentTimestamp;

    return 0;
  }

  function buy(uint256 amount) external returns (bool bought) {
    require(
      block.timestamp >= _startTime,
      "Error: Token sale has not begun yet"
    );
    require(block.timestamp < _endTime, "Error: Token sale has ended");
    _withdrawalWallet.transfer(amount);
    bool sold = _tradeToken.transferFrom(
      _withdrawalWallet,
      msg.sender,
      amount / _rate
    );
    require(sold, "Error: Failed to send XOXCASH");
    emit TokenSold(amount / _rate, msg.sender);
  }

  function setWithdrawalWallet(address withdrawalWallet_)
    external
    onlyOwner
    returns (bool)
  {
    _withdrawalWallet = payable(withdrawalWallet_);
    return true;
  }

  function getRate() external view returns (uint256) {
    return _rate;
  }

  function getStartTime() external view returns (uint256) {
    return _startTime;
  }

  function getEndTime() external view returns (uint256) {
    return _endTime;
  }
}
