#include <lua.h>
#include <lauxlib.h>
#include <stdio.h>
#include <openssl/md5.h>
#include <openssl/evp.h>
#include <openssl/rsa.h>
#include <openssl/x509.h>
#include <openssl/err.h>
#include <openssl/pem.h>

const uint8_t* base64encode(const uint8_t *in, int32_t inl, int32_t* outl){
    int encode_sz = 128;
    uint8_t* buf = (uint8_t *) malloc(encode_sz);
    outl = 0;
    *outl = EVP_EncodeBlock(buf, in, inl);
    if(0 > *outl)
    {
        free(buf);
        return NULL;
    }
    *outl = encode_sz;
    return buf;
}

int lbase64encode(lua_State *L) {
    size_t sz = 0;
    const uint8_t* text = (const uint8_t*)luaL_checklstring(L, 1, &sz);


    int32_t encode_sz = 0;
    const uint8_t* buf = base64encode(text, sz, &encode_sz);

    lua_pushlstring(L, buf, encode_sz);
    free(buf);

    return 1;
}


const uint8_t* base64decode(const uint8_t *in, int32_t inl, int32_t* outl) {
    int encode_sz = inl;
    uint8_t* buf = (uint8_t *) malloc(inl);
    outl = 0;
    *outl = EVP_DecodeBlock(buf, in, inl);
    if(0 > *outl)
    {
        free(buf);
        return NULL;
    }
    *outl = encode_sz;
    return buf;
}

int lbase64decode(lua_State *L) {
    size_t sz = 0;
    const uint8_t* text = (const uint8_t*)luaL_checklstring(L, 1, &sz);


    int32_t encode_sz = 0;
    const uint8_t* buf = base64decode(text, sz, &encode_sz);

    lua_pushlstring(L, buf, encode_sz);
    free(buf);

    return 1;
}

int md5_with_rsa(lua_State *L) {
    size_t content_sz = 0;
    size_t key_sz = 0;

    const uint8_t* content = (const uint8_t*)luaL_checklstring(L, 1, content_sz);
    const uint8_t* key = (const uint8_t*)luaL_checklstring(L, 1, key_sz);

    size_t real_key_sz = 0;
//    uint8_t* real_key = base64decode(key, key_sz, real_key_sz)
}



int md5withrsa(lua_State *L) {
    size_t key_sz = 0;
    size_t content_sz = 0;
    RSA* rsa = NULL;
    const uint8_t* key = (const uint8_t*)luaL_checklstring(L, 1, &key_sz);

    const uint8_t* content = (const uint8_t*)luaL_checklstring(L, 2, &content_sz);
    uint32_t signLen = 0;
    uint8_t* signBuf = NULL;
    uint8_t* outBuf = NULL;
    int32_t ret = 0;
    int32_t outLen = 0;

    rsa = d2i_RSAPrivateKey(NULL, (const uint8_t **) &key, key_sz);
    if(rsa == NULL) {
        printf("生成key失败 keylen = %d\n", key_sz);
        return 0;
    }

    EVP_PKEY* pkey = EVP_PKEY_new();
    EVP_PKEY_assign_RSA(pkey, rsa);

    EVP_MD_CTX mdCtx;
    EVP_SignInit(&mdCtx, EVP_md5());
    EVP_SignUpdate(&mdCtx, content, content_sz);

    signLen = (EVP_PKEY_size(pkey));
    outLen = 0;
    signBuf = (uint8_t *) OPENSSL_malloc(signLen);
    outBuf = (uint8_t *) OPENSSL_malloc(signLen * 2);

    ret = EVP_SignFinal(&mdCtx, signBuf, &signLen, pkey);
    if(1!=ret) {
        printf("EVP_SignFinal failed\n");
        return 0;
    }

    outLen = EVP_EncodeBlock(outBuf, signBuf, signLen);
    if(outLen<0) {
        printf("EVP_EncodeBlock failed\n");
        return 0;
    }

    lua_pushlstring(L, outBuf, outLen);
    OPENSSL_free(signBuf);
    OPENSSL_free(outBuf);
    return 1;
}

int verifymd5withrsa(lua_State *L) {
    size_t key_sz = 0;
    size_t content_sz = 0;
    size_t sign_sz = 0;
    RSA* rsa = NULL;
    const uint8_t* key = (const uint8_t*)luaL_checklstring(L, 1, &key_sz);

    const uint8_t* content = (const uint8_t*)luaL_checklstring(L, 2, &content_sz);
    const uint8_t* sign = (const uint8_t*)luaL_checklstring(L, 3, &sign_sz);

    rsa = d2i_RSA_PUBKEY(NULL, (const uint8_t **) &key, key_sz);
    if(rsa == NULL) {
        printf("生成key失败 keylen = %d\n", key_sz);
        return 0;
    }

    EVP_PKEY* pkey = EVP_PKEY_new();
    EVP_PKEY_assign_RSA(pkey, rsa);

    EVP_MD_CTX mdCtx;
    EVP_VerifyInit(&mdCtx, EVP_md5());
    EVP_VerifyUpdate(&mdCtx, content, content_sz);
    int32_t ret = EVP_VerifyFinal(&mdCtx, sign, sign_sz, pkey);
    if(ret == 1) {
        lua_pushboolean(L, 1);
    }
    else
    {
        lua_pushboolean(L, 0);
    }
    return 1;
}


int luaopen_openssll(lua_State *L) {
    luaL_Reg l[] = {
      {"base64encode", lbase64encode},
      {"base64decode", lbase64decode},
      {"md5withrsa", md5withrsa},
      {"verifymd5withrsa", verifymd5withrsa},
      {NULL, NULL}
    };

    luaL_newlib(L,l);
    return 1;
}
