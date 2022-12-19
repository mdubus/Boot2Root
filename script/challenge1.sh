#!/bin/bash
rm -f out.c
cd ft_fun
tail -n +1 ./* | grep -H "file" * > ../list.txt
cd ..
awk -F: '{print $2 ":" $1}' list.txt > list2.txt
cat list2.txt | sort -V | cut -d : -f 2 > list3.txt

for file in $(cat list3.txt) ; do
    cat ft_fun/$file >> out.c
    echo >> out.c
done
rm -f list.txt list2.txt list3.txt
gcc out.c && ./a.out
