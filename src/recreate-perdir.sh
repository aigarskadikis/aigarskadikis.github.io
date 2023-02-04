#!/bin/bash

clear

#######
# SQL #
#######

# list all files with extension 'sh' exclude this program
ls -1 | grep -E "[0-9][0-9]\.sql$" | while IFS= read -r FILE
do {

echo -e "\n##### $FILE #####"

# extract name without extension
NAME=$(echo "$FILE" | sed 's|.sql$||')

DEST="../zabbix$NAME"

# if directory does not exist then create it
[ ! -d "$DEST" ] && mkdir "$DEST"

# define location of index file
INDEX="$DEST/index.html"

# start from a clean file
> "$INDEX"

# put header
echo "<html><head><style type='text/css'>" >> "$INDEX"

# install css
cat css.css >> "$INDEX"

# start body and all tabs
echo "</style></head><body onLoad='initDataArray()'><div class='tabs'><div class='tog'><label for='toggler'>Use single line mode <input id='singleLineToggle' name='toggler' type='checkbox' /></label><script type='text/javascript'>if(/MSIE \d|Trident.*rv:/.test(navigator.userAgent)){document.write('<script src="../singleLine.togglerIE.js"><\/script>')}else{document.write('<script src="../singleLine.toggler.js"><\/script>')}</script><script>var el=document.getElementById('singleLineToggle');el.addEventListener('change',function(ev){toSingleLine(ev.target.checked)})</script></div>" >> "$INDEX"

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
cat $NAME.inc | sed -n "H;1h;\${g;s|\n<pre><code>\n|<pre><code>|g;p}" | sed -n "H;1h;\${g;s|\n</code></pre>|</code></pre>|g;p}" >> "$INDEX"

#} done




# put footer
echo "</div><div id='searchInputArea'><span>SEARCH</span><input type='text' id='searchInput' placeholder='Type at least 1 characters...' onkeyup='onTypeSearchInput(event)' /></div><div id='searchResultDlg'><div id='closeIcon' onclick='onCloseDlg()'>&times;</div><div id='searchResultDlgContent'></div></div><script src='../searcher.js'></script></body></html>" >> "$INDEX"

# install default block
sed -i 's|input type="radio" name="tabs" id="50"|input type="radio" name="tabs" id="50" checked="checked"|' "$INDEX"

# remove unnecessarry space
sed -i 's| </code></pre>|</code></pre>|' "$INDEX"

# remove trailing spaces
sed -i 's/^[ \t]*//;s/[ \t]*$//' "$INDEX"

# remove includes (a source for tabs)
rm -rf *inc
} done

echo

