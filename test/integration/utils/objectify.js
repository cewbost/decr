function objectify(obj) {
  return Object.fromEntries([...Object.keys(obj)].filter(isNaN).map(key => [key, obj[key]]))
}

module.exports = {
  objectify: objectify,
}
