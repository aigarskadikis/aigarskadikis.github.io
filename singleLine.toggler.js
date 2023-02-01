storage = {}

converted = {};

function toSingleLine(ev) {

    var blocks = document.querySelectorAll('pre code');

    if (ev) {

        blocks.forEach((block, i) => {

            processBlock(block, i);

        })

        return;

    }

    blocks.forEach((block, i) => {

        block.innerHTML = storage[i].text;

    })

}

function processBlock(block, i) {

    if(!storage[i]) {

        storage[i] = {index: i, text: block.innerText};

    }

   var rawText =  block.innerText;

   var lines = rawText.split('\n');

   var result = [];

   var shouldMerge = false;

   var doubleQuote = false;

    lines.forEach(line => {

        // Rule 1

        if (line.endsWith('\\')){

            line = line.substr(0, line.length-1)

            shouldMerge = true;

        }

        // Rule 3

        if (line.endsWith('"') && line.indexOf('"') == line.length -1) {

            doubleQuote = true;

        }

        // Rule 2

        if (/^[A-Z]/.test(line)) {

            // first letter is capital. Let's check for '=' in first word

            var hasEqual = (line.split(' ') || [''])[0].indexOf('=') < 0;

            if ( hasEqual) {

                line = line + ' ';

                shouldMerge = true;

            }

        }



        if (shouldMerge || doubleQuote) {

            result.push(line);

            result.push('MergeMark')

            if (doubleQuote && !shouldMerge) {

                doubleQuote = false;

            }

            shouldMerge = false;



        } else {

            result.push(line);

        }

    });

  var combined = result.join('\n');

  // simply replace merge marge with empty line = merge

  var prefinalLine = combined.replaceAll(/\nMergeMark\n/g, '');

  // clean up last occurance if merged with last line

  var finalLine = prefinalLine.replace('\nMergeMark', '')

  converted[i] = { index: i, text: finalLine };



    block.innerHTML = converted[i].text;

}


