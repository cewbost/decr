const { Matcher } = require('./matcher.js');
const { BigNumber } = require('bignumber.js');

class NumberMatcher extends Matcher {
  #value

  constructor(number) {
    super();
    this.#value = BigNumber(number);
  }

  match(obj) {
    let num = BigNumber(obj);
    if(this.#value.isEqualTo(num)) {
      return [];
    } else {
      return [
        ["expected", "0x" + this.#value.toFixed(16)],
        ["to equal", "0x" + num.toFixed(16)],
      ];
    }
  }
}

function beNumber(num) {
  return new NumberMatcher(num);
}

module.exports = {
  beNumber: beNumber,
}
