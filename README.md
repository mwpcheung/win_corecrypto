# corecrypto for windows
    corecryto from [corecrypto](https://github.com/samdmarshall/apple-corecrypto)
    apple's corecrypto is very powerful,and not directly open source. according to apple's words, they said Although corecrypto   does not directly provide programming interfaces for developers. no API, any source ? It's very very like opensl/fips.
  
# Diff
##  1. remove OS X gcd function calls like
    1.dispatch_async(get_queue_main()^(){...});
    2.dispatch_once(...);
    I don't know how the Apple's gcd function works. On windows Environment, u'd better use winmmi API waking up your callbacks. and injecting your code to another thread is more hard. MicroSoft never provide APC programming in UserMode. May be hooking windows ntdll sysenter and call your callback functions. ohter
    wise fucking the Windows iTunes is the best way
## 2. fast AES
    I only complied the pure c AES.
## 3. cccurve25519 or cced25519
    Apple's UserMode corecrypto uses cced25519 libs, cccurve25519 for KernelMode. I've never get the definition of cccurve25519 privatekey.
## 4. Apple SEPRom
    Apple SEP ROM is a hardware Embedded On your iPhone. It provides ecdsa, aes ...  this project closed it.
## 5. cc_config.h
    Checking your config for yourself.
  
  
 







