const { Matcher } = require("./matcher.js")
const { AssertionFailed } = require("./error.js")

class Expectation {
  #obj
  constructor(obj) {
    this.#obj = obj
  }
  to(matcher) {
    if (!(matcher instanceof Matcher)) {
      throw Error("Argument to 'to' must be a matcher")
    }
    let res = matcher.match(this.#obj)
    if (res.length > 0) {
      throw new AssertionFailed(res)
    }
  }
}

function expect(obj) {
  return new Expectation(obj)
}

module.exports = {
  expect: expect,
}
