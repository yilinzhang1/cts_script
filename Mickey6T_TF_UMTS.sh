#!/bin/bash
set -x
shopt -s expand_aliases

PROJECT_NAME="Mickey6T_TF_UMTS"
SCRIPT_DIR="${TOOLS_INT_DIR}/cts"
CTS_PATH="${WORK_DIR}"
CTS_TOOL_PATH="${CTS_PATH}/android-cts-6.0_r9/android-cts"
#CTS_TOOL_PATH="${CTS_PATH}/android-cts-5.1_r1/android-cts"
GTS_TOOL_PATH="${CTS_PATH}/android-xts-3.0_r6/android-xts"
CTS_MEDIA_PATH="${CTS_PATH}/android-cts-media-1.1"
SDK_PATH="${CTS_PATH}/android-sdk-linux"
RUNCTS="${CTS_TOOL_PATH}/tools/cts-tradefed"
CTSAPK_PATH="${CTS_TOOL_PATH}/repository/testcases"
SOFTWARE_PATH="jenkins@172.26.35.213:/data/share/CTS/tools"
USER="jenkins"
CTS_RESULT_SERVER="172.26.35.213"
CTS_RESULT_PATH="${CTS_RESULT_SERVER}/data/share/cts/$PROJECT_NAME"
Number=1
SETTING_DIR="${SCRIPT_DIR}/lib/Mickey6T_TF_UMTS"

alias die='_die "[Error $BASH_SOURCE->$FUNCNAME:$LINENO]"'
# This function is used to cleanly exit any script. It does this showing a
# given error message, and exiting with an error code.
function _die
{
    echo -e "\033[31;1m==================================\033[0m"
    echo -e "\033[31;1m$@\033[0m"
    echo -e "\033[31;1m==================================\033[0m"
    exit 1
}


function setup_cts_env()
{
    test -d $CTS_PATH && echo "The cts path is :" $CTS_PATH || \
        mkdir -vp $CTS_PATH
    test -d ${CTS_PATH}/android-cts-6.0_r9 && echo "The cts path is :" ${CTS_PATH}/android-cts-6.0_r9 || \
        mkdir -vp ${CTS_PATH}/android-cts-6.0_r9
    test -d ${CTS_PATH}/android-xts-3.0_r6 && echo "The xts path is :" ${CTS_PATH}/android-xts-3.0_r6 || \
        mkdir -vp ${CTS_PATH}/android-xts-3.0_r6
    cd $CTS_PATH
    #set gts tools
    test -d $GTS_TOOL_PATH && echo "There has a GTS tool!" || \
       ( scp -r $SOFTWARE_PATH/GTS/gts-3.0_r6.zip $HOME&& \
       unzip gts-3.0_r6.zip -d ${CTS_PATH}/android-xts-3.0_r6 && rm gts-3.0_r6.zip )

    #set cts tools
    test -d $CTS_TOOL_PATH && echo "There has a CTS tool!" || \
       ( scp -r $SOFTWARE_PATH/6.0CTS/android-cts-6.0_r9-linux_x86-arm.zip $HOME&& \
       unzip android-cts-6.0_r9-linux_x86-arm.zip -d ${CTS_PATH}/android-cts-6.0_r9 && \
       rm android-cts-6.0_r9-linux_x86-arm.zip )

    #set cts media
    test -d $CTS_MEDIA_PATH && echo "There has CTS media" || \
       ( scp -r $SOFTWARE_PATH/android-cts-media-1.1.zip $HOME&& \
       unzip android-cts-media-1.1.zip -d $CTS_PATH && rm android-cts-media-1.1.zip )
    #set sdk
    test -d $SDK_PATH && echo "Tere has a SDK!" || \
       ( scp -r $SOFTWARE_PATH/android-sdk-linux.zip $HOME&& \
       unzip android-sdk-linux.zip && rm android-sdk-linux.zip )
    SDK_PATH_BUILDTOOL=`cd ${SDK_PATH}/build-tools && ls | sed -n 1p`
    export PATH="$PATH:${SDK_PATH}/tools:${SDK_PATH}/platform-tools:${SDK_PATH}/build-tools/${SDK_PATH_BUILDTOOL}"
}


function check_adb_devices()
{
    adbdvices=`adb devices | sed -n 2p`
    if [ "$adbdvices" = "" ];then
        die "NO adb devices"
    fi
}


function flash_img(){
    #use windows teleweb to flash image
    echo 'Start VM ...'
    #VBoxManage startvm "shreck"
    #sleep 60
    #VBoxManage list runningvms | grep shreck && echo "VM is running" ||  die "No VM running..."

    echo 'Download image files into phone ...'
    ssh 192.168.56.101 "python d:\\TelewebMtk.py ${PROJECT} ${VERSION} $PERSO"
    echo "wait....use teleweb flash image for windows VM"
    sleep 30
    #echo 'Shut Down VM...'
    #VBoxManage controlvm "shreck" acpipowerbutton
    #sleep 60

    #echo 'Check version number in phone ...'
    #VERSION_NEW_GOT=`adb shell getprop | grep ro\.custom\.build\.version | perl -n -e 'if (m/\[v([0-9A-Z]{3}-[0-9A-z])\]/) {print $1}'`

    #if [ $VERSION_NEW_GOT != $VERSION ]; then
    #   die "Error: version downloaded mismatch"
    #fi


}


function auto_setting()
{
    check_adb_devices
    Sum=`adb devices | wc -l`
    number=2
    local -a array
    i=0
    while [ $number -lt $Sum ]
	do			
	adbdevices=`adb devices | sed -n ${number}p `
	adbdevices=${adbdevices:0:8} #截取命令
	#adbdevices=`echo $adbdevices | cut -d' ' -f1`	一样可以截取
	array[$i]=$adbdevices
	i=$[i+1]
	number=$[number+1]
	done
    if [ $i -eq 0 ];then
	echo $i
    else
    	Number=$i
    fi
    for i in ${array[@]};do
    	adb -s $i install -r $CTSAPK_PATH/CtsDeviceAdmin.apk
    	adb -s $i install -r $SETTING_DIR/Idol4_bellAutoSetting.apk
    	adb -s $i install -r $SETTING_DIR/SettingBrowserActivity.apk

    	#monkeyrunner $SETTING_DIR/wake.py $SETTING_DIR
    	#adb shell am instrument -w com.settings.test/android.test.InstrumentationTestRunner

    	adb -s $i shell am instrument -e class com.settings.test.TestSetting#test01Development -w com.settings.test/android.test.InstrumentationTestRunner
    	adb -s $i shell am instrument -e class com.settings.test.TestSetting#test02ConnectWifi -w com.settings.test/android.test.InstrumentationTestRunner
    	adb -s $i shell am instrument -e class com.settings.test.TestSetting#test03Display -w com.settings.test/android.test.InstrumentationTestRunner
    	adb -s $i shell am instrument -e class com.settings.test.TestSetting#test04DateTime -w com.settings.test/android.test.InstrumentationTestRunner
    	adb -s $i shell am instrument -e class com.settings.test.TestSetting#test05SetSecurity -w com.settings.test/android.test.InstrumentationTestRunner
    	adb -s $i shell am instrument -e class com.settings.test.TestSetting#test06LockScreen -w com.settings.test/android.test.InstrumentationTestRunner
    	#setting Browser
    	#monkeyrunner $SETTING_DIR/wake.py $SETTING_DIR browser_setting

    	#copy media file
    	adb -s $i push $CTS_MEDIA_PATH "/mnt/sdcard/test/"
	done
}


function run_gts()
{
    #remove gts old result
    if [[ -d $GTS_TOOL_PATH/repository/results ]];then
        test -d $GTS_TOOL_PATH/repository/oldresult && echo "oldresult dir is exist" || \
            mkdir -vp $GTS_TOOL_PATH/repository/oldresult
        mv  $GTS_TOOL_PATH/repository/results/* $GTS_TOOL_PATH/repository/oldresult
        rm -rf $GTS_TOOL_PATH/repository/logs/*
    fi
    #run gts atuo setting
    check_adb_devices
    #monkeyrunner $SCRIPT_DIR/lib/beetlelite_auto_setting.py connect_wifi
    expect -c"
            set timeout -1
            spawn bash ${GTS_TOOL_PATH}/tools/xts-tradefed run xts --plan XTS
            expect {
                "*generated*" { send exit\r\n; send \003 ; interact }
                eof { exit }
            }
            exit
            "
    rm -rf ${GTS_TOOL_PATH}/tools/athrun
    cp -r $SCRIPT_DIR/lib/athrun ${GTS_TOOL_PATH}/tools
    sed -i 's/cts/xts/g'  ${GTS_TOOL_PATH}/tools/athrun/*
    sed -i 's/testResult.xml/xtsTestResult.xml/g' ${GTS_TOOL_PATH}/tools/athrun/*
    cd ${GTS_TOOL_PATH}/tools/athrun && mv runcts.py runxts.py
    i=0
    while [ $i -lt 2 ]
        do
            $SCRIPT_DIR/lib/runcts.py ${GTS_TOOL_PATH}/tools/athrun runnopass
            i=`expr $i + 1`
        done
}


function run_cts()
{
    #remove cts old result
    if [[ -d $CTS_TOOL_PATH/repository/results ]];then
        test -d $CTS_TOOL_PATH/repository/oldresult && echo "oldresult dir is exist" || \
            mkdir -vp $CTS_TOOL_PATH/repository/oldresult
        mv  $CTS_TOOL_PATH/repository/results/* $CTS_TOOL_PATH/repository/oldresult
        rm -rf $CTS_TOOL_PATH/repository/logs/*
    fi
    #run cts test
    check_adb_devices
    if [$Number -eq 1];then
  	  auto_done_cts "bash ${CTS_TOOL_PATH}/tools/cts-tradefed run cts --plan CTS"
    else 
	  auto_done_cts "bash ${CTS_TOOL_PATH}/tools/cts-tradefed run cts --plan CTS --disable-reboot --shards $Number"
    fi 
    adb reboot
    sleep 80
    rm -rf ${CTS_TOOL_PATH}/tools/athrun
    cp -r $SCRIPT_DIR/lib/athrun ${CTS_TOOL_PATH}/tools
    cd ${CTS_TOOL_PATH}/tools/athrun
    i=0
    while [ $i -lt 4 ]
        do
            check_adb_devices
            #monkeyrunner $SCRIPT_DIR/lib/beetlelite_auto_setting.py connect_wifi
            auto_done_cts "bash runnotpasscts.sh"
            i=`expr $i + 1`
        done
}


function auto_done_cts()
{

    expect -c"
    set timeout -1
    spawn $1
    expect "*testResult.xml*"
    exec sleep 60
    send \"exit\r\"
    send \"\003\"
    expect eof
    exit
    "
}


function copy_result()
{
    var=$1
    if [ "$var" = "cts" ]; then
        result_path=$CTS_TOOL_PATH
    else
        result_path=$GTS_TOOL_PATH
    fi

    cd $result_path/repository/results
    dir=`ls *.zip | sed -r 's/(.*).zip/\1/g'`
    test -d $dir && echo "The result dir is:"$dir || unzip *.zip
    mkdir -vp v${VERSION}/${PERSO} && \
    mkdir -vp v${VERSION}/${PERSO}/${var}_log && \
    mv $dir v${VERSION}/${PERSO} && \
    cd v${VERSION}/${PERSO} && \
    cp -r $dir ${var}_Result && \
    zip -r $dir.${var}.zip $dir && \
    cd $result_path/repository/results && \
    mv $result_path/repository/logs $result_path/repository/results/v${VERSION}/${PERSO}/${var}_log || die "move result failed"
    auto_passwd_expect "scp -o StrictHostKeyChecking=no -r v${VERSION}/ $USER@$CTS_RESULT_SERVER:/data/share/CTS/$PROJECT_NAME/"
    echo "The result is : smb://$CTS_RESULT_PATH/v${VERSION}/${PERSO}"
}


function auto_passwd_expect()
{
    expect -c"
    set timeout -1
    spawn $1
    expect "*password:*"
    send \"$JENKINS_PASSWD\r\"
    expect eof
    exit
    "

}


function main()
{
    setup_cts_env
    #flash_img
#    auto_setting
    if [ x"$AUTO_SETTING" != x"false" ];then
         auto_setting
    fi
    if [ x"$RUN_CTS" != x"false" ];then
         run_cts
         copy_result cts
    fi
    if [ x"$RUN_GTS" != x"false" ];then
         run_gts
         copy_result gts
    fi

}
main
