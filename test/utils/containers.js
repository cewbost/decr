function objectify(obj) {
  return Object.fromEntries([...Object.keys(obj)].filter(isNaN).map(key => [key, obj[key]]))
}

function split(arr, cat) {
  let map = {}
  for (let val of arr) {
    let key = cat(val)
    if (!(key in map)) map[key] = []
    map[key].push(val)
  }
  return map
}

module.exports = {
  objectify: objectify,
  split:     split,
}
