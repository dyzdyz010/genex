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
export TARGET_VENDOR=unknown
export TARGET_OS=linux
export TARGET_ABI=musl
export BURRITO_TARGET=linux_x86_64
export MIX_ENV=prod
mix release
