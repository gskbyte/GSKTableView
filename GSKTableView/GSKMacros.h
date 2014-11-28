
#ifndef GSKTableView_GSKDefines_h
#define GSKTableView_GSKDefines_h

#define SEND_TO_DELEGATE_IF_RESPONDS(__who, __selector, __call) \
if([__who respondsToSelector:__selector]) { \
    __call;\
}

#define RETURN_FROM_DELEGATE_IF_RESPONDS(__who, __selector, __call, __return_if_no) \
if([__who respondsToSelector:__selector]) { \
    return __call;\
} else { \
    return __return_if_no;\
}

#define RETURN_FROM_DELEGATE_OR_CRASH(__who, __selector, __call, __assert_message) \
if([__who respondsToSelector:__selector]) { \
    return __call;\
} else { \
    NSAssert(NO, __assert_message);\
    return 0; \
}


#endif
