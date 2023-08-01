const { Matcher } = require('./matcher.js');
const { equal } = require('./equal.js');

class FieldsMatcher extends Matcher {
  #matchers

  constructor(fields) {
    super();
    let matchers = {};
    for(let [key, matcher] of Object.entries(fields)) {
      if(matcher instanceof Matcher) {
        matchers[key] = matcher;
      } else {
        matchers[key] = equal(matcher);
      }
    }
    this.#matchers = matchers;
  }

  match(obj) {
    let messages = [];
    for(let [key, matcher] of Object.entries(this.#matchers)) {
      if(!(key in obj)) {
        messages.push([`expected to have property ${key}`]);
      } else {
        let match = matcher.match(obj[key]);
        if(match.length > 0) {
          messages.push([`on property ${key}:`, match]);
        }
      }
    }
    if(messages.length > 0) {
      return [
        ["matching fields on", JSON.stringify(obj)],
        ["failed with errors:", messages],
      ];
    }
    return [];
  }
}

function matchFields(obj) {
  return new FieldsMatcher(obj);
}

module.exports = {
  matchFields: matchFields,
}
