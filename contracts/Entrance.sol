pragma solidity >=0.4.21 <0.6.0;

import "./SafeMath.sol";

contract Entrance {
  using SafeMath for *;
  mapping(address => uint256) public balances;
  mapping(address => bool) public has_played;
  uint256 pin;
  uint256 balance;

  event EntranceFlag(string server, string port);

  modifier legit(uint256 _pin) {
    require(_pin == pin, "bye");
    _;
  }

  modifier onlyNewPlayer {
    require(has_played[msg.sender] == false, "hello");
    _;
  }

  constructor(uint256 _pin) public {
    pin = _pin;
  }

  function enter(uint256 _pin) public legit(_pin) {
    balances[msg.sender] = 10;
    has_played[msg.sender] = false;
  }

  function balanceOf(address _who) public view returns (uint256 balance) {
    return balances[_who];
  }

  function gamble() public onlyNewPlayer {
    require (balances[msg.sender] >= 10, "gamble");
    if ((block.number).mod(7) == 0) {
      balances[msg.sender] = balances[msg.sender].add(10);
      balance = balances[msg.sender];
      // Tell the sender he won!
      msg.sender.call("You won!");
      has_played[msg.sender] = true;
    } else {
      balances[msg.sender] = balances[msg.sender].sub(10);
    }
  }

  function getFlag(string memory _server, string memory _port) public {
    require (balances[msg.sender] > 300, "flag");
    emit EntranceFlag(_server, _port);
  }
}
