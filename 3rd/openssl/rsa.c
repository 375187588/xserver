#include <lua.h>
#include <lauxlib.h>

int base64encode() {
    return 0;
}

int lbase64encode() {
    return 0;
}

int md5_with_rsa() {
    

}

int luaopen_rsa(lua_State *L) {
    luaL_Reg l[] = {
      {"base64encode", lbase64encode},
      {NULL, NULL}
    };

    luaL_newlib(L,l);
    return 1;
}
