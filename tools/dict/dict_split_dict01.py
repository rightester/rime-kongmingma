

原 = "kongmingma_part01.dict.yaml"
# 就是单字
# 特征是 上屏内容只有一个字


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

symbols_str = """
‘’`~_+'《》～：~‰@％#℃$°】［[｛{］]｝}（）！”’“‘·？【※∶√”⿰⿱⿲⿳⿴⿵⿶⿷⿸⿹⿺⿻
""".replace('\n','')

def dispatch_line(line):
	result = ""
	line_split_lst = line.split('\t')
	char = line_split_lst[0]
	code = line_split_lst[1][:-1]
	if len(code)==2 and ('_' in code or code.startswith('a') or False):
		f00.write(line)
	elif code.startswith('i'):
		fii.write(line)
	elif len(code)==2 and code[0] in "viuVIoE;,./:<>?1234567890":
		if char in symbols_str:
			fsym.write(line)
		else:
			f03.write(line)
	elif len(code)==2:
		f01.write(line)
	else:
		f02.write(line)
	
	
def yaml_dict_open(dict_name):
	f = open(dict_name+".dict.yaml", 'w', encoding="utf-8")
	f.write(yaml_header.format(dict_name=dict_name, version=版本))
	return f


if __name__ == "__main__":
	
	f0 = open(原, 'r', encoding="utf-8")
	f00 = yaml_dict_open("kongmingma_part01_00")
	fii = yaml_dict_open("kongmingma_part01_ii")
	f01 = yaml_dict_open("kongmingma_part01_01")
	fsym = yaml_dict_open("kongmingma_part01_symbols")
	f02 = yaml_dict_open("kongmingma_part01_02")
	f03 = yaml_dict_open("kongmingma_part01_00")
	

	flag = False
	for line in f0:
#		print(line)
		line = line.replace("\ufeff",'')
		if (not flag) and line.startswith("..."):
			flag = True
			continue
		if line=='\n':
			continue
		if flag:
			dispatch_line(line)


	f0.close()
	fii.close()
	f00.close()
	f01.close()
	f02.close()
	f03.close()






