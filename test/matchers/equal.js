const { Matcher } = require('./matcher.js');
const deepEqual = require('deep-equal');

class EqualMatcher extends Matcher {
  #value;

  constructor(value) {
    this.#value = value;
  }

  match(obj) {
    if(!deepEqual(this.#value, obj)) {
      return [
        ["expected", JSON.stringify(obj)],
        ["to equal", JSON.stringify(this.#value)],
      ];
    }
    return [];
  }
}

function equal(obj) {
  return new EqualMatcher(obj);
}

module.exports = {
  equal: equal,
}
