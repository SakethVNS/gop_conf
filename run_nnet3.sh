#!/usr/bin/env bash

# Copyright      2019  Junbo Zhang
#           2020-2021  Xiaomi Corporation (Author: Junbo Zhang, Yongqing Wang)
# Apache 2.0

# This script shows how to calculate Goodness of Pronunciation (GOP) and
# use the GOP-based feature to do phone-level mispronunciations detection.
# Read ../README.md or the following paper for details:
#
# "Hu et al., Improved mispronunciation detection with deep neural network
# trained acoustic models and transfer learning based logistic regression
# classifiers, 2015."


# Set this to somewhere where you want to put your data, or where someone 
# else has already put it.  You'll want to change this if you're not on
# the Xiaomi's grid.
retrain=/media/run/kaldi/egs/iitm_baseline/English_ASR_Challenge/asr
gop=/media/run/kaldi/egs/gop_speechocean762/s5/
retrain_data=$retrain/data
data=data
# data=old_data

# Base url for downloads.
data_url=www.openslr.org/resources/101
stage=3
nj=8
phone_gop=1

# You might not want to do this for interactive shells.
set -e

. ./cmd.sh
. ./path.sh
. parse_options.sh

# This recipe depends on the model trained in the librispeech recipe.
# For training it:
#   cd $KALDI_ROOT/egs/librispeech/s5
#   ./run.sh && local/nnet3/run_tdnn.sh

# Check librispeech's models

librispeech_eg=../../librispeech/s5


#model=$librispeech_eg/$exp/nnet3_cleaned/tdnn_sp
#model=exp_jan_2_wpp/chain/tdnn
model=exp_nnet3_retrain/nnet3_cleaned/tdnn_sp
# model=eng_exp_iitm_harsha/chain/tdnn
# model=exp_jan_18_iitm/chain/tdnn
# model=hindi_exp_sep_30_word_letter_up_rj/chain/tdnn

exp=$model/../../

#ivector_extractor=$librispeech_eg/$exp/nnet3_cleaned/extractor
# ivector_extractor=$model/../../nnet3/extractor
ivector_extractor=$model/../extractor


#lang=$librispeech_eg/data/lang
#lang=$data/lang_phone_bg/
#lang=$data/lang_no_gm/
# lang=$retrain_data/lang_hindi_let_wor_saketh/
#lang=$retrain_data/lang_gop_ph/
# lang=$data/lang_gop_400_ex_one_sil
lang=$data/lang_gop_gm_ph_0.1_gm/


dict=$data/local/gop_400_ex_dictionary


# train=gop_test_data # Hindi data
train=dec_gop_572_nnet3 # English data
test=""


for d in $model $ivector_extractor $lang; do
  [ ! -d $d ] && echo "$0: no such path $d" && exit 1;
done

if [ $stage -le -1 ]; then
  # Download data and untar
  local/download_and_untar.sh $data_url $data
fi

if [ $stage -le -2 ]; then
  # Prepare data
  for part in $train; do
    local/data_prep.sh $data/$part $data/$part
  done

  #mkdir -p data/local
  #cp $data/speechocean762/resource/* data/local
fi

if [ $stage -le 3 ]; then
  # Create high-resolution MFCC features
  for part in $train; do
    steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
      --cmd "$cmd" $data/$part || exit 1;
    steps/compute_cmvn_stats.sh $data/$part || exit 1;
    utils/fix_data_dir.sh $data/$part
  done
fi
#exit 1
if [ $stage -le 4 ]; then
  # Extract ivector
  for part in $train; do
    steps/online/nnet2/extract_ivectors_online.sh --cmd "$cmd" --nj $nj \
      $data/$part $ivector_extractor $data/$part/alignments/ivectors || exit 1;
  done
fi
#exit 0

       # --frame-subsampling-factor 3 \
if [ $stage -le 5 ]; then
  # Compute Log-likelihoods
  for part in $train; do
    steps/nnet3/compute_output.sh --cmd "$cmd" --nj $nj \
    --use-gpu true \
    --online-ivector-dir $data/$part/alignments/ivectors $data/$part $model $exp/probs_$part
  done
fi

if [ $stage -le 6 ]; then
  # Prepare lang
  #local/prepare_dict.sh $data/local/dictionary_dummy/lexicon.txt $data/local/dict_nosp
  #sed -i '/SIL/d' $data/local/dict_nosp/nonsilence_phones.txt
  utils/prepare_lang.sh --phone-symbol-table $lang/phones.txt \
    $dict/ "!SIL" $data/local/lang_tmp_nosp $data/lang_nosp
fi

if [ $stage -le 6 ]; then
    get_align_nnet3.sh --stage 3 --nj $nj $data/$train $lang $exp $data/$train/alignments
    echo "## Create text-phone file and run from stage 7##"
    exit 0
fi

if [ $stage -le -7 ]; then
  # Split data and make phone-level transcripts
  for part in $train; do
    utils/split_data.sh $data/$part $nj
    for i in `seq 1 $nj`; do
      utils/sym2int.pl --map-oov "!SIL" -f 2- $data/lang_nosp/words.txt \
        $data/$part/split${nj}/$i/text \
        > $data/$part/split${nj}/$i/text.int
    done

    utils/sym2int.pl -f 2- $data/lang_nosp/phones.txt \
      $data/local/text-phone > $data/local/text-phone.int
  done
fi
#exit 0
if [ $stage -le 7 ]; then
    echo "stage 7"
  # Split data and make phone-level transcripts
  cp -r $lang/* $data/lang_nosp
  for part in $train; do
    utils/split_data.sh $data/$part $nj
    for i in `seq 1 $nj`; do
      utils/sym2int.pl --map-oov "!SIL" -f 2- $data/lang_nosp/words.txt \
        $data/$part/split${nj}/$i/text \
        > $data/$part/split${nj}/$i/text.int
    done

    utils/sym2int.pl -f 2- $data/lang_nosp/phones.txt \
      data/local/text-phone > $data/local/text-phone.int
  done
fi


echo "here"
#exit 0
if [ $stage -le 8 ]; then
  # Make align graphs
  for part in $train; do
    $cmd JOB=1:$nj $exp/ali_$part/log/mk_align_graph.JOB.log \
      compile-train-graphs-without-lexicon \
        --read-disambig-syms=$data/lang_nosp/phones/disambig.int \
        $model/tree $model/final.mdl \
        "ark,t:$data/$part/split${nj}/JOB/text.int" \
        "ark,t:$data/local/text-phone.int" \
        "ark:|gzip -c > $exp/ali_$part/fsts.JOB.gz" || exit 1;
    echo $nj > $exp/ali_$part/num_jobs
  done
fi

if [ $stage -le 9 ]; then
  # Align
  for part in $train; do
    steps/align_mapped.sh --cmd "$cmd" --nj $nj \
    --scale_opts "--transition-scale=1.0 --acoustic-scale=0.1 --self-loop-scale=0.1" \
    --graphs $exp/ali_$part \
      $data/$part $exp/probs_$part $lang $model $exp/ali_$part
  done
fi

if [ $stage -le 10 ]; then
  # Make a map which converts phones to "pure-phones"
  # "pure-phone" means the phone whose stress and pos-in-word markers are ignored
  # eg. AE1_B --> AE, EH2_S --> EH, SIL --> SIL
  local/remove_phone_markers.pl $lang/phones.txt \
    $data/lang_nosp/phones-pure.txt $data/lang_nosp/phone-to-pure-phone.int
fi

if [ $stage -le 11 ]; then
  # Convert transition-id to phone-id
  for part in $train; do
    $cmd JOB=1:$nj $exp/ali_$part/log/ali_to_phones.JOB.log \
      ali-to-phones --frame-shift=0.03 --per-frame=true $model/final.mdl \
        "ark,t:gunzip -c $exp/ali_$part/ali.JOB.gz|" \
        "ark,t:|gzip -c >$exp/ali_$part/ali-phone.JOB.gz"   || exit 1;
  done
fi
#exit 0
if [ $stage -le 12 ]; then
  # Use alignments and get word level alignments in ali-word format similar to that of phone level done in above stage
    oov=`cat $lang/oov.int` || exit 1;
    for part in $train; do
    $cmd JOB=1:$nj $exp/ali_$part/log/align_to_word.JOB.log \
    set -o pipefail '&&' \
    linear-to-nbest "ark,t:gunzip -c $exp/ali_$part/ali.JOB.gz|" "ark:sym2int.pl --map-oov $oov -f 2- data/lang_nosp/words.txt < $data/$part/split$nj/JOB/text|" "" "" "ark:-" \| \
    lattice-align-words "$lang/phones/word_boundary.int" "$model/final.mdl" "ark:-" "ark,t:|gzip -c >$exp/ali_$part/aligned_words.JOB.gz" || exit 1;
    ./ali-word-converter.py $exp/ali_$part/
    done

fi

# free_phone_dir=exp_jan_2_wpp/chain/tdnn/decode_gop_400_bg/
# free_lang=data/lang_gop_400_bg/
# mkdir -p $free_phone_dir/ali
# if [ $stage -le 12 ]; then
#     oov=`cat $lang/oov.int` || exit 1;
#     for part in $train; do
#     $cmd JOB=1:$nj $free_phone_dir/log/lattice_to_word.JOB.log \
#     set -o pipefail '&&' \
#     lattice-1best --acoustic-scale=0.4 --word-ins-penalty=4 "ark,t:gunzip -c $free_phone_dir/lat.JOB.gz|" "ark:-" \| \
#     lattice-align-words-lexicon "$free_lang/phones/align_lexicon.int" "$model/final.mdl" "ark:-" "ark,t:|gzip -c >$free_phone_dir/ali/aligned_words.JOB.gz" || exit 1;
#     ./ali-word-converter.py $free_phone_dir/ali/
#     done

# fi
#exit 0
if [ $stage -le 12 ]; then
  # The outputs of the binary compute-gop are the GOPs and the gop-base features.
  #
  # An example of the GOP result (extracted from "ark,t:$dir/gop.3.txt"):
  # 4446-2273-0031 [ 1 0 ] [ 12 0 ] [ 27 -5.382001 ] [ 40 -13.91807 ] [ 1 -0.2555897 ] \
  #                [ 21 -0.2897284 ] [ 5 0 ] [ 31 0 ] [ 33 0 ] [ 3 -11.43557 ] [ 25 0 ] \
  #                [ 16 0 ] [ 30 -0.03224623 ] [ 5 0 ] [ 25 0 ] [ 33 0 ] [ 1 0 ]
  # It is in the posterior format, where each pair stands for [pure-phone-index gop-value].
  # For example, [ 27 -5.382001 ] means the GOP of the pure-phone 27 (it corresponds to the
  # phone "OW", according to "$dir/phones-pure.txt") is -5.382001, indicating the audio
  # segment of this phone should be a mispronunciation.
  #
  # The gop-base features are in matrix format:
  # 4446-2273-0031  [ -0.2462088 -10.20292 -11.35369 ...
  #                   -8.584108 -7.629755 -13.04877 ...
  #                   ...
  #                   ... ]
  # The number of rows is the number of phones of the utterance. In this case, it is 17.
  # The column number is 2 * (pure-phone set size), as the feature is consist of LLR + LPR.
  # The gop-base features can be used to train a classifier with human labels. See Hu's
  # paper for detail.
  # for part in $train; do
  #   $cmd JOB=1:$nj $exp/gop_$part/log/compute_gop.JOB.log \
  #     compute-gop --phone-map=$data/lang_nosp/phone-to-pure-phone.int \
  #       --skip-phones-string=0:1 \
  #       $model/final.mdl \
  #       "ark,t:gunzip -c $exp/ali_$part/ali-phone.JOB.gz|" \
  #       "ark:$exp/probs_$part/output.JOB.ark" \
  #       "ark,scp:$exp/gop_$part/gop.JOB.ark,$exp/gop_$part/gop.JOB.scp" \
  #       "ark,scp:$exp/gop_$part/feat.JOB.ark,$exp/gop_$part/feat.JOB.scp"   || exit 1;
  #     cat $exp/gop_$part/feat.*.scp > $exp/gop_$part/feat.scp
  #     cat $exp/gop_$part/gop.*.scp > $exp/gop_$part/gop.scp
  # done
   if [ $phone_gop -eq 1 ];then
   echo "stage 12 GOP computation"
   for part in $train; do
     $cmd JOB=1:$nj $exp/gop_$part/log/compute_gop.JOB.log \
       compute-gop --phone-map=$data/lang_nosp/phone-to-pure-phone.int \
         --skip-phones-string=0:1 \
         $model/final.mdl \
         "ark,t:gunzip -c $exp/ali_$part/ali-phone.JOB.gz|" \
         "ark:$exp/probs_$part/output.JOB.ark" \
         "ark,t:$exp/gop_$part/gop.JOB.txt" \
         "ark,t:$exp/gop_$part/feat.JOB.txt"  || exit 1;
       cat $exp/gop_$part/feat.*.txt > $exp/gop_$part/feat.txt
       cat $exp/gop_$part/gop.*.txt > $exp/gop_$part/gop.txt
       cp $data/lang_nosp/phones-pure.txt $exp/gop_$part/
       ./combine_gop.sh $exp/gop_$part/ phones-pure.txt gop

   done
   fi
  # Use word alignment to get word level GOP
  for part in $train; do
      echo "Computing word level GOP scores from $part"
    $cmd JOB=1:$nj $exp/gop_$part/log/compute_gop_word.JOB.log \
      compute-gop-word --phone-map=$data/lang_nosp/phone-to-pure-phone.int \
      --skip-phones-string=0:1 \
      --word-map=$data/lang_nosp/words-pure.int \
      --skip-words-string=0:1 \
        $model/final.mdl \
        "ark,t:gunzip -c $exp/ali_$part/ali-phone.JOB.gz|" \
        "ark,t:gunzip -c $exp/ali_$part/ali-word.JOB.gz|" \
        "ark:$exp/probs_$part/output.JOB.ark" \
        "ark,t:$exp/gop_$part/gop_phone.JOB.txt" \
        "ark,t:$exp/gop_$part/gop_word.JOB.txt" \
        "ark,t:$exp/gop_$part/gop_spot.JOB.txt" \
        "ark,t:$exp/gop_$part/feat_word.JOB.txt"\
        "ark,t:$exp/gop_$part/ali_frame.JOB.txt"\
        "ark,t:$exp/gop_$part/act_ali_frame.JOB.txt"  || exit 1;
      cat $exp/gop_$part/feat_word.*.txt > $exp/gop_$part/feat_word.txt
      cat $exp/gop_$part/gop_word.*.txt > $exp/gop_$part/gop_word.txt
      cat $exp/gop_$part/gop_spot.*.txt > $exp/gop_$part/gop_spot.txt
      cat $exp/gop_$part/gop_phone.*.txt > $exp/gop_$part/gop_phone.txt
      cat $exp/gop_$part/ali_frame.*.txt > $exp/gop_$part/ali_frame.txt
      cat $exp/gop_$part/act_ali_frame.*.txt > $exp/gop_$part/act_ali_frame.txt
  
  ## LLR Compute 
  # for part in $train; do
  #     echo "Computing word level LLR scores from $part"
  #   $cmd JOB=1:$nj $exp/gop_$part/log/compute_gop_word.JOB.log \
  #     compute-llr --phone-map=$data/lang_nosp/phone-to-pure-phone.int \
  #     --skip-phones-string=0:1 \
  #     --word-map=$data/lang_nosp/words-pure.int \
  #     --skip-words-string=0:1 \
  #       $model/final.mdl \
  #       "ark,t:gunzip -c $exp/ali_$part/ali-phone.JOB.gz|" \
  #       "ark,t:bg_ali/ali.JOB.txt" \
  #       "ark,t:gunzip -c $exp/ali_$part/ali-word.JOB.gz|" \
  #       "ark:$exp/probs_$part/output.JOB.ark" \
  #       "ark,t:$exp/gop_$part/gop_phone.JOB.txt" \
  #       "ark,t:$exp/gop_$part/gop_word.JOB.txt" \
  #       "ark,t:$exp/gop_$part/gop_spot.JOB.txt" \
  #       "ark,t:$exp/gop_$part/feat_word.JOB.txt"\
  #       "ark,t:$exp/gop_$part/ali_frame.JOB.txt"\
  #       "ark,t:$exp/gop_$part/act_ali_frame.JOB.txt"  || exit 1;
  #     cat $exp/gop_$part/feat_word.*.txt > $exp/gop_$part/feat_word.txt
  #     cat $exp/gop_$part/gop_word.*.txt > $exp/gop_$part/gop_word.txt
  #     cat $exp/gop_$part/gop_spot.*.txt > $exp/gop_$part/gop_spot.txt
  #     cat $exp/gop_$part/gop_phone.*.txt > $exp/gop_$part/gop_phone.txt
  #     cat $exp/gop_$part/ali_frame.*.txt > $exp/gop_$part/ali_frame.txt
  #     cat $exp/gop_$part/act_ali_frame.*.txt > $exp/gop_$part/act_ali_frame.txt
  


  cp $data/lang_nosp/words.txt $exp/gop_$part/
  cp $data/lang_nosp/phones-pure.txt $exp/gop_$part/
  ./combine_gop.sh $exp/gop_$part/ words.txt gop_word
  ./combine_gop_two_phone.sh $exp/gop_$part/ phones-pure.txt _phone
  ./combine_gop.sh $exp/gop_$part/ words.txt gop_spot
  ./combine_gop.sh $exp/gop_$part/ phones-pure.txt ali_frame
  ./combine_gop.sh $exp/gop_$part/ phones-pure.txt act_ali_frame

  echo "Computed word level GOP scores and saved to $exp/gop_$part"
  echo "In align_frame.*.txt: | indicates change in phone, ||| indicates change in word"
    done




fi

exit 0
local/check_dependencies.sh   || exit 1;
if [ $stage -le 13 ]; then
  # Visualize the GOP-based features for the training set
  python3 local/visualize_feats.py \
            --phone-symbol-table $data/lang_nosp/phones-pure.txt \
            $exp/gop_$train/feat.scp $data/local/scores.json \
            $exp/gop_$train/feats.png
  echo The features are visualized and saved in $exp/gop_train/feats.png
fi

if [ $stage -le 14 ]; then
  # Phone-level scoring
  for input in gop feat; do
    python3 local/${input}_to_score_train.py \
              --phone-symbol-table $data/lang_nosp/phones-pure.txt \
              --nj $nj \
              $exp/gop_$train/${input}.scp \
              $data/local/scores.json \
              $exp/gop_$train/model_${input}

    python3 local/${input}_to_score_eval.py \
              $exp/gop_train/model_${input} \
              $exp/gop_test/${input}.scp \
              $exp/gop_test/predicted_${input}.txt
    
    python3 local/print_predicted_result.py \
              --phone-symbol-table $data/lang_nosp/phones-pure.txt \
              --write $exp/gop_test/result_${input}.int \
              $data/local/scores.json \
              $exp/gop_test/predicted_${input}.txt

    utils/int2sym.pl -f 2 $data/lang_nosp/phones-pure.txt \
        $exp/gop_test/result_${input}.int > $exp/gop_test/result_${input}.txt
  done
fi
