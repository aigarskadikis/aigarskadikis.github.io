// IE doesn't support endWith
if (!String.prototype.endsWith) {
    String.prototype.endsWith = function(search, this_len) {
        if (this_len === undefined || this_len > this.length) {
            this_len = this.length;
        }
        return this.substring(this_len - search.length, this_len) === search;
    };
}

/**
 * String.prototype.replaceAll() polyfill
 * https://gomakethings.com/how-to-replace-a-section-of-a-string-with-another-one-with-vanilla-js/
 * @author Chris Ferdinandi
 * @license MIT
 */
if (!String.prototype.replaceAll) {
	String.prototype.replaceAll = function(str, newStr){

		// If a regex pattern
		if (Object.prototype.toString.call(str).toLowerCase() === '[object regexp]') {
			return this.replace(str, newStr);
		}

		// If a string
		return this.replace(new RegExp(str, 'g'), newStr);

	};
}

storage = {};
converted = {};
processedArrays = {};
function toSingleLine(ev) {
  var blocks = document.querySelectorAll('pre code');
  var ieArray = [];
  for(var i = 0; i< blocks.length; i++) {
      ieArray.push(blocks[i]);
  }
  if (ev) {
    ieArray.forEach(function (block, i) {
      processBlock(block, i);
    });
    return;
  }
  if(!storage) {
    //IE cached view without stored real data
    return;
  }
  ieArray.forEach(function (block, i) {
    block.innerHTML = storage[i].text;
  });
}
function processBlock(block, i) {
  if (!storage[i]) {
    storage[i] = {
      index: i,
      text: block.innerHTML
    };
  }
  // not workning in IE
//   var rawText = block.innerText;
//   var lines = rawText.split('/\n/');
  var lines = block.innerHTML.split('\n');
  var result = [];
  var shouldMerge = false;
  var doubleQuote = false;
  lines.forEach(function (line) {
    // Rule 1
    if (line.endsWith('\\')) {
      line = line.substr(0, line.length - 1);
      shouldMerge = true;
    }
    // Rule 3
    if (line.endsWith('"') && line.indexOf('"') == line.length - 1) {
      doubleQuote = true;
    }
    // Rule 2
    if (/^[A-Z]/.test(line)) {
      // first letter is capital. Let's check for '=' in first word
      var hasEqual = (line.split(' ') || [''])[0].indexOf('=') < 0;
      if (hasEqual) {
        line = line + ' ';
        shouldMerge = true;
      }
    }
    if (shouldMerge || doubleQuote) {
      result.push(line);
      result.push('MergeMark');
      if (doubleQuote && !shouldMerge) {
        doubleQuote = false;
      }
      shouldMerge = false;
    } else {
      result.push(line);
    }
  });
  processedArrays[i] = result;
  var combined = result.join('\n');

  // simply replace merge marge with empty line = merge
  var prefinalLine = combined.replaceAll(/\nMergeMark\n/g, '');
  // clean up last occurance if merged with last line
  var finalLine = prefinalLine.replace('\nMergeMark', '');
  converted[i] = {
    index: i,
    text: finalLine
  };
  if (block.id == "sql2tsvCode") {
    console.log(converted[i].text);
  }
  block.innerText = converted[i].text;
}

