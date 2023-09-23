const { BigNumber } = require('bignumber.js')

function asEthBytes(val, bytes) {
  let res
  if (typeof val == "number") {
    res = BigNumber(val).toString(16)
  } else if (typeof val == "string") {
    res = val.split("").map(c => c.charCodeAt(0).toString(16)).join("")
  } else throw new Error("asEthBytes expects number or string, got " + typeof val)
  return "0x" + res.padStart(bytes * 2, "0")
}

function asEthWord(val) {
  return asEthBytes(val, 32)
}

module.exports = {
  asEthBytes: asEthBytes,
  asEthWord:  asEthWord,
}
