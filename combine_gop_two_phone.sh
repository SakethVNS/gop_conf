folder=$1
if [ ! -f $folder/gop$3.1.txt ]; then
	echo "Given wrong path"
	exit 0
fi
#cat $folder/gop.1.txt > $folder/gop.txt
#cat $folder/gop.2.txt >> $folder/gop.txt
#cat $folder/gop.3.txt >> $folder/gop.txt
#cat $folder/gop.4.txt >> $folder/gop.txt
ref_file=$2
letter_word=$3

cat $folder/gop${letter_word}.txt |
 utils/int2sym_changed.pl -f 3 $folder/$ref_file |
 utils/int2sym_changed.pl -f 5- $folder/$ref_file |
 utils/int2sym_changed.pl -f 9 $folder/$ref_file |
 utils/int2sym_changed.pl -f 11 $folder/$ref_file |
 utils/int2sym_changed.pl -f 15 $folder/$ref_file |
 utils/int2sym_changed.pl -f 17 $folder/$ref_file |
 utils/int2sym_changed.pl -f 21 $folder/$ref_file |
 utils/int2sym_changed.pl -f 23 $folder/$ref_file |
 utils/int2sym_changed.pl -f 27 $folder/$ref_file |
 utils/int2sym_changed.pl -f 29 $folder/$ref_file |
 utils/int2sym_changed.pl -f 33 $folder/$ref_file |
 utils/int2sym_changed.pl -f 35 $folder/$ref_file |
 utils/int2sym_changed.pl -f 39 $folder/$ref_file |
 utils/int2sym_changed.pl -f 41 $folder/$ref_file |
 utils/int2sym_changed.pl -f 45 $folder/$ref_file |
 utils/int2sym_changed.pl -f 47 $folder/$ref_file |
 utils/int2sym_changed.pl -f 51 $folder/$ref_file |
 utils/int2sym_changed.pl -f 53 $folder/$ref_file |
 utils/int2sym_changed.pl -f 57 $folder/$ref_file |
 utils/int2sym_changed.pl -f 59 $folder/$ref_file |
 utils/int2sym_changed.pl -f 63 $folder/$ref_file |
 utils/int2sym_changed.pl -f 65 $folder/$ref_file |
 utils/int2sym_changed.pl -f 67 $folder/$ref_file |
 utils/int2sym_changed.pl -f 69 $folder/$ref_file |
 utils/int2sym_changed.pl -f 73 $folder/$ref_file |
 utils/int2sym_changed.pl -f 75 $folder/$ref_file |
 utils/int2sym_changed.pl -f 79 $folder/$ref_file |
 utils/int2sym_changed.pl -f 81 $folder/$ref_file |
 utils/int2sym_changed.pl -f 85 $folder/$ref_file |
 utils/int2sym_changed.pl -f 87 $folder/$ref_file > $folder/gop${letter_word}_sym.txt

cat $folder/gop${letter_word}_sym.txt | tr '[' '\n' | tr ']' '\n' > $folder/gop${letter_word}_like_sausage.txt


