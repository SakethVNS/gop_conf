#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Sep 23 16:18:09 2022

@author: saketh
"""
import os
import sys
import glob

def ali_word_gz(path:str):
	ali_names = glob.glob(path+'/aligned_words.*.gz')
	for ali_file in ali_names:
		file_count = ali_file[-4]
		ali_name = ali_file[:-2]+'txt'
		os.system(f'gzip -cd {ali_file} > {ali_name}')
		with open(ali_name,'r') as fp:
			ali_1 = fp.readlines()
		
		ali_name = path+f'/ali-word.{file_count}'
		fp = open(ali_name,'w')
		for i,line in enumerate(ali_1):
			line = line.strip().split()
			if len(line)==1:
				name=line[0]
				if len(name)>3:
					fp.write(f'\n{name}')
			elif len(line)==0:
				continue
			else:
				word_id = line[2]
				count = len(line[3].split(',')[-1].split('_'))
				if (word_id=='0'):
					word_id='1'
				word_string = ((word_id+' ')*count).strip()
				fp.write(f' {word_string}')
		
		
		fp.close()
		os.system(f'sed -i 1d {ali_name}')
		os.system(f'gzip -c {ali_name} > {ali_name}.gz')


if __name__ == '__main__':
	assert len(sys.argv)==2, "Usage: ali-word-converter.py [path_to_ali-phone]"
	ali_path = sys.argv[1]
	ali_word_gz(ali_path)