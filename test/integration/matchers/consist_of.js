const { Matcher } = require('./matcher.js');
const { equal } = require('./equal.js');

class ConsistOfMatcher extends Matcher {
  #matchers

  constructor(matchers) {
    super();
    let matchs = [];
    for (const matcher of matchers) {
      if (matcher instanceof Matcher) {
        matchs.push(matcher);
      } else {
        matchs.push(equal(matcher));
      }
    }
    this.#matchers = matchs;
  }

  match(obj) {
    let matchers = this.#matchers.slice();
    let unmatched = [];
    for (const elem of obj) {
      let matched = false;
      for (const idx in matchers) {
        if (matchers[idx].match(elem).length == 0) {
          matched = true;
          matchers.splice(idx, 1);
          break;
        }
      }
      if (!matched) unmatched.push(elem);
    }
    let messages = [];
    if (unmatched.length > 0) {
      messages.push(["unmatched elements:", unmatched.map(m => [JSON.stringify(m)])]);
    }
    if (matchers.length > 0) {
      messages.push(["unsatisfied matchers:", matchers.map(m => [m.description()])]);
    }
    if (messages.length > 0) {
      return [
        ["expected", JSON.stringify(obj)],
        ["to consist of", this.#matchers.map(m => [m.description()])],
      ].concat(messages);
    }
    return [];
  }

  description() {
    return "consist of " + this.#matchers.map(m => m.description()).join(", ");
  }
}

function consistOf(matchers) {
  return new ConsistOfMatcher(matchers);
}

module.exports = {
  consistOf: consistOf,
}
