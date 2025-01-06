// Parse input into lines
var lines = value.trim().split("\n");

// Group lines by OID prefix categories
var categories = {};
for (var i = 0; i < lines.length; i++) {
    var match = lines[i].match(/(\.\d+\.\d+\.\d+\.\d+\.\d+\.\d+\.\d+)\.(\d+) =/);
    if (match) {
        var category = match[1];
        var index = match[2];
        if (!categories[category]) {
            categories[category] = {};
        }
        categories[category][index] = true;
    }
}

// Find common OID indexes across all categories
var commonIndexes = null;
for (var category in categories) {
    var indexes = Object.keys(categories[category]);
    if (commonIndexes === null) {
        commonIndexes = indexes;
    } else {
        commonIndexes = commonIndexes.filter(function(index) {
            return indexes.indexOf(index) !== -1;
        });
    }
}

// Extract lines with matching indexes
var result = [];
for (var i = 0; i < lines.length; i++) {
    for (var j = 0; j < commonIndexes.length; j++) {
        if (lines[i].indexOf("." + commonIndexes[j] + " =") !== -1) {
            result.push(lines[i]);
            break;
        }
    }
}

return result.join("\n");
