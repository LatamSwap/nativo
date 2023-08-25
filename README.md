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
| approve() infinity | 24973 | 25110 | <span style="color:red">137</span> | <span style="color:red">-0.55</span>% |
| approve() | 24973 | 25110 | <span style="color:red">137</span> | <span style="color:red">-0.55</span>% |
| balanceOf() | 3031 | 3019 | <span style="color:green">-12</span> | <span style="color:green">0.39</span>% |
| decimals() | 7506 | 5360 | <span style="color:green">-2146</span> | <span style="color:green">28.59</span>% |
| deposit() | 35706 | 35873 | <span style="color:red">167</span> | <span style="color:red">-0.47</span>% |
| depositTo() | 71074 | 45845 | <span style="color:green">-25229</span> | <span style="color:green">35.49</span>% |
| totalSupply() | 871 | 2914 | <span style="color:red">2043</span> | <span style="color:red">-234.56</span>% |
| transfer() | 25709 | 25200 | <span style="color:green">-509</span> | <span style="color:green">1.97</span>% |
| transferFrom() infinity | 25993 | 25721 | <span style="color:green">-272</span> | <span style="color:green">1.04</span>% |
| transferFrom() | 26716 | 26042 | <span style="color:green">-674</span> | <span style="color:green">2.52</span>% |
| withdraw() | 9634 | 9692 | <span style="color:red">58</span> | <span style="color:red">-0.61</span>% |
| withdrawAll() | 10633 | 9764 | <span style="color:green">-869</span> | <span style="color:green">8.17</span>% |
| withdrawAllFromTo() | 74661 | 40608 | <span style="color:green">-34053</span> | <span style="color:green">45.61</span>% |
| withdrawAllTo() | 48687 | 39992 | <span style="color:green">-8695</span> | <span style="color:green">17.85</span>% |
| withdrawFromTo() | 73755 | 40542 | <span style="color:green">-33213</span> | <span style="color:green">45.03</span>% |
| withdrawTo() | 47781 | 39884 | <span style="color:green">-7897</span> | <span style="color:green">16.52</span>% |

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
