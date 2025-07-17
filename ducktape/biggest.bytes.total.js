function findLargestFsByBytesTotal(data) {
    var max = null;
    var i;

    for (i = 0; i < data.length; i++) {
        if (max === null || data[i].bytes.total > max.bytes.total) {
            max = data[i];
        }
    }

    return max;
}

return JSON.stringify(findLargestFsByBytesTotal(JSON.parse(value)));
