#!/bin/bash

# 删除_build目录
rm -rf _build

# 删除deps目录
rm -rf deps

# 重新获取依赖
mix deps.get

# 重新编译
TARGET_ABI=musl MIX_ENV=prod mix release
