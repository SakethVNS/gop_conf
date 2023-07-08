folder=$1
if [ ! -f $folder/$3.1.txt ]; then
	echo "Given wrong path $folder/$3"
	exit 0
fi
#cat $folder/gop.1.txt > $folder/gop.txt
#cat $folder/gop.2.txt >> $folder/gop.txt
#cat $folder/gop.3.txt >> $folder/gop.txt
#cat $folder/gop.4.txt >> $folder/gop.txt
ref_file=$2
letter_word=$3

cat $folder/${letter_word}.txt |
 utils/int2sym_changed.pl -f 3- $folder/$ref_file |
 utils/int2sym_changed.pl -f 7 $folder/$ref_file |
 utils/int2sym_changed.pl -f 11 $folder/$ref_file |
 utils/int2sym_changed.pl -f 15 $folder/$ref_file |
 utils/int2sym_changed.pl -f 19 $folder/$ref_file |
 utils/int2sym_changed.pl -f 23 $folder/$ref_file |
 utils/int2sym_changed.pl -f 27 $folder/$ref_file |
 utils/int2sym_changed.pl -f 31 $folder/$ref_file |
 utils/int2sym_changed.pl -f 35 $folder/$ref_file |
 utils/int2sym_changed.pl -f 39 $folder/$ref_file |
 utils/int2sym_changed.pl -f 43 $folder/$ref_file |
 utils/int2sym_changed.pl -f 47 $folder/$ref_file |
 utils/int2sym_changed.pl -f 51 $folder/$ref_file |
 utils/int2sym_changed.pl -f 55 $folder/$ref_file |
 utils/int2sym_changed.pl -f 59 $folder/$ref_file |
 utils/int2sym_changed.pl -f 63 $folder/$ref_file |
 utils/int2sym_changed.pl -f 67 $folder/$ref_file |
 utils/int2sym_changed.pl -f 71 $folder/$ref_file |
 utils/int2sym_changed.pl -f 75 $folder/$ref_file |
 utils/int2sym_changed.pl -f 79 $folder/$ref_file |
 utils/int2sym_changed.pl -f 83 $folder/$ref_file |
 utils/int2sym_changed.pl -f 87 $folder/$ref_file |
 utils/int2sym_changed.pl -f 91 $folder/$ref_file |
 utils/int2sym_changed.pl -f 95 $folder/$ref_file |
 utils/int2sym_changed.pl -f 99 $folder/$ref_file |
 utils/int2sym_changed.pl -f 103 $folder/$ref_file |
 utils/int2sym_changed.pl -f 107 $folder/$ref_file |
 utils/int2sym_changed.pl -f 111 $folder/$ref_file |
 utils/int2sym_changed.pl -f 115 $folder/$ref_file |
 utils/int2sym_changed.pl -f 119 $folder/$ref_file > $folder/${letter_word}_sym.txt

cat $folder/${letter_word}.txt | tr '[' '\n' | tr ']' '\n' > $folder/${letter_word}_like_sausage.txt
cat $folder/${letter_word}_like_sausage.txt | utils/int2sym_changed.pl -f 1 $folder/$ref_file > $folder/temp
mv $folder/temp $folder/${letter_word}_like_sausage.txt


