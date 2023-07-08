#!/bin/bash

set -e -o pipefail

stage=0
nj=4
cmd=run.pl
beam=10
retry_beam=40
scale_opts="--transition-scale=1.0 --acoustic-scale=0.1 --self-loop-scale=0.1"
use_gpu=true
frames_per_chunk=70
remove_phone_markers=True

echo "$0 $@"

. ./cmd.sh
[ -f path.sh ] && . ./path.sh
. parse_options.sh || exit 1


if [[ $# -ne 4 && $# -ne 3 ]]; then
    echo "Usage: $0 <data-dir> <lang-dir> <src-dir> [<align-dir>]"
    echo "data-dir: Contains data to which alignments are to be computed"
    echo "lang-dir: Contains pronunciation model L.fst, oov etc"
    echo "src-dir: Contains trained model (exp_dir) eg: hindi_exp_7 "
    echo "align-dir: Stores obtained alignments and corresponding logs"
    exit 1
fi



data=$1
lang=$2
srcdir=$3
dir=$4
if [ $# -ne 3  ];then
    dir=$4
else
    dir=$data/ali
fi
src_tdnn_dir=$srcdir/nnet3_cleaned/tdnn_sp
src_ivector_extractor=$srcdir/nnet3_cleaned/extractor

oov=`cat $lang/oov.int` || exit 1;
mkdir -p $dir/log
echo $nj > $dir/num_jobs
sdata=$data/split$nj
[[ -d $sdata && $data/feats.scp -ot $sdata ]] || split_data.sh $data $nj || exit 1;

if [ $stage -le 1 ]; then
echo -e '\n-------------Stage 1 ----------------\n'
echo "Checking if"
echo "$srcdir has features for ivector extraction"
echo "$data has extracted feature information"

for f in $data/feats.scp; do
    if [ ! -f $f ]; then 
        echo "$0: Features not extracted for $data, Extracting now.."
        echo "Creating High-res MFCC features;"
        #utils/copy_data_dir.sh $data ${data}_hires
        steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
            --cmd "$cmd" ${data}
        steps/compute_cmvn_stats.sh ${data}
        utils/fix_data_dir.sh $data
    else
        echo "$data have extracted features not extracting again, delete $data/feats.scp to extract again or use stage value 2"
        exit 0
    fi
done

fi


if [ $stage -le 2 ]; then
echo -e '\n-------------Stage 2 ----------------\n'
echo "Checking if $src_ivector_extractor has features for ivector extractor information"
for f in $src_ivector_extractor/final.dubm $src_ivector_extractor/final.mat $src_ivector_extractor/global_cmvn.stats \
    $src_ivector_extractor/online_cmvn.conf $src_ivector_extractor/splice_opts $src_ivector_extractor/num_jobs; do
    if [ ! -f $f ]; then
        echo "$f doesn't exist; make sure that ivector model is properly trained"
        exit 1
    fi
done
cmp $src_ivector_extractor/num_jobs $dir/num_jobs || exit 1
echo "All data in $src_ivector_extractor has been verified"

echo "Extracting ivectors to $dir"
if [ ! -d $dir/ivectors ]; then
    steps/online/nnet2/extract_ivectors_online.sh --cmd "$cmd" --nj $nj \
        $data $src_ivector_extractor $dir/ivectors || exit 1
    echo "Extracted ivectors to $dir/ivectors"
else
    echo "$dir has ivectors directory; delete the directory $dir/ivectors if you want to recompute ivectors or use stage value 3"
    exit 0
fi
fi


if [ $stage -le 3  ]; then
    echo -e '\n-------------Stage 3 ----------------\n'
    echo "Obtaining alignments"
    steps/nnet3/align.sh \
        --nj $nj \
        --extra-left-context-initial 0 --extra-right-context-final 0 \
        --scale-opts "--acoustic-scale=0.1 --transition-scale=1.0 --self-loop-scale=0.1" \
        --frames-per-chunk $frames_per_chunk \
        --use-gpu true \
        --online-ivector-dir $dir/ivectors $data $lang $src_tdnn_dir $dir || exit 1;
fi


if [ $stage -le 4 ]; then
    echo -e '\n-------------Stage 4 ----------------\n'
    echo "Obtaining ctm from alignments"
    get_train_ctm_ph.sh $data $lang $dir $dir/ali || exit 1;
    #python3 utils.py $dir/ali/phone_ctm
fi






















