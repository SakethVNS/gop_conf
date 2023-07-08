#!/bin/bash

lmwt=10
wip=0.0
nj=4

if [ $# -ne 1 ];then
    echo "Usage: $0 [decode_dir_path]"
    echo "Decode_dir_path: Path to decode directory"
    echo "This script writes alternate decoder output in addition to best hypothesis in the form of sausage"
    echo "The directory passed must contain lat.*.gz files which were used to decode the utterances"
    echo "Main options are"
    echo "lmwt, wip and thresholds to be set in lrt_config.ini"
    exit 1
fi
. ./path.sh
. ./cmd.sh
. ./lrt_config.ini

#ctm_sausage_path is present inside decode directory with name ctm, all files related to sausage and lrt are created inside that folder
#lang - graph directory navigated from the trained model. It is expected that tree_a_sp directory is present in exp/chain/tree_a_sp
decode_dir=$1
ctm_sausage_path=$decode_dir/ctm/
lang=$decode_dir/../../tree_a_sp/graph_$storyname/

for d in $decode_dir $lang; do
if [ ! -d $d ];then
    echo "$d directory is not present; Please check and provide and correct path"
    exit 1
fi
done

for f in $decode_dir/lat.1.gz; do
    if [ ! -f $f ];then
        echo "$f file does not exist"
        exit 1
    fi
done

mkdir -p $decode_dir/ctm/
# Uncomment these two lines below if you want to use lmwt and wip from config file
lmwt="$(cat $decode_dir/scoring_kaldi/wer_details/lmwt)"
wip="$(cat $decode_dir/scoring_kaldi/wer_details/wip)"

inv_lmwt=$(echo "1/$lmwt" | bc -l)
nj=$(ls $decode_dir/lat.*gz | wc -l)
cmd=run.pl


# Creates .sau sausage files inside ctm directory

$cmd JOB=1:$nj $decode_dir/ctm/log/sausage.JOB.log \
    set -o pipefail '&&' \
    lattice-add-penalty --word-ins-penalty=$wip "ark:gunzip -c $decode_dir/lat.JOB.gz|" ark:- \| \
    lattice-prune --inv-acoustic-scale=$lmwt --beam=5 ark:- ark:- \| \
    lattice-align-words-lexicon $lang/phones/align_lexicon.int $decode_dir/../final.mdl ark:- ark:- \| \
    lattice-mbr-decode --acoustic-scale=$inv_lmwt --one-best-times=true ark:- ark:- ark:/dev/null ark,t:$decode_dir/ctm/JOB.sau || exit 1;

# Combining all sausage files
for n in `seq $nj`; do
    cat $decode_dir/ctm/$n.sau
done > $ctm_sausage_path/sausage.txt

# Removing silences from sausage text
cat $ctm_sausage_path/sausage.txt | tr '[' '\n' | tr ']' '\n' > $ctm_sausage_path/sausage_test_line_split.txt
cat $ctm_sausage_path/sausage_test_line_split.txt | utils/int2sym_changed.pl -f 1 $lang/words.txt | utils/int2sym.pl -f 3 $lang/words.txt | utils/int2sym.pl -f 5 $lang/words.txt | utils/int2sym.pl -f 7 $lang/words.txt | utils/int2sym.pl -f 9 $lang/words.txt | utils/int2sym.pl -f 11 $lang/words.txt | utils/int2sym.pl -f 13 $lang/words.txt | utils/int2sym.pl -f 15 $lang/words.txt | utils/int2sym.pl -f 17 $lang/words.txt | utils/int2sym.pl -f 19 $lang/words.txt | utils/int2sym.pl -f 21 $lang/words.txt | utils/int2sym.pl -f 23 $lang/words.txt | utils/int2sym.pl -f 25 $lang/words.txt > $ctm_sausage_path/sausage_with_symbols.txt
rm $ctm_sausage_path/sausage_test_line_split.txt
sed -i '/^<eps>/d' $ctm_sausage_path/sausage_with_symbols.txt
sed -i '/^SIL/d' $ctm_sausage_path/sausage_with_symbols.txt
sed -i '/^WH/d' $ctm_sausage_path/sausage_with_symbols.txt
sed -i '/^ON/d' $ctm_sausage_path/sausage_with_symbols.txt
sed -i '/^FP/d' $ctm_sausage_path/sausage_with_symbols.txt
sed -i '/^BR/d' $ctm_sausage_path/sausage_with_symbols.txt
sed -i '/^MB/d' $ctm_sausage_path/sausage_with_symbols.txt
sed -i '/^$/d' $ctm_sausage_path/sausage_with_symbols.txt

cat $ctm_sausage_path/sausage_with_symbols.txt | cut -f1-26 -d ' ' > temp.txt && mv temp.txt $ctm_sausage_path/sausage_with_symbols.txt

# Obtain the correct/incorrect/repeat decision from the canonical, utterance_id and path to lattice
python3 get_conf_lrt.py --correct_threshold $correct_threshold --incorrect_threshold $incorrect_threshold $decode_dir $canonical $utterance
