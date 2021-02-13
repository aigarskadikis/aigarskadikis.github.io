#!/bin/bash
if [ -z "$1" ]
then
echo "specify a database name"
else
DBNAME=$1

VERSION=$(mysql --database=$DBNAME -sss --skip-column-names -e "
SELECT mandatory FROM dbversion;
")

for TABLE in $(
mysql --database=$DBNAME -sss --skip-column-names -e "
SHOW TABLES;
"
)
do
CASCADES=$(
mysql --database=$DBNAME -sss --skip-column-names -e "
SHOW CREATE TABLE \`$TABLE\`\G
" | \
grep -Eo "CONSTRAINT.*FOREIGN KEY.*REFERENCES.*ON DELETE CASCADE"
)
echo "$CASCADES" | \
grep -v "^$" | \
while IFS= read -r CASCADE
do {
FOREIGN_KEY=$(echo "$CASCADE" | grep -oP "FOREIGN KEY ..\K[a-z0-9_]+")
REFERENCES=$(echo "$CASCADE" | grep -oP "REFERENCES .\K[a-z0-9_]+")
FIELD=$(echo "$CASCADE" | grep -oP "REFERENCES \S+ ..\K[a-z0-9_]+")
echo "SELECT \`$FOREIGN_KEY\` FROM \`$TABLE\` WHERE \`$FOREIGN_KEY\` NOT IN (SELECT \`$FIELD\` FROM \`$REFERENCES\`);"
} done
done > ./$VERSION.sql

mysql --database=$DBNAME -sss --skip-column-names -e "
SELECT mandatory FROM dbversion;
"

fi
