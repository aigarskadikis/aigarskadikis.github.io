const lines = value.trim().split('\n');
var result = [];
var currentLine = '';
var lines_num = lines.length;
for (i = 0; i < lines_num; i++) {
    // Check if the line starts with the OID
    if (lines[i].startsWith('.1.3.6')) {
        // If there's an accumulated line, push it to results
        if (currentLine) result.push(currentLine);
        // Start a new OID line
        currentLine = lines[i];
    } else {
        // Append hex data to the current OID line with whitespace check
        currentLine += (currentLine.endsWith(' ') ? '' : ' ') + lines[i].trim();
    }
}

// Push the final accumulated line
if (currentLine) result.push(currentLine);

// Join results into a single output
const output = result.join('\n');
return output;
