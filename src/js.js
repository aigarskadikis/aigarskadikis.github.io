// if reported value is empty then return 0
return ( value.length ) ? value : 0;

// grep warning
return value.match(/.*warning.*/gm) ? value.match(/.*warning.*/gm).join("\n") : '';

// grep -c pattern
return (value.match(/.*error.*/gm) || []).length;

// wc -l
return value === "" ? 0 : value.split(/\r?\n/).length;

// grep -v warning
return value.split("\n").filter(function(line) {return !/warning/.test(line)}).join('\n');

