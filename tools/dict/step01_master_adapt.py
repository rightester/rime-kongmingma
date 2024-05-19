# 词典适配，保留原样内容，输出Rime词典格式

import re
import time
import os
from pathlib import Path

output_dir = Path(".\output")

src_fn = "MasterDit.shp"

dst_id = "kmm"

version = time.strftime("%Y%m%d", time.localtime())

phony_schema_pattern = "phony_{}"

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
	f.write(dict_yaml_header.format(dict_id=dict_id, version=version))
	if make_phony:
		make_phony_schema(dict_id)
	return f

def process_line(line):
	result = ""
	lst = line.split(" ")
	code = lst.pop(0)
	for i in range(len(lst)):
		result += "{chars}\t{code}\n".format(code=code,chars=lst[i])
	return result


def main():
	if not os.path.exists(output_dir):
		os.mkdir(output_dir)
	with open(src_fn, 'r', encoding="utf-8") as src_f:
		os.chdir(output_dir)
		dst_f = dict_yaml_open_w(dst_id, make_phony=False)
		for line in src_f:
			line = line.replace("\ufeff",'').replace("\n",'')
			result = process_line(line)
			if bool(result):
				dst_f.write(result)
		dst_f.close()
	os.chdir("..")


if __name__ == "__main__":
	main()
