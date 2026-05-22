#!/system/bin/sh
# 等待系统加载完毕 (20秒通常足够)
sleep 20
ime enable org.fcitx.fcitx5.android/.input.FcitxInputMethodService
ime set org.fcitx.fcitx5.android/.input.FcitxInputMethodService