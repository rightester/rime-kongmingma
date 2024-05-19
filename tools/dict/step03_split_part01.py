
import re
import time
import os
from pathlib import Path

output_dir = Path(".\output")

src_dict_id = "kongmingma_part01"

dict_levels = ["char", "ii", "sym"]
dst_dict_pattern = "kongmingma_part01_{}"
phony_schema_pattern = "phony_{}"

'''
编码小于4：
	char 纯单字，包含简码
	ii i码反查
	sym 符号
'''
def decide_level(code, cand):
	len_code = len(code.replace('_', ''))
	len_cand = len(cand)
	if len_code>1 and code.startswith('i'):
		return 1
	if len_code==1 and len_cand==1:
		return 999
	if len_code>1 and len_cand==1 and re.match(r"[A-z\u2E80-\u9FFF]", cand): # 还要再加上汉字增补区
		return 0
	else:
		return 2


time_version = time.strftime("%Y%m%d", time.localtime())


dict_yaml_header = """\
# Rime dictionary
# encoding: utf-8
# 空明码词典

---
name: {dict_id}
version: {version}
sort: original
use_preset_vocabulary: false
...

"""

schema_yaml_header = """\
# Rime schema
# encoding: utf-8

schema:
  schema_id: {schema_id}
  name: {name}
  description: {description}

engine:
  translators:
    - table_translator

translator:
  dictionary: {dict_id}
  enable_user_dict: false
  enable_sentence: false
  enable_encoder: false
"""

def make_phony_schema(dict_id):
	schema_id = phony_schema_pattern.format(dict_id)
	schema_name = schema_id + ".schema.yaml"
	f = open(schema_name, 'w', encoding="utf-8")
	f.write(schema_yaml_header.format(
		schema_id = schema_id,
		dict_id = dict_id,
		name = "伪方案 "+dict_id,
		description = "用于词典部署",
	))

def dict_yaml_open_w(dict_id, make_phony=True):
	dict_name = dict_id + ".dict.yaml"
	f = open(dict_name, 'w', encoding="utf-8")
	f.write(dict_yaml_header.format(dict_id=dict_id, version=time_version))
	if make_phony:
		make_phony_schema(dict_id)
	return f


mapping = str.maketrans({
	'!':'>',
	'_':'!',
})
def translate_code(code):
	return code.translate(mapping)

def process_cands(code, cands, dst_files):
	level = 0
	for cand in cands:
		level = max(level, decide_level(code, cand))
		if not level in range(len(dst_files)):
			return
		if f:=dst_files[level]:
			temp_code = code
#			temp_code = translate_code(temp_code)
#			temp_code = temp_code + '_' if len(temp_code)%2 else temp_code
			f.write(cand+'\t'+temp_code+'\n')

def process_file(f_src, f_dsts):
	prev_code = ''
	prev_cands = []
	f_src_iter = iter(f_src)
	try:
		while not next(f_src_iter).startswith('...'):
			continue
		while True:
			line = next(f_src_iter)
			if '\t' in line:
				line[:-1]
				break
	except StopIteration:
		pass
	for line in f_src_iter:
		line = line[:-1]
		cand, code = line.split('\t')[:2]
		if code==prev_code:
			prev_cands.append(cand)
		else:
			process_cands(prev_code, prev_cands, f_dsts)
			prev_code = code
			prev_cands.clear()
			prev_cands.append(cand)


def main():
	if not os.path.exists(output_dir):
		return
	os.chdir(output_dir)
	with open(src_dict_id+'.dict.yaml', 'r', encoding='utf-8') as src_dict_file:
		dst_dict_files = list(map(
			lambda x: dict_yaml_open_w(dst_dict_pattern.format(x)) if x else None,
			dict_levels
		))
		
		process_file(src_dict_file, dst_dict_files)
		
		map(lambda x: x.close() if x else None, dst_dict_files)
	
	os.remove(src_dict_id + ".dict.yaml")
	os.remove("phony_kongmingma_part01.schema.yaml")
	os.chdir("..")


if __name__ == "__main__":
	main()





