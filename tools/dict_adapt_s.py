import sys
import re
import time


原文件 = "MasterDit.shp"


输出词典名 = "kongmingma"
if len(sys.argv) > 1:
	输出词典名 = sys.argv[1]

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
	'!':'>',
}


def process_line(line):
	result = ""
	lst = line.split(" ")
#	print(lst)
	code = lst.pop(0)
#	print(code)
	code = code.translate(str.maketrans(mapping))
	if len(code)>4:
		return
	if len(code)%2==1:
#		code += '_'
		pass
#	print(code)
	for i in range(0,len(lst)):
		result += "{chars}\t{code}\n".format(code=code,chars=lst[i])
#		print(result)
#	result = result[:-1]
#	print(result)
	return result




if __name__ == "__main__":

	f1 = open(原文件, 'r', encoding="utf-8")
	fo = yaml_dict_open(输出词典名)


	for line in f1:
#		print(line)
		line = line.replace("\ufeff",'').replace("\n",'')
		result = process_line(line)
		if bool(result):
			fo.write(result)
#		print(result)
#		input()


	f1.close()
	fo.close()








