#!/bin/bash

clear
# start from empty space
> ../v/index.html

# put header
echo "<html><head><link rel='stylesheet' type='text/css' href='../src/css.css' />" >> ../v/index.html

# install css
# cat css.css >> ../v/index.html

# start body and all tabs
echo "</head><body onLoad='initDataArray()'><div class='tabs'><div class='tog'><label for='toggler'>Use single line mode <input id='singleLineToggle' name='toggler' type='checkbox' /></label><script type='text/javascript'>if(/MSIE \d|Trident.*rv:/.test(navigator.userAgent)){document.write('<script src="../singleLine.togglerIE.js"><\/script>')}else{document.write('<script src="../singleLine.toggler.js"><\/script>')}</script><script>var el=document.getElementById('singleLineToggle');el.addEventListener('change',function(ev){toSingleLine(ev.target.checked)})</script></div>" >> ../v/index.html


#######
# SQL #
#######

# list all files with extension 'sh' exclude this program
ls -1 | grep -E "[0-9][0-9]\.sql$" | while IFS= read -r FILE
do {

# extract name without extension
NAME=$(echo "$FILE" | sed 's|.sql$||')

echo -e "\n##### $FILE #####"

# this is master block for "TAB"
echo "<input type=\"radio\" name=\"tabs\" id=\"$NAME\"><label for=\"$NAME\">$FILE</label><div class=\"tab\">" > $NAME.inc

# analyze the original "TEXT" file, blindly remove first 2 lines
cat $FILE | while IFS= read -r LINE
do {
	
# check empty line
echo "$LINE" | grep "^$" > /dev/null
if [ $? -eq 0 ]; then
# echo -e "\nempty"
echo "</code></pre>" >> $NAME.inc
else

# check if the line is having comment
echo "$LINE" | grep "^--" > /dev/null
if [ $? -eq 0 ]; then
# echo comment
# If sentence endis with dot and space '. ', then uppercase the letter of next sentence
OUT=$(echo "$LINE" | sed 's|^--||' | sed 's/\. ./\U&/')
# convert line first letter to uppercase
echo -e "${OUT^}\n<pre><code>" >> $NAME.inc
else
# blindly assume this is line having useful code
echo -n '.'
# echo -n "$LINE " >> $NAME.inc
echo "$LINE " >> $NAME.inc

fi

fi

} done

echo "<p>Download this section: <a href=\"src/$FILE\">https://aigarskadikis.github.io/src/$FILE</a><br />" >> $NAME.inc
echo "Fancy syntax highlighter? Read same page on GitHub: <a href=\"https://github.com/aigarskadikis/aigarskadikis.github.io/blob/main/src/$FILE\" target=\"_blank\">https://github.com/aigarskadikis/aigarskadikis.github.io/blob/main/src/$FILE</a></p>" >> $NAME.inc

# end of "TAB"
echo "</div>" >> $NAME.inc

# save some new line characters for '<pre><code></code></pre>'
# cat $NAME.inc >> ../v/index.html
cat $NAME.inc | sed -n "H;1h;\${g;s|\n<pre><code>\n|<pre><code>|g;p}" | sed -n "H;1h;\${g;s|\n</code></pre>|</code></pre>|g;p}" >> ../v/index.html

} done




# put footer
echo "</div><div id='searchInputArea'><span>SEARCH</span><input type='text' id='searchInput' placeholder='Type at least 1 characters...' onkeyup='onTypeSearchInput(event)' /></div><div id='searchResultDlg'><div id='closeIcon' onclick='onCloseDlg()'>&times;</div><div id='searchResultDlgContent'></div></div><script src='../searcher.js'></script></body></html>" >> ../v/index.html

# install default block
sed -i 's|input type="radio" name="tabs" id="50"|input type="radio" name="tabs" id="50" checked="checked"|' ../v/index.html

# remove unnecessarry space
sed -i 's| </code></pre>|</code></pre>|' ../v/index.html

# remove trailing spaces
sed -i 's/^[ \t]*//;s/[ \t]*$//' ../v/index.html

# remove includes (a source for tabs)
rm -rf *inc

# test page imediatelly
# firefox ../v/index.html

echo

