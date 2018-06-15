# corecrypto for windows
    corecryto from [corecrypto](https://github.com/samdmarshall/apple-corecrypto)
    apple's corecrypto is very powerful,and not directly open source. according to apple's words, they said Although corecrypto  
    does not directly provide programming interfaces for developers. no API, any source ? It's very very like opensl/fips.
  
# Diff
##  1. remove OS X gcd function calls like
    1.dispatch_async(get_queue_main()^(){...});
    2.dispatch_once(...);
    I don't know how the Apple's gcd function works. On windows Environment, u'd better use winmmi API waking up your callbacks.
    and injecting your code to another thread is more hard. MicroSoft never provide APC programming in UserMode. May be hooking 
    windows ntdll sysenter and call your callback functions. ohter
    wise fucking the Windows iTunes is the best way
## 2. fast AES
    I only complied the pure c AES.
## 3. cccurve25519 or cced25519
    Apple's UserMode corecrypto uses cced25519 libs, cccurve25519 for KernelMode. 
    I've never get the definition of cccurve25519 privatekey.
## 4. Apple SEPRom
    Apple SEP ROM is a hardware Embedded On your iPhone. It provides ecdsa, aes ...  this project closed it.
## 5. cc_config.h
    Checking your config for yourself.
## 6. take care of cc_xxx_ctx_t
    it's difficult to understanding Apple's code style.  for example when you want to malloc a cc_digest_ctx_t, 
    Apple's macro  ccdigest_ctx_decl ccdigest_ctx_size ccdigest_di_size is very useful for you.
    and force convert the allocated address to cc_digest_ctx_t, not a context pointer.
    '''
        struct ccdigest_info* destInfo = ccsha1_di();
		ccdigest_ctx_t context = (ccdigest_ctx_t)(struct ccdigest_ctx*)malloc(ccdigest_ctx_size(destInfo->state_size, destInfo->block_size));
		ccdigest_init(destInfo, context);
				// do something
    '''
 







