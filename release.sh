#!/bin/bash

#删除release目录所有内容
function pack_skynet()
{
    local dest="$1"
    local skynet_dir="${dest}/skynet"
    mkdir $skynet_dir
    cp skynet/skynet $skynet_dir
    cp -r skynet/lualib $skynet_dir
    cp -r skynet/luaclib $skynet_dir
    cp -r skynet/service $skynet_dir
    cp -r skynet/cservice $skynet_dir
}

function pack_login()
{
    echo "打包登录服"
    local d=release/login
    if [ -d $d ]; then
        rm -rf $d
    fi
    mkdir $d
    mkdir "$d/log"
    cp -r login $d
    cp -r lualib $d
    cp -r luaclib $d
    cp config_login.lua $d
    cp login.sh $d
    pack_skynet $d
    echo "打包登录服结束..."
}

function pack_lobby()
{
    echo "打包大厅"
    local d=release/lobby
    if [ -d $d ]; then
        rm -rf $d
    fi
    mkdir $d
    mkdir "$d/log"
    cp -r lobby $d
    cp -r lualib $d
    cp -r luaclib $d
    cp config_lobby.lua $d
    cp lobby.sh $d
    pack_skynet $d
    echo "打包大厅结束..."
}

function pack_game()
{
    echo "打包游戏"
    local d=release/game
    if [ -d $d ]; then
        rm -rf $d
    fi
    mkdir $d
    mkdir "$d/log"
    cp -r game $d
    cp -r lualib $d
    cp -r luaclib $d
    cp -r proto $d
    cp config_game_dgnn.lua $d
    cp config_game_pdk.lua $d
    cp game.sh $d
    cp game_pdk.sh $d
    pack_skynet $d
    echo "打包游戏结束..."
}

function pack_record()
{
    echo "打包回放服务器开始"
    local d=release/record
    if [ -d $d ]; then
        rm -rf $d
    fi
    mkdir $d
    cp -r record $d
    cp -r lualib $d
    cp -r luaclib $d
    cp config_record.lua $d
    cp record.sh $d
    pack_skynet $d
    echo "打包回放服务器结束..."
}

function pack_http_reverse_proxy()
{
    echo "打包http反向代理"
    local d=release/http_reverse_proxy
    if [ -d $d ]; then
        rm -rf $d
    fi
    mkdir $d
    cp login_proxy/main $d
    cp login_proxy/cfg_login.json $d
    cp login_proxy/cfg_lobby.json $d
    echo "打包http反向结束..."
}

function pack_tcp_reverse_proxy()
{
    echo "打包tcp反向代理"
    local d=release/tcp_reverse_proxy/
    if [ -d $d ]; then
        rm -rf $d
    fi
    mkdir $d
    cp tcp_proxy/main $d
    cp tcp_proxy/cfg.json $d
    echo "打包tcp反向代理结束..."
}

function pack_tar(){
    echo "压缩开始"
    tar -czf release.tar.gz release
    echo "压缩结束"
}

function pack_all()
{
    echo "打包所有"
    pack_login
    sleep 1
    pack_lobby
    sleep 1
    pack_game
    sleep 1
    pack_record
    sleep 1
    pack_http_reverse_proxy
    sleep 1
    pack_tcp_reverse_proxy
    sleep 1
    pack_tar
    echo "打包所有结束..."
}

function select_cmd(){
    echo "xserver打包工具1.0"
    echo "请选择打包项（对应数字）"
    local cmd
    select cmd in "打包所有" "打包登录服" "打包大厅服" "打包游戏服" "打包回放服务器" "打包http反向代理" "打包tcp反向代理" "打压缩包" "退出"
    do
        case $cmd in
            "打包所有")
                pack_all
                break
                ;;
            "打包登录服")
                pack_login
                break
                ;;
            "打包大厅服")
                pack_lobby
                break
                ;;
            "打包游戏服")
                pack_game
                break
                ;;
            "打包回放服务器")
                pack_record
                break
                ;;
            "打包http反向代理")
                pack_http_reverse_proxy
                break
                ;;
            "打包tcp反向代理")
                pack_tcp_reverse_proxy
                break
                ;;
            "打压缩包")
                pack_tar
                break
                ;;
            "退出")
                break
                ;;
            *)
                ;;
        esac
    done
}

select_cmd
