# 空明码并击
空明码的Rime方案

目前已经做得差不多了，然后发现版本分叉太多了，管理极为麻烦，急需使用版本管理工具来保证各自互不干扰
也试一下Git的用法，实践一下比看多少教程都来得深刻。

目前主要有三个版本：
  - 标准键盘指法，标准无魔改的空明码方案
  - 齐列键盘指法，标准无魔改的空明码方案
  - 齐列键盘指法，逐渐魔改的空明码方案
~~...~~
更，我好像找到了办法了，原来Rime是有这块的功能的：[在 YAML 語法的基礎上，增設以下編譯指令...](https://github.com/rime/home/wiki/Configuration#%E9%85%8D%E7%BD%AE%E7%B7%A8%E8%AD%AF%E5%99%A8%E6%8F%92%E4%BB%B6)


# TODO
- [x] 加入四码上屏功能，使用lua_filter筛候选项配合auto_select=true，将多个候选根据条件滤除至仅剩一个实现任意情况下可强制上屏
- [x] 分割词典，避免某处小改动就要将整个词典重新编译一遍，浪费时间和硬盘读写寿命（并完成了遍历分词典反查）
- [ ] **搞定指法与配置文件分离**
- [ ] 在实现四码上屏的同时，实现能够，通过击键组合，阻止上屏并继续输入（长词句等）
- [ ] 第二项完成的分词典功能导致了新的问题，原有码表的排序没有被保留，尤其是有些4字词在3字词或2字词前的情况，直接麻了，需要重新修复，需要了解码表格式，尝试利用好词典的权重等进行排序（重写分割词典的py脚本，单手击字、符号、i码、单字、词）（词分割注意，首先根据这个音起头的词排，如果起头的词已经排到后面，那么后面的词哪怕是简词，也要跟着前面的走）（或者说，不再是“派发”模式了，而是以编码条项为单位的串行模式。一个编码内的内容都得在一起走）
- [ ] ~~修复利用Processor的commit等的强制上屏和等等，重新设计编码方式和处理方式~~改进editor和selector的功能
- [x] lua_processor实现chord_composer的抬指立即释放的版本（librime>=1.10.0开始内置了此功能，可以不用插件）

  ……
---

