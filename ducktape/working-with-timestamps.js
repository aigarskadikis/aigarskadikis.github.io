function getFormattedDate(offsetType, offsetValue) {
    var now = new Date();
    if (offsetType === "DAY") now.setDate(now.getDate() - offsetValue);
    else if (offsetType === "HOUR") now.setHours(now.getHours() - offsetValue);
    else if (offsetType === "MINUTE") now.setMinutes(now.getMinutes() - offsetValue);

    function padZero(n) { return n < 10 ? '0' + n : n; }
    return now.getFullYear() + '-' + padZero(now.getMonth() + 1) + '-' + padZero(now.getDate()) +
           'T' + padZero(now.getHours()) + ':' + padZero(now.getMinutes());
}

var url = 'https://www.google.com/q=java&pubStartDate=' + getFormattedDate("DAY", 7) +
          '&pubEndDate=' + getFormattedDate("HOUR", 0);
var response = new HttpRequest().get(url);

return url + '\n' + response;
