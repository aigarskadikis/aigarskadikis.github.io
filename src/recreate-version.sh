#!/bin/bash

clear
# start from empty space
> ../version.html

# put header
echo "<html><head><style type='text/css'>" >> ../version.html

# install css
cat readable.css >> ../version.html

# start body and all tabs
echo "</style></head><body onLoad='initDataArray()'><div class='tabs'>" >> ../version.html

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
# cat $NAME.inc >> ../version.html
cat $NAME.inc | sed -n "H;1h;\${g;s|\n<pre><code>\n|<pre><code>|g;p}" | sed -n "H;1h;\${g;s|\n</code></pre>|</code></pre>|g;p}" >> ../version.html

} done




# put footer
echo "</div><div id='searchInputArea'><span>SEARCH</span><input type='text' id='searchInput' placeholder='Type at least 1 characters...' onkeyup='onTypeSearchInput(event)' /></div><div id='searchResultDlg'><div id='closeIcon' onclick='onCloseDlg()'>&times;</div><div id='searchResultDlgContent'></div></div><script src='searcher.js'></script></body></html>" >> ../version.html

# install default block
sed -i 's|input type="radio" name="tabs" id="backup"|input type="radio" name="tabs" id="backup" checked="checked"|' ../version.html

# remove unnecessarry space
sed -i 's| </code></pre>|</code></pre>|' ../version.html

# install extra link to create users using wizard
sed -i 's|<input type="radio" name="tabs" id="users"><label for="users">users.sql</label><div class="tab">|<input type="radio" name="tabs" id="users"><label for="users">users.sql</label><div class="tab"><p>Create MySQL users using wizard: <a href="./u/version.html">https://aigarskadikis.github.io/u</a></p>|' ../index.html

# convert MySQL to PostgreSQL
# sed "s|UNIX_TIMESTAMP(NOW()-INTERVAL 1 HOUR)|EXTRACT(epoch FROM NOW()-INTERVAL '30 MINUTE')|g"

# remove includes (a source for tabs)
rm -rf *inc

# test page imediatelly
# firefox ../version.html

echo

