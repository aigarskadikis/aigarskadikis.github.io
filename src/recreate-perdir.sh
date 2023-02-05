#!/bin/bash

clear

#######
# SQL #
#######

# list all files with extension 'sql' exclude this program
ls -1 | grep -E "[0-9][0-9]\.sql$" | while IFS= read -r FILE
do {

# extract name without extension
NAME=$(echo "$FILE" | sed 's|.sql$||')

WORKDIR="/dev/shm/1/$NAME"

rm -rf "$WORKDIR" && mkdir -p "$WORKDIR"

# show progress on screen
echo -en " $NAME"

DEST="../z$NAME"

# if directory does not exist then create it
[ ! -d "$DEST" ] && mkdir "$DEST"

# define location of index file
INDEX="$DEST/index.html"

# start from an empty file
> "$INDEX"

# put header
echo "<html><head><link rel='stylesheet' type='text/css' href='../src/css.css' />" >> "$INDEX"

# start body and all tabs
echo "</head><body><div class='tabs'>" >> "$INDEX"

# install toggler button
echo "<div class='tog'>
<label for='toggler'>Use single line mode <input id='singleLineToggle' name='toggler' type='checkbox' /></label>
<script type='text/javascript'>if(/MSIE \d|Trident.*rv:/.test(navigator.userAgent)){document.write('<script src="../singleLine.togglerIE.js"><\/script>')}else{document.write('<script src="../singleLine.toggler.js"><\/script>')}</script>
<script>var el=document.getElementById('singleLineToggle');el.addEventListener('change',function(ev){toSingleLine(ev.target.checked)})</script>
</div>" >> "$INDEX"

# empty the index file
> goto.inc

# analyze the original "TEXT" file
cat $FILE | while IFS= read -r LINE
do {
	
# check if line is empty
echo "$LINE" | grep "^$" > /dev/null
if [ $? -eq 0 ]; then

# block has reached end. need to summarize what the content is about
ABOUT=$(echo "$BLOCK" | grep -m1 -oP '^FROM \K\w+')

# put the block as completed
echo -e "<p id=\"$GOTO\">${OUT^}</p><pre><code>$(echo "$BLOCK"|sed 1d)</code></pre>\n" >> "$WORKDIR/$ABOUT.2.xml"

# prepare a list item. this will be used for index under the tab
echo "<li><a href=\"#$GOTO\">${OUT^}</a></li>" >> "$WORKDIR/$ABOUT.1.xml"

else

# check if the line is having comment
echo "$LINE" | grep "^--" > /dev/null
if [ $? -eq 0 ]; then

# since its start of block then reset content
BLOCK=""

# If sentence endis with dot and space '. ', then uppercase the letter of next sentence
OUT=$(echo "$LINE" | sed 's|^--||' | sed 's/\. ./\U&/')

# calculate md5sum which will be used for have bookmarks
GOTO=$(echo "${OUT^}" | md5sum | grep -Eo "^\S+")

else

# put line in block variable
BLOCK="$(echo -e "${BLOCK}\n$LINE")"

fi

fi

} done


# go through all XML files and prepare tabs
ls -1 "$WORKDIR" | grep "2.xml" | while IFS= read -r TABDATA
do {

SECTION=$(echo "$TABDATA" | sed "s|...xml||")

# this is master block for "TAB"
echo "<input type=\"radio\" name=\"tabs\" id=\"$SECTION\"><label for=\"$SECTION\">$SECTION</label><div class=\"tab\">" >> "$INDEX"

# install index
echo "<ol>" >> "$INDEX"
cat "$WORKDIR/$SECTION.1.xml" >> "$INDEX"
echo "</ol>" >> "$INDEX"

# install content
cat "$WORKDIR/$SECTION.2.xml" >> "$INDEX"

# end of "TAB"
echo "</div>" >> "$INDEX"

} done

# put footer
echo "</div></body></html>" >> "$INDEX"

# install default tab
sed -i "s%<input type=\"radio\" name=\"tabs\" id=\"items\">%<input type=\"radio\" name=\"tabs\" id=\"items\" checked=\"checked\">%" "$INDEX"

} done

echo

