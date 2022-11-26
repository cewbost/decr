const { AssertionFailed } = require('./error.js');

class Matcher {
  match(obj) {
    throw new Error("match method not implemented");
  }
}

module.exports = {
  Matcher: Matcher,
}
