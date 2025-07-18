function hexToIp(hexString) {
    var parts = hexString.split(' ');
    var ip = [];
    for (var i = 0; i < parts.length; i++) {
        ip.push(parseInt(parts[i], 16));
    }
    return ip.join('.');
}

return hexToIp(value);
