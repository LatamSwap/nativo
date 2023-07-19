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
| approve() infinity | 25122 | 25075 | <span style="color:green">-47</span> | <span style="color:green">0.18</span>% |
| approve() | 25116 | 25069 | <span style="color:green">-47</span> | <span style="color:green">0.18</span>% |
| balanceOf() | 3177 | 3446 | <span style="color:red">269</span> | <span style="color:red">-8.47</span>% |
| decimals() | 7562 | 5512 | <span style="color:green">-2050</span> | <span style="color:green">27.1</span>% |
| deposit() | 35797 | 36618 | <span style="color:red">821</span> | <span style="color:red">-2.3</span>% |
| depositTo() | 71403 | 46549 | <span style="color:green">-24854</span> | <span style="color:green">34.8</span>% |
| totalSupply() | 934 | 3004 | <span style="color:red">2070</span> | <span style="color:red">-221.63</span>% |
| transfer() | 25852 | 25721 | <span style="color:green">-131</span> | <span style="color:green">0.5</span>% |
| transferFrom() infinity | 26166 | 25852 | <span style="color:green">-314</span> | <span style="color:green">1.2</span>% |
| transferFrom() | 26889 | 26162 | <span style="color:green">-727</span> | <span style="color:green">2.7</span>% |
| withdraw() | 9817 | 9934 | <span style="color:red">117</span> | <span style="color:red">-1.2</span>% |
| withdrawAll() | 10921 | 10299 | <span style="color:green">-622</span> | <span style="color:green">5.69</span>% |
| withdrawAllFromTo() | 75076 | 40926 | <span style="color:green">-34150</span> | <span style="color:green">45.48</span>% |
| withdrawAllTo() | 49014 | 40717 | <span style="color:green">-8297</span> | <span style="color:green">16.92</span>% |
| withdrawFromTo() | 74178 | 40907 | <span style="color:green">-33271</span> | <span style="color:green">44.85</span>% |
| withdrawTo() | 47984 | 40045 | <span style="color:green">-7939</span> | <span style="color:green">16.54</span>% |

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
