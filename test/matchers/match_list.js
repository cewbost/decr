const { Matcher } = require('./matcher.js')

class MatchListMatcher extends Matcher {
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
      ["to match list", this.#matchers.map(m => [m.description()])],
    ].concat(messages)
    return []
  }
}

function matchList(matchers) {
  return new MatchListMatcher(matchers)
}

module.exports = {
  matchList: matchList,
}
