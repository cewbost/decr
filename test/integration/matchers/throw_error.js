const { Matcher } = require('./matcher.js')
const { equal } = require('./equal.js')

class ThrowMatcher extends Matcher {
  #matcher

  constructor(matcher) {
    super();
    if (matcher instanceof Matcher) {
      this.#matcher = matcher
    } else {
      this.#matcher = equal(matcher)
    }
  }

  match(obj) {
    if (!(obj instanceof Function)) return [
      ["expected", JSON.stringify(obj)],
      ["to be function"],
    ]
    let err = null
    try {
      obj()
      return [["expected exception"]]
    } catch (e) {
      err = e
    }
    return this.#matcher.match(err)
  }

  description() {
    return "throw exception matching " + this.#matcher.description()
  }
}

function throwError(obj) {
  return new ThrowMatcher(obj);
}

module.exports = {
  throwError: throwError,
}
