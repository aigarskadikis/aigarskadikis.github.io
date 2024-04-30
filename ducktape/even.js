var schedule = [];
for (var m = 0; m < 15; m++) {
    for (s = 0; s < 60; s++) {
        var batch2 = m + 15;
        var batch3 = m + 30;
        var batch4 = m + 45;
        schedule.push('m' + m + ',' + batch2 + ',' + batch3 + ',' + batch4 + 's' + s);
    }
}
return schedule[0];
