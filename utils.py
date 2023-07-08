#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jul 25 15:22:16 2022

@author: saketh
"""
import argparse
import re

def remove_last_underscore(text:str):
    if text.strip()[-2]=='_':
        text = text.strip()[:-2]
    return text.strip()

def write_phone_ctm(ctm:str):
    with open(ctm,'r') as fp:
        phone_ctm = fp.readlines()
    phone_ctm = list(map(remove_last_underscore, phone_ctm))
    with open(ctm,'w') as fp:
        for line in phone_ctm:
            fp.write(line+'\n')

def phone_seq_to_word_seq(decoded_file_path:str, lex_path:str):
	"""
	Converts phone sequence like 'AA_B R_E F_B AW_I N_I D_E' to 'AA_R F_AW_N_D'
	Also creates a lexicon for each word
	
	"""
	with open(decoded_file_path,'r') as fp:
		phone_decoded = fp.readlines()
	phone_dec = []
	modified_file = []
	count=0
	for line in phone_decoded:
		line = line.strip().split()
		file_name = line[0]
		modified_file.append([file_name])
		modified_line = []
		for char in line:
			if char.endswith('_B') or char.endswith('_S'):
				word = char.split('_')[0]
				if char.endswith('_S') and len(word)>0:
					modified_line.append(word)
					if word not in phone_dec:
						phone_dec.append(word)
					
			elif char.endswith('_I') or char.endswith('_E'):
				word += '_' + char.split('_')[0]
				if char.endswith('_E'):
					modified_line.append(word)
					if word not in phone_dec:
						phone_dec.append(word)
		modified_file[count]+=modified_line
		count+=1
	with open(f'{lex_path}/dec.txt','w') as fp:
		for line in modified_file:
			file_name = line[0]
			line = ' '.join(line[1:])
			fp.write(f'{file_name}\t{line}\n')
	with open(f'{lex_path}/phone_lexicon.txt','w') as fp:
		phone_seq = [x.replace('_', ' ') for x in phone_dec]
		phone_tuple = list(zip(phone_dec, phone_seq))
		for line in phone_tuple:
			fp.write(line[0]+'\t'+line[1]+'\n')
	pass

def phone_ctm2phone_text(ctm_path:str):
    """
    Converts phone level ctm to phone level text in the format required by GOP calculator in kaldi
    Ex: 
    [Utt_id].{word_count} phone_context
    1358_HI_S4_WD_1.0 s_B o_I c_E
    1358_HI_S4_WD_2.1 t_B aa_I l_E
    """
    with open(ctm_path,'r') as fp:
        phone_ctm = fp.readlines()
    phone_ctm = list(map(lambda x:x.strip(), phone_ctm))
    file_name = sorted(list(set(map(lambda x:x.split()[0], phone_ctm))))
    phone_text=[]
    for name in file_name:
        count=0
        utt = list(filter(lambda x:x.split()[0]==name and x.split()[-1]!="SIL", phone_ctm))
        for x in utt:
            if x[-1] == 'S':
                phone_text.append(f"{name}.{count} {x.split()[-1]}\n")
                count+=1
            elif x[-1]=='E':
                phone_text.append(f" {x.split()[-1]}\n")
                count+=1
            elif x[-1]=='B':
                phone_text.append(f"{name}.{count} {x.split()[-1]}")
            else:
                phone_text.append(f" {x.split()[-1]}")
    with open("data/local/text-phone",'w') as fp:
        fp.writelines(phone_text)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Removes phone markers. Ex: AE_B -> AE, EH_S -> EH ",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('phone_ctm',type=str, 
                        help="Path to phone level ctm in kaldi format")
    
    args = parser.parse_args()
    write_phone_ctm(args.phone_ctm)
    #phone_ctm2phone_text(args.phone_ctm)




