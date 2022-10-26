#!/bin/bash

clear
# start from empty space
> ../index.html

# put header
echo "<html><head><style type='text/css'>" >> ../index.html

# install css
cat css.css >> ../index.html

# start body and all tabs
echo "</style></head><body onLoad='initDataArray()'><div class='tabs'>" >> ../index.html

########
# bash #
########

# list all files with extension 'sh' and exclude program 'recreate.sh'
ls -1 | grep -E "\.sh$" |grep -v "recreate" | grep -v "perversion.sh" | while IFS= read -r FILE
do {

# filename without extension
NAME=$(echo "$FILE" | sed 's|.sh$||')

echo -e "\n##### $FILE #####"

# this is master block for "TAB"
echo "<input type=\"radio\" name=\"tabs\" id=\"$NAME\"><label for=\"$NAME\">$NAME</label><div class=\"tab\">" > $NAME.inc

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
echo "$LINE" | grep "^#" > /dev/null
if [ $? -eq 0 ]; then
# echo comment
# If sentence endis with dot and space '. ', then uppercase the letter of next sentence
OUT=$(echo "$LINE" | sed 's|^# ||' | sed 's/\. ./\U&/')
# convert line first letter to uppercase
echo -e "${OUT^}\n<pre><code>" >> $NAME.inc
else
# blindly assume this is line having useful code
echo -n '.'

# if lines ends with backslash then merge this line together with next line
# echo "$LINE" | grep " \\\\$" > /dev/null
# if [ $? -eq 0 ]; then
# echo -n "$LINE" | sed 's|.$||' >> $NAME.inc
# else
echo "$LINE" >> $NAME.inc
# fi

fi

fi

} done

echo "<p>Download this section: <a href=\"src/$FILE\">https://aigarskadikis.github.io/src/$FILE</a><br />" >> $NAME.inc
echo "Fancy syntax highlighter? Read same page on GitHub: <a href=\"https://github.com/aigarskadikis/aigarskadikis.github.io/blob/main/src/$FILE\" target=\"_blank\">https://github.com/aigarskadikis/aigarskadikis.github.io/blob/main/src/$FILE</a></p>" >> $NAME.inc

# end of "TAB"
echo "</div>" >> $NAME.inc

# save some new line characters for '<pre><code></code></pre>'
cat $NAME.inc | sed -n "H;1h;\${g;s|\n<pre><code>\n|<pre><code>|g;p}" | sed -n "H;1h;\${g;s|\n</code></pre>|</code></pre>|g;p}" >> ../index.html

} done





#######
# SQL #
#######

# list all files with extension 'sh' exclude this program
ls -1 | grep -E "\.sql$" | grep -v "^[0-9]" | while IFS= read -r FILE
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
# cat $NAME.inc >> ../index.html
cat $NAME.inc | sed -n "H;1h;\${g;s|\n<pre><code>\n|<pre><code>|g;p}" | sed -n "H;1h;\${g;s|\n</code></pre>|</code></pre>|g;p}" >> ../index.html

} done




# put footer
echo "</div><div id='searchInputArea'><span>SEARCH</span><input type='text' id='searchInput' placeholder='Type at least 1 characters...' onkeyup='onTypeSearchInput(event)' /></div><div id='searchResultDlg'><div id='closeIcon' onclick='onCloseDlg()'>&times;</div><div id='searchResultDlgContent'></div></div><script src='searcher.js'></script></body></html>" >> ../index.html

# install default block
sed -i 's|input type="radio" name="tabs" id="server"|input type="radio" name="tabs" id="server" checked="checked"|' ../index.html

# remove unnecessarry space
sed -i 's| </code></pre>|</code></pre>|' ../index.html

# install extra link to create users using wizard
sed -i 's|<input type="radio" name="tabs" id="users"><label for="users">users.sql</label><div class="tab">|<input type="radio" name="tabs" id="users"><label for="users">users.sql</label><div class="tab"><p>Create MySQL users using wizard: <a href="./u/index.html">https://aigarskadikis.github.io/u</a></p>|' ../index.html

# install extra link under 'server.sql' to have quries per version
sed -i 's|<input type="radio" name="tabs" id="server"><label for="server">server.sql</label><div class="tab">|<input type="radio" name="tabs" id="server"><label for="server">server.sql</label><div class="tab"><p>Explore SQLs per specific Zabbix version: <a href="./version.html">https://aigarskadikis.github.io/version.html</a></p>|' ../index.html

# convert MySQL to PostgreSQL
# sed "s|UNIX_TIMESTAMP(NOW()-INTERVAL 1 HOUR)|EXTRACT(epoch FROM NOW()-INTERVAL '30 MINUTE')|g"

# remove includes (a source for tabs)
rm -rf *inc

# test page imediatelly
# firefox ../index.html

echo

