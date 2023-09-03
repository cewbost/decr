const { Matcher } = require('./matcher.js')

class MatchElementsMatcher extends Matcher {
  #matchers

  constructor(matchers) {
    super()
    let matchs = []
    for (const matcher of matchers) {
      if (matcher instanceof Matcher) matchs.push(matcher)
      else matchs.push(equal(matcher))
    }
    this.#matchers = matchs
  }

  match(obj) {
    let messages = []
    for (let [key, elem] of obj.entries()) {
      let res = this.#matchers[key].match(elem)
      if (res.length > 0) messages.push([`${key}:`, res])
    }
    if (messages.length > 0) return [
      ["expected", JSON.stringify(obj)],
      ["to match elements", this.#matchers.map(m => [m.description()])],
      ["failed with errors:", messages]
    ]
    return []
  }

  description() {
    return "consist of " + this.#matchers.map(m => m.description()).join(", ")
  }
}

function matchElements(matchers) {
  return new MatchElementsMatcher(matchers)
}

module.exports = {
  matchElements: matchElements,
}
