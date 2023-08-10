const { Matcher } = require('./matcher.js');

class ContainMatcher extends Matcher {
  #value

  constructor(value) {
    super()
    this.#value = value
  }

  match(obj) {
    if (!obj.includes(this.#value)) {
      return [
        ["expected", JSON.stringify(obj)],
        ["to contain", JSON.stringify(this.#value)],
      ]
    }
    return []
  }
}

function contain(obj) {
  return new ContainMatcher(obj);
}

module.exports = {
  contain: contain,
}
