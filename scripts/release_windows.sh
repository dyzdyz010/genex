#!/bin/bash

# 删除burrito_output目录
# rm -rf burrito_output

# 删除_build目录
rm -rf _build

# 删除deps目录
rm -rf deps

# 重新获取依赖
mix deps.get

# 重新编译
TARGET_VENDOR=pc TARGET_OS=windows TARGET_ABI=msvc BURRITO_TARGET=windows MIX_ENV=prod mix release
# MIX_ENV=prod mix release