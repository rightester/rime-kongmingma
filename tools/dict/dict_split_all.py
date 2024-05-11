import sys
import re
import time


原文件 = "kongmingma.dict.yaml"

f01 = "kongmingma_part01"
# 单字

f02 = "kongmingma_part02"
# 简词

f03 = "kongmingma_part03"
# 普通词语

f04 = "kongmingma_part04"
# 四字词, 4码

f06 = "kongmingma_part06"
# 更多字的短语和词
# 五个字及以上，4码及以上

版本 = time.strftime("%Y%m%d", time.localtime())



yaml_header = """\
# Rime dictionary
# encoding: utf-8
# 空明码词典

---
name: {dict_name}
version: {version}
sort: original
use_preset_vocabulary: false
...

"""


def yaml_dict_open(dict_name):
	f = open(dict_name+".dict.yaml", 'w', encoding="utf-8")
	f.write(yaml_header.format(dict_name=dict_name, version=版本))
	return f







mapping = {
"%": '6',
"~": '7',
"@": '8',
"*": '9',
"&": '0',
}


def dispatch_line(line):
	result = ""
	line_split_lst = line.split('\t')
	try:
		char = line_split_lst[0]
		code = line_split_lst[1][:-1]
	except:
		return
	if len(code) < 1:
		return
	if code[0] in "%~@*&":
		code = code.translate(str.maketrans(mapping))
	
	if len(char)==1:
		f1.write(line)
		#单字
	else:
		if len(code)<3:
			f2.write(line)
		elif len(code)<4:
			f2.write(line)
		elif len(code)<5 and len(char)<4:
			f2.write(line)
		elif len(code)<5 and len(char)<5:
			f3.write(line)
		elif len(code)<7 and 4<len(char)<7:
			f4.write(line)
		else:
			f6.write(line)



if __name__ == "__main__":

	f0 = open(原文件, 'r', encoding="utf-8")
	f1 = yaml_dict_open(f01)
	f2 = yaml_dict_open(f02)
	f3 = yaml_dict_open(f03)
	f4 = yaml_dict_open(f04)
#	f5 = yaml_dict_open(f05)
	f6 = yaml_dict_open(f06)


	for line in f0:
#		print(line)
		line = line.replace("\ufeff",'')
		#.replace("\n",'')
		dispatch_line(line)
#		result = dispatch_line(line)
#		fo.write(result)
#		print(result)
#		input()


	f0.close()
	f1.close()
	f2.close()
	f3.close()
	f4.close()
#	f5.close()
	f6.close()
	












#拆分掉
# ([A-z0-9,./;<!?:%@&~*]+)
# ([\u2E80-\u4E00] ){33}

