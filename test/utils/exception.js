async function awaitException(fn) {
  try {
    await fn()
  } catch (e) {
    return e
  }
  throw new Error("awaitException: function didn't throw")
}

module.exports = {
  awaitException: awaitException,
}
