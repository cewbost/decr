const { Matcher } = require('./matcher.js');

class InstanceOfMatcher extends Matcher {
  #type;

  constructor(type) {
    super()
    this.#type = type
  }

  description() {
    return "instance of " + JSON.stringify(this.#type);
  }

  match(obj) {
    if (!(obj instanceof this.#type)) {
      return [
        ["expected", JSON.stringify(obj)],
        ["to be instance of", JSON.stringify(this.#type)],
      ]
    }
    return []
  }
}

function beInstanceOf(type) {
  return new InstanceOfMatcher(type)
}

module.exports = {
  beInstanceOf: beInstanceOf,
}
