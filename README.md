Obtain phone level and word level GOP scores
Usage:
	use run.sh to get GOP from chain models
	use run_nnet3.sh to get GOP from non chain models
	
	Eg: ./run_nnet3.sh --stage 3
	If code exits at any stage you can debug and resume from that stage
	
	All parameters are defined inside the "run" file
	Files/paths needed to run the script(run.sh) are
		tdnn_model
		ivector path
		dictionary path
		data dir path

Outputs: 
Inside the tdnn directory following folders will be created
tdnn/ali_${data_dir_path}
tdnn/probs_${data_dir_path}
tdnn/gop_${data_dir_path}

The gop related files are created inside tdnn/gop_${data_dir_path} 

For confidence scoring related features go to LRT folder and look at README.md in that folder


