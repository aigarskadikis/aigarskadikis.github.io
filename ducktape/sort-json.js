// sort
function sortJson(obj) {
  if (Object.prototype.toString.call(obj) === '[object Object]') {
    var sortedObj = {};
    var keys = [];
    for (var key in obj) {
      if (obj.hasOwnProperty(key)) {
        keys.push(key);
      }
    }
    keys.sort();
    for (var i = 0; i < keys.length; i++) {
      var k = keys[i];
      sortedObj[k] = sortJson(obj[k]);
    }
    return sortedObj;
  } else if (Object.prototype.toString.call(obj) === '[object Array]') {
    var sortedArray = [];
    for (var j = 0; j < obj.length; j++) {
      sortedArray.push(sortJson(obj[j]));
    }
    return sortedArray.sort(function (a, b) {
      return JSON.stringify(a) > JSON.stringify(b) ? 1 : -1;
    });
  } else {
    return obj;
  }
}

return JSON.stringify(sortJson(JSON.parse(value)));

