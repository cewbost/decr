const { textify, indent } = require("./util.js")

class AssertionFailed  extends Error {
  constructor(cause) {
    super(indent(4, "\n" + textify(cause)))
    this.name = "AssertionFailed"
  }
}

module.exports = {
  AssertionFailed: AssertionFailed,
}
