const { BigNumber } = require('bignumber.js')

function asEthWord(num) {
  let str = BigNumber(num).toString(16)
  return "0x" + "0".repeat(64 - str.length) + str
}

module.exports = {
  asEthWord: asEthWord,
}
