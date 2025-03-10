function fillEmptyValues(arr) {
    var allKeys = {};
    var i, j, obj, key;

    // Collect all keys
    for (i = 0; i < arr.length; i++) {
        obj = arr[i];
        for (key in obj) {
            allKeys[key] = true;
        }
    }

    // Convert keys object to an array
    var keys = [];
    for (key in allKeys) {
        keys.push(key);
    }

    // Fill missing values
    var result = [];
    for (i = 0; i < arr.length; i++) {
        var newObj = {};
        for (j = 0; j < keys.length; j++) {
            key = keys[j];
            newObj[key] = arr[i][key] || "";
        }
        result.push(newObj);
    }

    return result;
}

// Test input
return JSON.stringify(fillEmptyValues(JSON.parse(value)));

