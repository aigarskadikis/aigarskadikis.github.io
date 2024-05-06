// ectract PID
var pid = value.match(/\s*(\d+)/)[1];

// extract the rest after the PID
var afterPid = value.match(/\s*\d+(:.*)/)[1];

// how many digits in PID
var len = pid.toString().length;

// how manu placeholders in worst case scenario
var howMany = 10;

// calculate amount of needed placeholders
var place = '';
// inject placegolder
for (var n=len; n < howMany; n++){
place=place+'p';
}

return place+pid+afterPid;
