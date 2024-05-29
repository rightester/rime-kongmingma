
import os

projection_prefferred_delimiters = ('/', '|', '=', ' ')

left_sort  = "qazwsxedcrfvtgb12345"
right_sort = "yhnujmik,ol.p;/67890"
space_sort = "'=[`\- ]"
chord_composer_sort = left_sort + right_sort + space_sort

space_sort_help_msg = """
请输入要使用的空格，注意按键盘上从左到右的顺序来排列，
只支持普通字符键如 '、-、=、` 等（注意用按Shift出的不是键）
不支持特殊键如Ctrl、Alt、Win、Shift等
例：
只使用空格键作为空格：直接输入一个空格键后回车
空格使用引号和空格键，引号在左手：先输入引号、空格，回车
"""

map1 = str.maketrans({
	';': 'A',
	',': 'C',
	'.': 'X',
	'/': 'Z',
	'!': '>',
	'_': '!',
})

def chord_sort(zf, order):
	r = []
	for c in order:
		count = zf.count(c)
		r.append(c*count)
	return ''.join(r)

def process_file(file):
	dst_file = '_' + '.'.join(file.split('.')[:-1]) + '.yaml'
	file = open(file, 'r', encoding='utf-8')
	zf_map = []
	for line in file:
		line = line.strip().strip('\ufeff')
		s = line.split('=')[:2]
		print(s)
		zf_map.append(s)
	__________________________a = input('')
	with open(dst_file, 'w', encoding='utf-8') as dst_file:
		dst_file.write("# encoding: utf-8\n\nchord_composer:\n  algebra:\n")
		for zf, v in zf_map:
			zf = zf.translate(map1)
			zf = chord_sort(zf, chord_composer_sort)
			delim = ''
			for d in projection_prefferred_delimiters:
				if (not d in zf) and (not d in v):
					delim = d
					break
			dst_file.write(
				"    - xform{delim}<{zf}>{delim}{v}{delim}\n".format(
					delim = delim,
					zf = zf,
					v = v,
			))

def main():
	print(space_sort_help_msg)
	s = input("请输入要使用的空格键排序：")
	if bool(s):
		space_sort = s
#	过滤掉py脚本自身
	ff = filter(lambda x: x.endswith('.txt'), os.listdir())
	for f in ff:
		process_file(f)
		break

if __name__ == '__main__':
	main()