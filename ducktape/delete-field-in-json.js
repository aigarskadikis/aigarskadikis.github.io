// delete field 'size'
var array = JSON.parse(value);
for (i=0; i<array.length; i++) { delete array[i].size;}
return JSON.stringify(array);
