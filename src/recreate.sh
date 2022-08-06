#!/bin/bash

clear
# start from empty space
> ../index.html

# put header
echo "<html><head><style type='text/css'>" >> ../index.html
cat css.css >> ../index.html
echo "</style></head><body><div class='tabs'>" >> ../index.html

########
# bash #
########

# list all files with extension 'sh' exclude this program. extract only filename without extension
ls -1 | grep -E "\.sh$" |grep -v "recreate.sh" | while IFS= read -r FILE
do {

NAME=$(echo "$FILE" | sed 's|.sh$||;s|.sql$||')

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
echo -e "$LINE\n<pre><code>" >> $NAME.inc
else
# blindly assume this is line having useful code
echo -n "code"
echo "$LINE" >> $NAME.inc

fi

fi

} done

# end of "TAB"
echo "</div>" >> $NAME.inc

# save some new line characters for '<pre><code></code></pre>'
cat $NAME.inc | sed -n "H;1h;\${g;s|\n<pre><code>\n|<pre><code>|g;p}" | sed -n "H;1h;\${g;s|\n</code></pre>|</code></pre>|g;p}" >> ../index.html

} done














#######
# SQL #
#######

# list all files with extension 'sh' exclude this program. extract only filename without extension
ls -1 | grep -E "\.sql$" | while IFS= read -r FILE
do {

# remove extension
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
echo -e "$LINE\n<pre><code>" >> $NAME.inc
else
# blindly assume this is line having useful code
echo -n "code"
echo "$LINE" >> $NAME.inc

fi

fi

} done

# end of "TAB"
echo "</div>" >> $NAME.inc

# save some new line characters for '<pre><code></code></pre>'
cat $NAME.inc | sed -n "H;1h;\${g;s|\n<pre><code>\n|<pre><code>|g;p}" | sed -n "H;1h;\${g;s|\n</code></pre>|</code></pre>|g;p}" >> ../index.html

} done






# put footer
echo "</div></body></html>" >> ../index.html

# install default block
sed -i 's|input type="radio" name="tabs" id="bash"|input type="radio" name="tabs" id="bash" checked="checked"|' ../index.html

rm -rf *inc

# firefox ../index.html

echo

