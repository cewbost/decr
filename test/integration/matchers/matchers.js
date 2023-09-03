const { expect        } = require("./expect.js")
const { equal         } = require("./equal.js")
const { matchFields   } = require("./match_fields.js")
const { beNumber      } = require("./be_number.js")
const { beInstanceOf  } = require("./be_instance_of.js")
const { contain       } = require("./contain.js")
const { consistOf     } = require("./consist_of.js")
const { beEmpty       } = require("./be_empty.js")
const { matchElements } = require("./match_elements.js")

module.exports = {
  expect:        expect,
  equal:         equal,
  matchFields:   matchFields,
  beNumber:      beNumber,
  beInstanceOf:  beInstanceOf,
  contain:       contain,
  consistOf:     consistOf,
  beEmpty:       beEmpty,
  matchElements: matchElements,
}
