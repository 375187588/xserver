drop database if exists xserver;

create database xserver;

use xserver;

create table account(
    account varchar(32) not null primary key,
    password varchar(32),
    sex int,
    headimgurl varchar(32),
    nickname varchar(64),
    userid int,
    openid varchar(64)
);
