const { textify } = require("./util.js");

class AssertionFailed  extends Error {
  constructor(cause) {
    this.name = "AssertionFailed";
    super(textify(cause));
  }
}

module.exports = {
  AssertionFailed: AssertionFailed,
}
