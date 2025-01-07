function isoToUnixTime(isoString) {
    // Parse the ISO string to milliseconds since the epoch
    var timestamp = Date.parse(isoString);
    
    // Convert milliseconds to seconds (Unix time)
    return Math.floor(timestamp / 1000);
}

return isoToUnixTime(value);
