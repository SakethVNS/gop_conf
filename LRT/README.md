Obtain Word level confidence using LRT and sausage file to accept/reject the spoken utterance
Usage:
	The file lat2sausage.sh needs to be present inside kaldi folder, The decode folder to be present inside the model(exp/chain/tdnn) directory
	Graph directory is needed to give words.txt file. Name of graph directory is graph_story_name. This directory is present in exp/chain/tree/ or exp/chain/tree_a_sp/
	./lat2sausage.sh [lattice_directory_path]
    Other parameters are to be specified inside lrt_config.ini

lrt_config.ini(Parameters):
    correct_threshold: Above which utterance is treated as correct
    incorrect_threshold: Below which utterance is treated as incorrect
    lmwt and wip: These are used to weight lattice to obtain alternate hypothesis in the form of sausage
    utterance: Utterance ID 
    canonical: canonical text corresponding to Utterance ID
    

Usage for get_conf_lrt.py:
	Uses obtained sausage files to obtain decision of acceptance or rejection using the thresholds from the config file
	This script is internally called in lat2sausage.sh
	Use: "python get_conf_lrt.py -h" to see the parameter details


