<p align="center">
  <a href="#nativo">
    <img src="./art/cover.png" alt="readme cover"/>
  </a>
</p>


# Nativo

`Nativo` is an enhanced version of the `WETH` contract, which provides a way to wrap the native cryptocurrency of any supported EVM network into an ERC20 token, thus enabling more sophisticated interaction with smart contracts and DApps on various blockchains.

[English readme](./README-EN.md)

---

# Nativo

`Nativo` es una versión mejorada del contrato `WETH`, que proporciona una forma de enwrappear la criptomoneda nativa de cualquier red EVM compatible en un token ERC20, permitiendo así una interacción más sofisticada con contratos inteligentes y DApps en varias blockchains.

[Español readme](./README-ES.md)


---

# Gas Benchmark

| method           | WETH9   | Nativo   | delta  | percent cheaper |
|------------------|---------|----------|--------|-----------------|
| approve() infinity | 25045 | 25139 | <span style="color:red">94</span> | <span style="color:red">-0.38</span>% |
| approve() | 25042 | 25136 | <span style="color:red">94</span> | <span style="color:red">-0.38</span>% |
| balanceOf() | 3037 | 3037 | <span style="color:green">0</span> | <span style="color:green">0</span>% |
| decimals() | 7506 | 5337 | <span style="color:green">-2169</span> | <span style="color:green">28.89</span>% |
| deposit() | 35706 | 35947 | <span style="color:red">241</span> | <span style="color:red">-0.68</span>% |
| depositTo() | 71178 | 46006 | <span style="color:green">-25172</span> | <span style="color:green">35.36</span>% |
| totalSupply() | 871 | 2927 | <span style="color:red">2056</span> | <span style="color:red">-236.06</span>% |
| transfer() | 25778 | 25456 | <span style="color:green">-322</span> | <span style="color:green">1.24</span>% |
| transferFrom() infinity | 25999 | 25973 | <span style="color:green">-26</span> | <span style="color:green">0.1</span>% |
| transferFrom() | 26722 | 26186 | <span style="color:green">-536</span> | <span style="color:green">2</span>% |
| withdraw() | 9640 | 9925 | <span style="color:red">285</span> | <span style="color:red">-2.96</span>% |
| withdrawAll() | 10651 | 10000 | <span style="color:green">-651</span> | <span style="color:green">6.11</span>% |
| withdrawAllFromTo() | 74746 | 39114 | <span style="color:green">-35632</span> | <span style="color:green">47.67</span>% |
| withdrawAllTo() | 48809 | 38460 | <span style="color:green">-10349</span> | <span style="color:green">21.2</span>% |
| withdrawFromTo() | 73889 | 39093 | <span style="color:green">-34796</span> | <span style="color:green">47.09</span>% |
| withdrawTo() | 47881 | 38408 | <span style="color:green">-9473</span> | <span style="color:green">19.78</span>% |
---

# Deployments


## Mantle Testnet

[`0x556Ba000FdF0553b79aF7815e98961Ddf4eCf84F`](https://explorer.testnet.mantle.xyz/address/0x556Ba000FdF0553b79aF7815e98961Ddf4eCf84F)

## XDAI testnet Chain

[`0x2A955Cd173b851bac5Be79BdC8Cbc5D5a30e1d8d`](https://blockscout.chiadochain.net/address/0x2A955Cd173b851bac5Be79BdC8Cbc5D5a30e1d8d)

## Scroll Alpha Testnet

[`0x2Ca416EA2F4bb26ff448823EB38e533b60875C81`](https://blockscout.scroll.io/address/0x2Ca416EA2F4bb26ff448823EB38e533b60875C81/contracts#address-tabs)

## Avax fuji


✅ Hash: 0xe8872c56d00cd986c3b370c1258a897bfa5dbd9c94066ca734f760513688e638
Contract Address: [`0x2A955Cd173b851bac5Be79BdC8Cbc5D5a30e1d8d`](https://testnet.snowtrace.io/address/0x2a955cd173b851bac5be79bdc8cbc5d5a30e1d8d)
Block: 23254746


## RSK testnet

✅ Hash: 0x9565b1786271748a297deaae610185e6daa2e11ef2e28a9b29121752505664b1
Contract Address: [`0x2A955Cd173b851bac5Be79BdC8Cbc5D5a30e1d8d`](https://explorer.testnet.rsk.co/address/0x2a955cd173b851bac5be79bdc8cbc5d5a30e1d8d)
Block: 3983205
Gas Used: 2308294

## LA CHAIN

✅ Hash: [`0x8c9df5a4c542a8ac8e4e1e4388ee11109fc7891729d13af0dcd14d2891baee8b`](https://explorer.lachain.network/tx/0x8c9df5a4c542a8ac8e4e1e4388ee11109fc7891729d13af0dcd14d2891baee8b)

Contract Address: [`0x2A955Cd173b851bac5Be79BdC8Cbc5D5a30e1d8d`](https://explorer.lachain.network/address/0x2A955Cd173b851bac5Be79BdC8Cbc5D5a30e1d8d)
