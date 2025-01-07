# convert test string to LLD macro
="{#"&UPPER(A2)&"}"

# substitute
=SUBSTITUTE(A2, "entPhysical", "")

# extract "ENTITY-MIB" from "ENTITY-MIB::entPhysicalDescr"
=LEFT(A2,FIND("::",A2)-1)

# extract "entPhysicalDescr" from "ENTITY-MIB::entPhysicalDescr"
=RIGHT(A2,LEN(A2)-FIND("::",A2)-1)

