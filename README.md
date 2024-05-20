# 空明码并击
空明码的Rime方案，可以从速录宝平台迁移，kongmingma_chord.schema.yaml可用于桌面端Rime发行版和同文/中文（外接键盘）；触屏可考虑使用kmm.schema.yaml，配合.trime.yaml键盘面板。

相比速录宝，由于Rime限制，目前需要特别对Rime拓展才能实现的是`向系统重发送按键`，受影响功能包括：并击发送退格/上下左右HomeEnd等任何需要模拟按键而不是发送文本的功能



# TODO
- [x] ~~加入四码上屏功能，使用lua_filter筛候选项配合auto_select=true，将多个候选根据条件滤除至仅剩一个实现任意情况下可强制上屏~~
- [x] 分割词典，避免某处小改动就要将整个词典重新编译一遍，浪费时间和硬盘读写寿命（并完成遍历分词典反查）
- [ ] **搞定指法与配置文件分离**，脚本处理速录宝的指法文件配合YAML编译自动整合进kongmingma_chord.schema.yaml  Rime的YAML编译指令的功能：[在 YAML 語法的基礎上，增設以下編譯指令...](https://github.com/rime/home/wiki/Configuration#%E9%85%8D%E7%BD%AE%E7%B7%A8%E8%AD%AF%E5%99%A8%E6%8F%92%E4%BB%B6)
- [ ] 在实现四码上屏的同时，实现能够，通过击键组合，阻止上屏并继续输入（长词句等）
- [x] 功能2 完成的分词典功能处理不当导致了新的问题，原有码表的排序没有被保留，尤其是有些4字词在3字词或2字词前的情况，需要修复（移植MasterDit.shp）
- [x] ~~修复利用Processor的commit等的强制上屏和等等，重新设计编码方式和处理方式~~ ~~改进editor和selector的功能~~ 通过并击命令处理的方式实现上屏控制(功能3)
- [x] lua_processor实现chord_composer的抬指立即释放的版本（librime>=1.10.0开始内置了此功能，可以不用插件）
- [x] one.shp移植转换
- [ ] 并击顶屏控制，使用handler来完成，不依赖speller/auto_select: true
- [ ] 优化多个translator配置在方案中的写法，考虑在lua中动态传递处理配置而不是堆在.schema.yaml中
- [ ] 并击击速、键速、输入速度统计
- [ ] 退格一键回退一击的编码
- [ ] 无编码时退格一键可选：回退上一击字数退格/发送Ctrl+Z
- [ ] 扩展Rime，支持向系统重发送按键，实现外部光标/模拟按键操作
- [ ] 引入全拼（雾凇拼音），作为默认反查方案和备选输入方案（目前是自用的轻量小鹤音形方案和词库）
- [ ] 速录宝用户词库迁移 (?
- [ ] 移植py脚本至Rust，使得用户可以双击执行
- [ ] 用户初始化方案提示/lua调用确保初始化，初始化自动判断`MasterDict, one.shp, 指法文件, 速录宝用户词典`是否变化并按需更新Rime对应文件

  ……
---

