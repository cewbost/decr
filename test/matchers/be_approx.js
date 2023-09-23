const { Matcher } = require('./matcher.js')
const { BigNumber } = require('bignumber.js')

class BeApproxMatcher extends Matcher {
  #value
  #delta

  constructor(num, delta) {
    super()
    this.#value = num
    this.#delta = delta
  }

  description() {
    return `=~ ${this.#value} +- ${this.#delta}`
  }

  match(obj) {
    if (Math.abs(obj - this.#value) < this.#delta) return []
    else return [
      ["expected", obj],
      ["to be approximately", `${this.#value} +- ${this.#delta}`]
    ]
  }
}

function beApprox(num, delta) {
  return new BeApproxMatcher(num, delta)
}

module.exports = {
  beApprox: beApprox,
}
