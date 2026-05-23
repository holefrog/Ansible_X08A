# Android / Mico Device Automation Setup

本项目基于 Ansible 自动化工具，旨在将安卓设备（如小米音箱、Android TV 等）进行深度的纯净版改造。
包含从恢复出厂设置、卸载内置自带广告软件（Debloat）、将第三方应用转为系统应用安装（节省空间），到全自动配置自定义桌面启动器与屏幕保护程序的完整流程。

---

## 0. 目标设备规格 (Target Device: XiaoAi X08A)

| 参数 | 规格 |
|------|------|
| 型号 | 小米小爱触屏音箱 8（XiaoAi X08A） |
| 屏幕 | 8 英寸 IPS 触摸屏，1280 × 800，横屏，多点触控 |
| 操作系统 | Android 8.1.0 (API Level 28)，深度定制 Mico OS |
| 处理器 | MediaTek MT8167A（四核 Cortex-A35，1.5GHz） |
| 内存 | 1GB / 2GB LPDDR3 |
| 存储 | 8GB eMMC（预装系统占用过半，`/data` 可用空间极少） |
| Wi-Fi | 2.4GHz / 5GHz 双频（802.11 b/g/n/ac） |
| 蓝牙 | Bluetooth 5.0（含 Mesh 网关） |
| 其他 | 前置摄像头、全频扬声器、远场麦克风阵列 |

> **存储吃紧是核心约束**：预装 Mico 系统和应用占用超过一半容量，因此本项目将第三方 APK 直接推送到 `/system/app/` 而非 `/data`，以最大化用户可用空间。

---

## 1. 擦除数据与恢复出厂设置 (Factory Reset)

如果是重新配置设备，建议先清空所有数据。你可以选择手动操作，或者在已开启 ADB Root 的情况下使用 Ansible 脚本。

### 方式一：实体按键手动双清
1. 同时按住 `Vol+` 和 `Vol-` 键。
2. 插入电源开机。
3. 保持按住直到屏幕显示 "Mi" Logo，系统将进入 Recovery 自动清空数据。
4. 大概要等待5分钟时间才会进入系统。如果一直卡在转圈，重新插一次电源就进入系统了。

### 方式二：使用 Ansible 脚本（需设备已连接 ADB 且授权）
直接在终端执行以下剧本，按提示输入大写 `WIPE` 确认即可自动重启清空数据：
```bash
ansible-playbook factory_reset.yml
```

---

## 2. 初始开机向导 (Initial Setup)

恢复出厂后，需要手动完成基础的系统引导过程：
1. **连接 WIFI**：按照屏幕提示连接网络。
2. **登录账号**：登录 Mi App。
3. **授权登录**：完成设备与账号的绑定。
4. **开启 ADB 调试**：在设置中连续点击系统版本号开启开发者模式，并允许通过网络/USB进行 ADB 调试。

⚠️ **【极度重要】**：必须**禁用麦克风**！否则 `MiVpmService` 进程将会满载消耗所有 CPU 资源导致设备卡顿断网。
* **操作方法**：从屏幕顶部下拉打开内置设置面板，点击静音麦克风。
* *(注：每次手动重启设备后，都需要重新执行此静音操作)*

---

## 3. Ansible 自动化部署 (Automated Installation)

将需要安装的 APK 放置在 `roles/apps/files/` 目录下，配置好目标设备的 IP 地址后，运行主控 Playbook：

```bash
./apply.sh
```

脚本将按以下顺序自动完成操作：

### 3.1 系统初始化 (`roles/system_init`)

1. **获取 Root 权限并挂载读写分区**：执行 `adb root` 与 `adb remount`，为后续操作准备环境。
2. **设置时区**：开启自动时间/时区同步，并将系统时区强制设置为 `America/Vancouver`。
3. **禁用 MiVpmService**：取消 `/system/bin/MiVpmService` 的执行权限，彻底阻止其消耗 CPU。
4. **批量卸载预装垃圾软件（Bloatware）**：通过 `pm uninstall --user 0` 移除以下应用：
   - `com.xiaomi.micloud.sdk`、`com.miui.weather2`、`com.baidu.map.location`
   - `com.ktcp.aiagent`、`com.miui.hybrid.soundbox`、`com.qiyi.video.speaker`
   - `com.tencent.qqlive.audiobox`、`com.xiaoxun.xun`、`com.xiaomi.mico.feedback`
   - `com.xiaomi.mico.gallery`、`com.xiaomi.mico.romupdate`、`com.xiaomi.mico.screensaver`
   - `com.youku.iot`、`com.sohu.inputmethod.sogou.tv`
5. **停用顽固系统应用**：无法完全卸载的应用通过 `pm disable-user --user 0` 停用：
   - `com.xiaomi.mico.appstore`、`com.xiaomi.smarthome`、`com.xiaomi.mico.ai`
6. **推送壁纸**：将 `Marvin.jpg` 推送至 `/data/system/users/0/wallpaper` 与 `/system/media`，并修复文件权限（`chown system:system` + `chmod 644`）防止桌面重置壁纸。

### 3.2 应用安装 (`roles/apps`)

1. **推送系统分区应用**：将 `roles/apps/files/` 下文件名**不含** `newpipe`、`firefox`、`launcher`、`fcitx`、`virtualsoftkeys`（均大小写不敏感）的 APK 推送至 `/system/app/`，设置 `644` 权限，然后执行软重启（`stop` / `start`）并轮询等待包管理器就绪。
2. **安装常规应用**：将文件名**含有** `newpipe`、`firefox`、`launcher`、`fcitx`、`virtualsoftkeys` 的 APK 通过 `adb install -r` 安装到用户空间（`/data` 分区），方便日后独立更新。
3. **配置屏幕保护程序**：将 `FSClock` 注册为系统屏保服务，设定为睡眠/底座模式触发，并将息屏超时设为 10 分钟（600000 毫秒）。
4. **配置桌面启动器**：启用 `Niagara Launcher`（`bitpit.launcher`），将其设为系统默认桌面，并停用 `com.xiaomi.micolauncher` 防止冲突。
5. **推送 VPN 配置文件**：将 `AC3100.ovpn` 推送至设备的 `/storage/sdcard0/Download/` 目录。
6. **配置 Fcitx5 输入法**：启用 `org.fcitx.fcitx5.android` 并将其设置为系统默认输入法。之后通过直接修改 `/data/system/users/0/settings_secure.xml`，将 `default_input_method` 与 `enabled_input_methods` 的 `value` 和 `defaultValue` 同时写入 fcitx5，确保重启后设置不被覆盖。

   ---

   #### 第三方输入法无法在重启后持久化——完整调试记录与结论

   **现象**：每次重启后，`default_input_method` 变为空白，需要手动重新执行 `ime enable` + `ime set`。

   **排查过程**：

   1. **守护脚本方向（无效）**：最初尝试通过 `init.rc` 服务加 `init.d` 脚本在开机后自动执行 `ime enable` / `ime set`。该方案完全无效——`init` 进程只在启动最早期扫描一次 `/system/etc/init/`。Ansible 部署时系统已在运行，推进去的 `.rc` 文件从未被读取，脚本从未执行。

   2. **修改 `settings_secure.xml` 方向（无效）**：发现 `/data/system/users/0/settings_secure.xml` 中的 `defaultValue` 字段是系统重置的基准值，尝试用 `sed` 直接修改。无效——`InputMethodManagerService` 在每次启动时会用内存中的状态重建并覆盖整个文件，运行时写入的内容必然被覆盖。

   3. **搜狗残留方向（部分原因）**：确认搜狗 APK 仍留在 `/system/app/SogouIME/`，`pm uninstall --user 0` 只对 user 0 隐藏，APK 本体未删除。系统启动时扫描到搜狗，用它重建 `defaultValue`。已将搜狗目录物理删除，并在 `clear.yml` 中加入 `rm -rf /system/app/SogouIME` 任务。

   4. **fcitx5 的根本限制（Android 版本）**：删除搜狗后问题依然存在。日志显示：
      ```
      InputMethodUtils: No software keyboard is found. systemLocale=en_CA fallbackLocale=null
      InputMethodManagerService: No default found
      ```
      `InputMethodManagerService` 扫描到 fcitx5 但拒绝将其设为默认，原因是 fcitx5 没有声明任何 subtype，`fallbackLocale` 为 null，系统无法匹配当前 locale。查阅源码确认：**fcitx5-android 从 0.0.9 版本才开始暴露 subtypes，且仅对 Android 14+（API 34）生效。本设备为 Android 8.1（API 28），该机制永远不会触发。**

   5. **尝试替换为 Trime（同文输入法）（无效）**：Trime 最低支持 Android 5.0，理论上兼容。先作为普通应用安装到 `/data/app/`——重启后报 `cannot start after reboot until unlock your phone`，Direct Boot 机制阻止了 `/data` 分区的应用在解锁前启动。随后将 Trime APK 及其唯一的 native 库 `librime_jni.so` 推入 `/system/app/` 和 `/system/lib/`，使其成为系统应用。重启后依然空白，日志揭示了根本原因：
      ```
      19:45:30 - InputMethodManagerService 启动，imis=[]（Trime 尚未被扫描到）
      19:45:30 - No default found
      19:45:34 - Trime 被 PackageManager 扫描到（已晚4秒）
      ```
      **Mico OS 的定制启动顺序导致 `InputMethodManagerService` 初始化时 PackageManager 尚未完成对 `/system/app/` 的扫描，系统用空列表完成初始化后不会再触发默认 IME 选择流程。这个问题与搜狗是否存在无关，装进系统分区也无法解决。**

   **结论**：在这台 XiaoAi X08A（Mico OS / Android 8.1）上，任何第三方输入法——无论安装位置是 `/data/app/` 还是 `/system/app/`——都无法在开机时被系统自动设为默认 IME。这是 Mico OS 深度定制的启动时序问题，在不修改系统固件的前提下无解。

   **现行妥协方案**：`ime enable` + `ime set` 保留在 Ansible 的 `fcitx5.yml` 末尾，每次重新部署后自动设置一次。重启后设置会丢失，重跑 `./apply.sh` 即可恢复。如需更快恢复，可单独执行：
   ```bash
   adb shell ime enable com.osfans.trime/.ime.core.TrimeInputMethodService
   adb shell ime set com.osfans.trime/.ime.core.TrimeInputMethodService
   ```


   **关于开机自启的坑**

   曾尝试通过 `init.rc` 服务加 `init.d` 脚本在开机后自动执行 `ime enable` / `ime set`，该方案完全无效，原因如下：

   - **`.rc` 文件运行时推送无效**：Android 的 `init` 进程只在系统启动最早期扫描一次 `/system/etc/init/`。Ansible 部署时系统已在运行，推进去的 `.rc` 文件永远不会被读取，服务从未注册，脚本从未执行。
   - **fcitx5 没有 `BOOT_COMPLETED` receiver**：无法靠应用自身在开机后自动启动并重新注册。
   - **根本原因在 `settings_secure.xml`**：`InputMethodManagerService` 在每次启动时以 `defaultValue` 字段为基准重置输入法配置。该文件的 `defaultValue` 初始值为搜狗（或空），导致无论运行时如何通过 `ime set` 修改，重启后必然被覆盖还原。

   **正确解法**：在 fcitx5 安装完成后，用 `sed` 直接修改 `/data/system/users/0/settings_secure.xml`，将两个字段的 `value` 与 `defaultValue` 同时替换为 fcitx5，从根本上替换系统的重置基准值。
   
### 4.5 VirtualSoftKeys (虚拟按键悬浮球) 配置
悬浮球应用 (`tw.com.daxia.virtualsoftkeys`) 受限于 Mico OS 的无障碍服务限制和权限阉割，Ansible 部署后需确保以下指令已执行以强制授权并保活：
1. **授予悬浮窗权限**（绕过系统阉割的设置界面）：
   `adb shell appops set tw.com.daxia.virtualsoftkeys SYSTEM_ALERT_WINDOW allow`
2. **激活无障碍服务**（若界面无法开启）：
   `adb shell settings put secure enabled_accessibility_services tw.com.daxia.virtualsoftkeys/.service.ServiceFloating`
   `adb shell settings put secure accessibility_enabled 1`
3. **加入后台白名单**（防止系统杀死限制）：
   `adb shell dumpsys deviceidle whitelist +tw.com.daxia.virtualsoftkeys`
   *(注：仍建议在 4.4 所述的“快霸”中双重确认已允许其后台运行。由于应用较老，若出现严重兼容问题请卸载并替换为 Key Mapper。)*

---

## 4. 后续手动配置补充 (Post-Install Configurations)

部分系统级的行为控制及第三方应用配置，需要在 Ansible 部署完成后手动进行：

### 4.1 OpenVPN 代理配置 (Bypass VPN Dialog)
VPN 应用在首次连接时系统会弹窗请求授权，如果被顶层应用遮挡无法点击 "OK"，可利用 ADB 模拟键盘按键放行：
1. 在设备端打开 OpenVPN 并导入已推送的 `AC3100.ovpn`。
2. 点击连接触发授权弹窗。
3. 在电脑端依次发送以下按键指令（对应：Enter -> Tab -> Tab -> Enter）：
```bash
adb shell input keyevent 66
adb shell input keyevent 61
adb shell input keyevent 61
adb shell input keyevent 66
```

### 4.2 时区与时间修复 (Timezone)
Ansible 部署时已自动配置时区。如需手动修复，可通过 ADB 强制指定：
```bash
adb root
adb shell settings put global auto_time 1
adb shell settings put global auto_time_zone 1
adb shell setprop persist.sys.timezone America/Vancouver
```

### 4.3 SB Player 设置注意
**切勿**取消勾选 "Show this screen at launch"。否则该应用的设置界面将在后续启动时彻底隐藏，只能通过清空应用数据才能重新配置。

### 4.4 允许后台运行权限
前往系统 `Settings -> 快霸`，手动打开需要常驻后台的应用（如代理、保活应用）的后台运行允许权限。

---

## 5. 常见故障排除 (Troubleshooting)

**问题：在系统设置中更改字体/显示大小后，设备陷入无尽的 "Please wait,..." 循环加载。**
**解决办法**：清除自带设置数据，并通过 ADB 疯狂发送重新拉起 Niagara 桌面的指令打断循环。
```bash
adb shell pm clear com.xiaomi.mico.settings
adb shell pm enable bitpit.launcher
adb shell pm enable bitpit.launcher
adb shell pm enable bitpit.launcher
```

**问题：设置 Niagara Launcher 主题后设备无限重启。**
**原因**：1.13.4 及以上版本在 XiaoAi X08A (API 28) 设备上运行时，在主题功能路径上引用了 API 33 才有的类。主题功能会崩溃，需使用旧版 APK。
**解决办法**：⚠️ **【极度重要】切勿在 Niagara Launcher 中设置任何主题！** 更改主题会导致系统界面崩溃并引发设备无限重启。如果已发生无限重启，请尝试使用 ADB 清除桌面数据或重新刷机。
```bash
adb shell pm clear bitpit.launcher
```

**问题：输入法应用运行后不断崩溃。**
**原因**：输入法不能当成系统应用安装，否则会找不到库文件不断崩溃。
**解决办法**：APK 文件名须包含 `fcitx` 关键字，Ansible 会自动将其识别为常规应用安装到用户空间（`/data` 分区），不会推送到 `/system/app/`。


**问题：Ansible 脚本执行过程中，再次安装Firefox 退出。**
**原因**：储存空间耗尽，要先删除。
**解决办法**： 先卸载
```bash
adb uninstall org.mozilla.firefox
```
