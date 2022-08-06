#!/bin/bash

clear
# start from empty space
> ../index.html

# put header
echo "<html><head><style type='text/css'>" >> ../index.html

# install css
cat css.css >> ../index.html

# start body and all tabs
echo "</style></head><body><div class='tabs'>" >> ../index.html

########
# bash #
########

# list all files with extension 'sh' and exclude this program
ls -1 | grep -E "\.sh$" |grep -v "recreate.sh" | while IFS= read -r FILE
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
echo -e "\nempty"
echo "</code></pre>" >> $NAME.inc
else

# check if the line is having comment
echo "$LINE" | grep "^#" > /dev/null
if [ $? -eq 0 ]; then
echo comment
# If sentence endis with dot and space '. ', then uppercase the letter of next sentence
OUT=$(echo "$LINE" | sed 's|^# ||' | sed 's/\. ./\U&/')
# convert line first letter to uppercase
echo -e "${OUT^}\n<pre><code>" >> $NAME.inc
else
# blindly assume this is line having useful code
echo -n "code"

# if lines ends with backslash then merge this line together with next line
echo "$LINE" | grep " \\\\$" > /dev/null
if [ $? -eq 0 ]; then
echo -n "$LINE" | sed 's|.$||' >> $NAME.inc
else
echo "$LINE" >> $NAME.inc
fi

fi

fi

} done

echo "<p>Download this section: <a href=\"src/$FILE\">https://aigarskadikis.github.io/src/$FILE</a><br />" >> $NAME.inc
echo "Code on GitHub: <a href=\"https://github.com/aigarskadikis/aigarskadikis.github.io/blob/main/src/$FILE\" target=\"_blank\">https://github.com/aigarskadikis/aigarskadikis.github.io/blob/main/src/$FILE</a></p>" >> $NAME.inc

# end of "TAB"
echo "</div>" >> $NAME.inc

# save some new line characters for '<pre><code></code></pre>'
cat $NAME.inc | sed -n "H;1h;\${g;s|\n<pre><code>\n|<pre><code>|g;p}" | sed -n "H;1h;\${g;s|\n</code></pre>|</code></pre>|g;p}" >> ../index.html

} done





#######
# SQL #
#######

# list all files with extension 'sh' exclude this program
ls -1 | grep -E "\.sql$" | while IFS= read -r FILE
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
echo -e "\nempty"
echo "</code></pre>" >> $NAME.inc
else

# check if the line is having comment
echo "$LINE" | grep "^--" > /dev/null
if [ $? -eq 0 ]; then
echo comment
# If sentence endis with dot and space '. ', then uppercase the letter of next sentence
OUT=$(echo "$LINE" | sed 's|^--||' | sed 's/\. ./\U&/')
# convert line first letter to uppercase
echo -e "${OUT^}\n<pre><code>" >> $NAME.inc
else
# blindly assume this is line having useful code
echo -n "code"
echo -n "$LINE " >> $NAME.inc

fi

fi

} done

echo "<p>Download this section: <a href=\"src/$FILE\">https://aigarskadikis.github.io/src/$FILE</a><br />" >> $NAME.inc
echo "Code on GitHub: <a href=\"https://github.com/aigarskadikis/aigarskadikis.github.io/blob/main/src/$FILE\" target=\"_blank\">https://github.com/aigarskadikis/aigarskadikis.github.io/blob/main/src/$FILE</a></p>" >> $NAME.inc

# end of "TAB"
echo "</div>" >> $NAME.inc


# save some new line characters for '<pre><code></code></pre>'
cat $NAME.inc | sed -n "H;1h;\${g;s|\n<pre><code>\n|<pre><code>|g;p}" | sed -n "H;1h;\${g;s|\n</code></pre>|</code></pre>|g;p}" >> ../index.html

} done






# put footer
echo "</div></body></html>" >> ../index.html

# install default block
sed -i 's|input type="radio" name="tabs" id="backup"|input type="radio" name="tabs" id="backup" checked="checked"|' ../index.html

# remove unnecessarry space
sed -i 's| </code></pre>|</code></pre>|' ../index.html

# remove includes (a source for tabs)
rm -rf *inc

# test page imediatelly
firefox ../index.html

echo
