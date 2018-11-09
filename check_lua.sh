#!/bin/bash

for file in `find game -name "*.lua" `;
do
    luacheck ${file}
done
