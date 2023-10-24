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
    let matchers = this.#matchers.slice()
    let messages = []
    if (!Array.isArray(obj)) messages = ["expected array"]
    else if (obj.length != this.#matchers.length) messages = ["unequal length"]
    else {
      for (const idx in obj) {
        const match = this.#matchers[idx].match(obj[idx])
        if (match.length != 0) messages.push([String(idx), match])
      }
    }
    if (obj.length != matchers.length) return [
      ["expected", JSON.stringify(obj)],
      ["to match elements", this.#matchers.map(m => [m.description()])],
    ].concat(messages)
    return []
  }

  description() {
    return "match elements " + this.#matchers.map(m => m.description()).join(", ")
  }
}

function matchElements(matchers) {
  return new MatchElementsMatcher(matchers)
}

module.exports = {
  matchElements: matchElements,
}
