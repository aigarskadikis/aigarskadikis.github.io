var delay = value;
// generate all possible timestamps
function generateSchedule(batchDelay, offset) {
    // the perfect second
    var perfectSecond = offset % 60;
    // jump
    var jump = Math.floor(batchDelay / 60);
    // first minute to kick in
    var firstkick = Math.floor(offset / 60);
    var times = [];
    for (var m = firstkick; m < 60; m += jump) { times.push(m); }
    return "m" + times.join(',') + "s" + perfectSecond;
}
var all = [];
for (var n = 0; n < delay; n++) { 
if (!( (n % 60) === 57 )) {	
	all.push(generateSchedule(delay, n)); 
}
}

return all.join("\n");
