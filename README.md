# win_corecrypto
corecrypto for windows

corecryto from git@github.com:samdmarshall/apple-corecrypto.git

corecrypto 是苹果系统下 libcommoncrypto 模块的源码。 该模块对openssl做了一些改装
同时按照苹果的说法是更加的安全。 
非常遗憾这个模块没有提供标准的makefile。 
corecrypto 目录结构比较简单粗暴
root
  ccalg1
  ccalg2
  ....
  
 ccAlg = cc 加密算法名称
   corecrypto - 该模块的头文件
   src - 该模块的实现
   crypto_test - 该模块的测试文件
 每个模块都按照这种结构组织。 其中AES和其他几个算法又包含汇编实现。 所有涉及汇编的代码， 该风格不是winvc汇编风格。暂不知道怎么让vc也能编译。
 
  ccder 模块
    这个模块非常有意思， iOS apticket.der文件使用了该算法。 https://www.theiphonewiki.com/wiki/APTicket
  ccpbkdf2
    这个模块是srp协议中处理aes_cbc_mode 加密解密用。 用于apple 解密spd 字段，获取二级服务授权token使用。
  ccsrp 模块
   这个模块也是非常有意思的。 苹果在iOS10系统中，为了更安全的登录，采用SRP-6a 版本用作登录密码认证。
   Authkit 模块在与apple login server交换密钥时使用了这个srp协议。
  
 新的代码层级:
  corecrypto
     xxx.h
     将所有的头文件统一放到corecrypto目录
  src
    ccAlg1
    ccAlg2
    将所有加密算法实现移到src/alg/source1.c src/alg/source2.c ...etc 
   创建了一个vc2015项目用于管理所有源码。 因苹果源码使用clang 比较标准的gcc编译器编译， 向vc的移植还未成功.
   
   mwpcheung
   2018-02-21
