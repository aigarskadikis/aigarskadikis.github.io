# rotate between values
echo "
one
two
" | grep -v "^$" | while IFS= read -r LINE
do {
echo $LINE
} done

# remove leading and trailing space with sed
sed 's/^[\t ]*//g;s/[\t ]*$//g'

