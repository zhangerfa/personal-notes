#!/bin/bash
# 每天定时执行，将内网主干同步到 GitHub 进行容灾备份
cd "$(dirname "$0")"
git checkout main
# 拉取内网最新的 main
git pull origin main
# 强制推送到 github 的 main 分支
git push github main
