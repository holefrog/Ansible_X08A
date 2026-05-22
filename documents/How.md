#####################################################################
# Factory Reset
#####################################################################
Press Vol+ and Vol-, then plug in the power.
Keep pressing until "Mi" is shown.


#####################################################################
# Ini
#####################################################################
1. Connect to WIFI

2. Login into Mi App

3. Auth login


#####################################################################
**Important**
#####################################################################
Must disable Microphone. Otherwise, MiVpmService will use all the CPU!!!
```
Swipe down from the top of the screen to open the built-in settings, then click to mute the microphone.
The mute setting needs to be reapplied after each restart.
```

# Disable
1. Find
```
adb shell ps -A | grep MiVpmService
root           858     1   74604  16400 binder_thread_read b5a657f0 S MiVpmService
```

```
adb shell find /system -type f -name "MiVpmService"
/system/bin/MiVpmService
```

2. Disable
```
adb root
adb remount
adb shell "su 0 mount -o rw,remount /"
adb shell chmod 000 /system/bin/MiVpmService
```


#####################################################################
# Install  launcher
#####################################################################

# Command
```
adb root

adb install Niagara_Launcher_1.13.4_APKPure.apk

adb shell pm list packages | grep launcher

adb shell cmd package resolve-activity --brief -c android.intent.category.HOME -a android.intent.action.MAIN

adb shell pm enable bitpit.launcher


adb shell am start -n bitpit.launcher/.ui.HomeActivity 
```

# Set Default App
+ Settings--App and Notice--Default App--Main Screen App
+ adb
```
adb shell cmd package set-home-activity bitpit.launcher/.ui.HomeActivity
```


# Disable MicoLauncher
```
pm list packages -f | grep -i launcher
package:/data/app/bitpit.launcher-ZPVuAr1FxBGbGimHYxR_yA==/base.apk=bitpit.launcher
package:/system/app/MicoLauncher/MicoLauncher.apk=com.xiaomi.micolauncher

pm disable-user --user 0 com.xiaomi.micolauncher
```


#####################################################################
# Remove apps
#####################################################################
1. list
```
adb shell pm list packages
```

2. Remove
```
adb root
# adb shell pm uninstall --user 0 com.sohu.inputmethod.sogou.tv

adb shell pm uninstall --user 0 com.baidu.map.location
adb shell pm uninstall --user 0 com.ktcp.aiagent
adb shell pm uninstall --user 0 com.miui.hybrid.soundbox
adb shell pm uninstall --user 0 com.qiyi.video.speaker
adb shell pm uninstall --user 0 com.tencent.qqlive.audiobox
adb shell pm uninstall --user 0 com.xiaoxun.xun
adb shell pm uninstall --user 0 com.xiaomi.mico.feedback
adb shell pm uninstall --user 0 com.xiaomi.mico.gallery
adb shell pm uninstall --user 0 com.xiaomi.mico.romupdate
adb shell pm uninstall --user 0 com.xiaomi.mico.screensaver
adb shell pm uninstall --user 0 com.youku.iot
adb shell pm uninstall --user 0 com.sohu.inputmethod.sogou.tv

```

# Do not uninstall below
```
adb shell pm uninstall --user 0 com.xiaomi.mico.fallbackhome
adb shell pm uninstall --user 0 com.xiaomi.smarthome
adb shell pm uninstall --user 0 com.xiaomi.mico.ai
adb shell pm uninstall --user 0 com.xiaomi.micooverrides 
adb shell pm uninstall --user 0 com.xiaomi.mico.appstore 
adb shell pm uninstall --user 0 com.xiaomi.mico.settings
```


#####################################################################
# Set system wall paper
#####################################################################
```
adb root
adb remount

adb push Marvin.jpg /data/system/users/0/wallpaper
adb push Marvin.jpg /system/media


adb push wallpaper.png /data/system/users/0/wallpaper
adb push wallpaper.png /system/media
```


#####################################################################
# How to click the OK button of VPN which is blocked by the topmost app.
#####################################################################
0. Config
```
adb push AC3100.ovpn /storage/sdcard0/Download
```

1. Run Openvpn

2. click the profile to connect

3. when the comfirm dialog appears, send key to the activity.

4. adb shell

5. set keys under adb
66: Enter
61: Tab
```
adb root
adb shell input keyevent 66
adb shell input keyevent 61
adb shell input keyevent 61
adb shell input keyevent 66
```


#####################################################################
# SB Player
#####################################################################
Do not **unchecked** "Show this screen at launch". 
Otherwise, the app screen will not show again after running. Have to clean the storage and setup again.


#####################################################################
# Timezone
#####################################################################
```
adb root
adb shell settings put global auto_time 1
adb shell settings put global auto_time_zone 1

adb shell setprop persist.sys.timezone America/Vancouver
```


#####################################################################
# 快霸
#####################################################################
Settings--快霸
打开允许app在后台运行。




# Change Font/Display size in settings will cause looping "Please wait,..."
Try this:
```
adb shell pm clear com.xiaomi.mico.settings

adb shell pm enable bitpit.launcher
adb shell pm enable bitpit.launcher
adb shell pm enable bitpit.launcher
adb shell pm enable bitpit.launcher
```





#####################################################################
# Install  launcher [Flauncher]
#####################################################################
# Git 
[https://gitlab.com/flauncher/flauncher]


# AndroidManifest.xml
1. Rename me.efesser.flauncher_315_apps.evozi.com.apk  to me.efesser.flauncher_315_apps.evozi.com.zip

2. Unzip AndroidManifest.xml

3. decode

```
java -jar AXMLPrinter2.jar AndroidManifest.xml > manifest.xml
```


# Command
```
adb root

adb install me.efesser.flauncher_315_apps.evozi.com.apk 

adb shell pm list packages | grep launcher

adb shell pm enable me.efesser.flauncher

adb shell am start -n me.efesser.flauncher/me.efesser.flauncher.MainActivity

```

# Set Default App
+ Settings--App and Notice--Default App--Main Screen App
+ adb
```
adb shell cmd package set-home-activity me.efesser.flauncher/me.efesser.flauncher.MainActivity

```



#####################################################################
# Screensaver
#####################################################################
## Find package
```
adb shell pm list packages | grep clock

package:systems.sieber.fsclock
```

## Find Activity
```
adb shell dumpsys package systems.sieber.fsclock | grep -iE "service|class"

Service Resolver Table:
      android.service.dreams.DreamService:
        fe0baa1 systems.sieber.fsclock/.FullscreenDream filter 663002f permission android.permission.BIND_DREAM_SERVICE
          Action: "android.service.dreams.DreamService"
```

## Set screensaver
```
adb shell settings put secure screensaver_components systems.sieber.fsclock/.FullscreenDream
adb shell settings put secure screensaver_enabled 1
adb shell settings put secure screensaver_activate_on_sleep 1
adb shell settings put secure screensaver_activate_on_dock 1
```


## Test
```
adb shell service call dreams 1
```

## Delay Time 
```
adb shell settings get system screen_off_timeout

adb shell settings put system screen_off_timeout 600000



