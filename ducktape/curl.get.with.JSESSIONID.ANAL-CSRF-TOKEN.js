var url = 'https://192.168.88.23:443/versa/analytics/nodes/status';
var request = new HttpRequest();
request.addHeader('Cookie: ' + value);
var token = value.match(/[^=]+$/)[0];
request.addHeader('X-CSRF-TOKEN: ' + token);
request.addHeader('X-Requested-With: XMLHttpRequest');
return request.get(url);
