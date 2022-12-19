#/bin/bash


create_input_file() {
	rm -f input
	echo "Public speaking is very easy." > input
	echo "1 2 6 24 120 720" >> input
	echo "1 b 214" >> input
	echo "9" >> input
	echo "opekma" >> input
	echo "4 $1" >> input
}

file="phase_6_possibilities"
while IFS=: read -r line
do
	echo "LINE = 4 $line"
	create_input_file "$line" 
	output=$(./bomb input)
	#cat input
	test=$(echo $output | grep "The bomb has blown up.")
	#echo "$test"
	if [[ -z $test ]]; then
		echo "Found !"
		exit
	fi
done <"$file"
