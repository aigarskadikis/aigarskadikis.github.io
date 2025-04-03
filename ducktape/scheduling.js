function generateSchedule(batchDelay,offset) {

    // the perfect second
    var perfectSecond = offset % 60;

    // jump
    var jump = Math.floor(batchDelay / 60);

    // first minute to kick in
    var firstkick = Math.floor(offset / 60);
    
    var times = [];
    for (var m = firstkick; m < 60; m += jump) {
        times.push(m);
    }

    return "m" + times.join(',') + "s" + perfectSecond;
}

return generateSchedule(720,7);

// m/1
// m/2
// m/3
// m/5
// m/6
// m/12
// m/15
