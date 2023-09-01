const fs = require('fs');

const data = {};

const files = fs.readdirSync(__dirname+'/.forge-snapshots');
files.forEach(f => {
    const content = fs.readFileSync(__dirname+'/.forge-snapshots/'+f);
    const [name, func,] = f.split('.')
    data[name] = data[name] || {};

    data[name][func] = String(content)

})

let output = 
`| method           | WETH9   | Nativo   | delta  | percent cheaper |
|------------------|---------|----------|--------|-----------------|`;

Object.keys(data.nativo).forEach(methodName => {
    const gasWeth = data.weth[methodName];
    const gasNativo = data.nativo[methodName];
    let delta =  gasNativo - gasWeth;
    let perc =  Math.floor(((gasWeth-gasNativo) / gasWeth) * 100 * 100) / 100;

    if(delta>0) {
        delta = `<span style="color:red">${delta}</span>`
        perc = `<span style="color:red">${perc}</span>`
    }else {
        delta = `<span style="color:green">${delta}</span>`
        perc = `<span style="color:green">${perc}</span>`
    }
    
    output += `\n| ${methodName} | ${gasWeth} | ${gasNativo} | ${delta} | ${perc}% |` ;
})
/*
| method           | Uniswap | Huffswap | delta  | percent cheaper |

| createExchange   | 227994  | 106858   | 121136 | 53,13%          |
| addLiquidity     | 99367   | 91304    | 8063   | 8,11%           |
| removeLiquidity  | 18150   | 14286    | 3864   | 21,29%          |
| swapEthToken     | 16250   | 12953    | 3297   | 20,29%          |
| swapTokenEth     | 16999   | 13595    | 3404   | 20,02%          |
| swapTokenToToken | 28406   | 20098    | 8308   | 29,25%          |
*/

console.log(output)