function indent(spaces, text) {
  const ind = (" ").repeat(spaces);
  return ind + text.replaceAll("\n", "\n" + ind);
}

function textify(list) {
  let entries = [];
  for(let vals of list) {
    if(vals.length == 0 || vals.length > 2){
      throw Error("textify: Argument must be array of pairs or singletons");
    }
    entries.push(vals[0]);
    if(vals.length > 1) {
      let subentry = vals[1];
      if(Array.isArray(subentry)) {
        subentry = textify(subentry);
      }
      entries.push(indent(subentry));
    }
  }
  return entries.join("\n");
}

module.exports = {
  indent:  indent,
  textify: textify,
}
