// extract uniq dates
var input = JSON.parse(value);
var seen = {};
var result = [];
for (var i = 0; i < input.length; i++) {
    var name = input[i].date + ' ' + input[i].partSize;
    if (!seen[name]) {
        seen[name] = true;
        result.push({"date": input[i].date,"partSize":input[i].partSize});
    }
}
return JSON.stringify(result);
