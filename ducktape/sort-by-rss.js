// parse to array (if you already have an array object, skip this and set arr = yourArray)
var arr = JSON.parse(value);

// sort in-place by rss descending
arr.sort(function(a, b) {
  var ra = Number((a && a.rss) || 0);
  var rb = Number((b && b.rss) || 0);
  return rb - ra; // rb - ra => descending order
});

// pretty-print result
return JSON.stringify(arr, null, 2);
