var process = JSON.parse(value);

process.sort(function (a, b) {
	return a.Name.localeCompare(b.Name);
});

result = process.map(function (process) {
	return {
		'Name': process.Name
	};
});

return JSON.stringify(result);
