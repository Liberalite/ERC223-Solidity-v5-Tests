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

### STRIPPED ERC223 INFO ###
1. By removing the second transfer function ethers.js finally is happy and behaves acordingly.
2. SafeERC223 is now restored to OpenZeppelin initial technique

The transfer function checks if "to" is contract and if it is it populates an empty data bytes "0x" and sends the payload to the ReceiverContract aka ERC223Crowdsale. My only concern now is regarding if you actually want to send a data payload to make a transfer, does it breaks anything or is the perfect way to move forward using ERC223 Tokens ?
