#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Sep  4 20:47:14 2022

@author: saketh
"""
import sys
from collections import defaultdict
import pandas as pd
import logging
import os
import argparse

sausage_dict = defaultdict(list)

def sausage2dict(sausage_file:str)->dict:
	with open(sausage_file,'r') as fp:
		sausage_text = fp.readlines()
		
	for line in sausage_text:
		if line[0].isdigit():
			name=line.strip()
		else:
			if name not in sausage_dict:
				sausage_dict[name].append(line.strip().split())

def obtain_LRT_decision(sausage_file,canonical,utt,correct_threshold=1.5,incorrect_threshold=0.2):
	sausage2dict(sausage_file)
	if len(sausage_dict[utt])==0:
		Decision=f"No decoding for {utt}"
		logging.warning(Decision)
		print(Decision)
		return [Decision, -1]
	idx = [x.index(canonical)+1 if canonical in x else -1 for x in sausage_dict[utt]]
	conf_all = [float(x[i]) if i!=-1 else -1 for i,x in zip(idx,sausage_dict[utt])]
	max_conf_idx = conf_all.index(max(conf_all))
	
	if max(conf_all)>0:
		if idx[max_conf_idx]==1:
			second_max = 3
		else:
			second_max = 1
		try:
			LRT = [sausage_dict[utt][max_conf_idx][idx[max_conf_idx]], sausage_dict[utt][max_conf_idx][second_max]]
			LRT = round(float(LRT[0])/float(LRT[1]),3)
			if LRT>10:
				LRT=10.0
		except IndexError:
			LRT = 10.0
		if LRT<=incorrect_threshold:
			Decision='Incorrect'
			logging.info(f"Incorrect: LRT:{LRT}, {utt}: canonical:{canonical}, decoded:{sausage_dict[utt]}")
		elif LRT>=correct_threshold:
			Decision='Correct'
			logging.info(f"Correct: LRT:{LRT}, {utt}: canonical:{canonical}, decoded:{sausage_dict[utt]}")
		else:
			Decision='Repeat'
			logging.info(f"Repeat: LRT:{LRT}, {utt}: canonical:{canonical}, decoded:{sausage_dict[utt]}")
	else:
		Decision='Incorrect'
		LRT = 0.0
		logging.info(f"Incorrect: LRT:{LRT}, {utt}: canonical:{canonical}, decoded:{sausage_dict[utt]}")
	
	print(f"{Decision}, LRT:{LRT}, Canonical:{canonical}, decoded:{list(map(lambda x:x[0],sausage_dict[utt]))}")
	return [Decision, LRT]

def getLRTConfidenceValue(lattice_path:str,canonical_text:str,utterance_id:str)->[str,float]:
	"""
	Parameters
	----------
	lattice_path : str
		Path to lattice directory. Before running this run lat2sausage.sh file to obtain sausage text files
	canonical_text : str
		Canonical Utterance to be read.
	utterance_id : str
		Utterance ID corresponding to Canonical.

	Returns
	-------
	[str,float]
		Decision(str): 
			Correct, means decoder is confident that the output is correct.
			Incorrect, means decoder is confident that output is incorrect.
			Repeat, means decoder is not confident of the output
		LRT(float):
			Value of LRT>=0.0 for valid utterances else -1 for no decoder output utterances
			
	"""
	
	sausage_path = os.path.join(lattice_path,'ctm/sausage_with_symbols.txt')
	if not os.path.exists(sausage_path):
		print("Run lat2sausage.sh file first and then run this file")
		sys.exit(1)
	try:
		os.remove(f"{os.path.dirname(sausage_path)}/confidence.log")
	except OSError:
		pass
	logging.basicConfig(filename = f"{os.path.dirname(sausage_path)}/confidence.log", level=logging.INFO, format='%(levelname)s: %(message)s')
	[Decision,LRT] = obtain_LRT_decision(sausage_path,canonical_text,utterance_id)
	return Decision,LRT
	
if __name__ == '__main__':
	
	parser = argparse.ArgumentParser(
		description="Uses created Sausage file and gets correct/incorrect/repeat decision using LRT scores",
		formatter_class=argparse.ArgumentDefaultsHelpFormatter)
	parser.add_argument('lattice_path', type=str,
						 help="Path to the Decode directory containing lat.*gz files")
	parser.add_argument('canonical', type=str,
						 help="Canonical string corresponding to the utterance")
	parser.add_argument('utterance', type=str,
						 help="Utterance ID corresponding to the utterance")
	parser.add_argument('--correct_threshold',type=float,
						 help="Any utterance with LRT above correct threshold is correct utterance", default=1.5)
	parser.add_argument('--incorrect_threshold',type=float,
						 help="Any utterance with LRT below incorrect threshold is correct utterance", default=0.2)
	
	args = parser.parse_args()
	lattice_path = args.lattice_path
	sausage_file = os.path.join(lattice_path,'ctm/sausage_with_symbols.txt')
	try:
		os.remove(f"{os.path.dirname(sausage_file)}/confidence.log")
	except OSError:
		pass
	logging.basicConfig(filename = f"{os.path.dirname(lattice_path)}/ctm/confidence.log", level=logging.INFO, format='%(levelname)s: %(message)s')
	canonical = args.canonical
	utterance = args.utterance
	
	
	[Decision,LRT] = getLRTConfidenceValue(lattice_path,canonical,utterance)




