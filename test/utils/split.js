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
  split: split,
}
