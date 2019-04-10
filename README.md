# ERC223-Solidity-v5-Tests
Function Overloading &amp; SafeTransfer Tests using Ethers.js v4

ERC223-Solidity-v5-Tests is a design pattern for creating ERC223 Vested Tokens ICO, aiming to simplify and maintain ERC223 Tokens with self governing contracts that do not use relayers/proxies/oracles.

Setup:

```npm i -g etherlime ganache```\
```npm i -g etherlime```

Deployment & Testing:
1. Run Ganache inside a terminal using: ```etherlime ganache```
2. Deploy Contracts to local Ganache Instance using: ```etherlime deploy```
3. Run etherlime tests using: ```etherlime test```

Current discovered bugs:
1. After deploying contracts to Ganache if we go check the ABI, we can see that we have 2 transfer methods that use the function overloading technique since we are using ERC223.
The trick here is that sometimes the transfer function accepts 2 arguments or 3 arguments depending on which one is above in the list.
The current tests are made to make transfers using 2 arguments that can send tokens to both an address or a contract. 
Depending on the order inside the ABI we can see that transfer with 2 arguments can fail since ethers.js only see the first function.

2. The Crowdsale Contract uses SafeERC20 which now checks if any data is passed to the function using and sends the call to the function selector. Tried to change ```callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value))``` to ```callOptionalReturn(token, abi.encodeWithSelector(msg.sig, from, to, value))``` instead and currently fails. 
The only way i found to make transfers work is by rolling back to the old way SafeERC20 used to work which is ```require(token.transfer(to, value));```
