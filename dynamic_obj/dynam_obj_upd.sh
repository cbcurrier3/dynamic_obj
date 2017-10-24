#!/bin/bash
# Version 9
# Date 10/10/2017 14:31:00

timeout=43200
LOG_FILE="$FWDIR/log/dynam_obj_upd.log"
CACHE_FILE_OLD="$FWDIR/database/dyn_cache.bip" #cache file
CACHE_FILE_NEW="$FWDIR/database/dyn_cache_tmp.bip"
CACHE_FOLDER="$FWDIR/database/"

y=0
x=0
z=0

#is_fw_module=$($CPDIR/bin/cpprod_util FwIsFirewallModule)
is_fw_module=1

IS_FW_MODULE=$($CPDIR/bin/cpprod_util FwIsFirewallModule)

MY_PROXY=$(clish -c 'show proxy address'|awk '{print $2}'| grep  '\.')
MY_PROXY_PORT=$(clish -c 'show proxy port'|awk '{print $2}'| grep -E '[0-9]+')
if [ ! -z "$MY_PROXY" ]; then
	HTTPS_PROXY="$MY_PROXY:$MY_PROXY_PORT"
fi

while getopts o:f:u:a:h: option
  do
	case "${option}"
	in	
	o) objName=${OPTARG};;
	u) url=${OPTARG};;
	f) filein=${OPTARG};;
	a) action=${OPTARG};;
	h) dohelp=${OPTARG};;
	?) dohelp=${OPTARG};;
	esac
done
function log_line {
	# add timestamp to all log lines
	message=$1
	local_log_file=$2	
	echo "$(date) $message" >> $local_log_file
}
function convert {
        while read ip; do
        if ! [[ "$ip" =~ [^0-9.-] ]];
        then
                todo[$y]+=" $ip $ip"
                if [ $z -eq 2000 ]
                        then
                                z=0
                                let y=$y+1
                        else
                                let z=$z+1
                        fi
        fi
        done

        dynamic_objects -do "$objName"
        dynamic_objects -n "$objName"

        for i in "${todo[@]}" ;
        do
                dynamic_objects -o "$objName" -r $i -a
        done
}
function check_url {
	if [ ! -z $url ]; then
		test_url=$url
					
		#verify curl is working and the internet access is avaliable
		if [ -z "$HTTPS_PROXY" ]
		then
			
			test_curl=$(curl_cli --head -k -s --cacert $CPDIR/conf/ca-bundle.crt --retry 2 --retry-delay 20 $test_url | grep HTTP)	
		else
			test_curl=$(curl_cli --head -k -s --cacert $CPDIR/conf/ca-bundle.crt $test_url --proxy $HTTPS_PROXY | grep HTTP)
		fi
		
		if [ -z "$test_curl" ]
		then 
			echo "Warning, cannot connect to $test_url"
			exit 1
		fi
		log_line "done testing http connection" $LOG_FILE
	fi	
}

function remove_existing_sam_rules {
	log_line "remove existing sam rules for $objName" $LOG_FILE
	dynamic_objects -do $objName
}

function print_help {
                echo ""
                echo "This script is intended to run on a Check Point Firewall"
                echo ""
                echo "Usage:"
                echo "  dynam_obj_upd.sh <options>"
                echo ""
                echo "Options:"
		echo "  -o			Dynamic Object Name (required)"
               	echo "  -u			url to retrieve IP Address list (optional)"
		echo "  -f			local file name of IP Address list (optional)"
		echo "  -a			action to perform (required) includes:"
		echo "				run (once), on (schedule), off (from schedule), stat (status)"
		echo "  -h			show help"
                echo ""
                echo ""
}
if [ -z $url ]; then
	if [ -e $filein ]; then
		optin="-f $filein"
	else
		log_line "file $filein for $objName not found" $LOG_FILE
		exit 1
	fi
else
	optin="-u $url"
fi

if [[ "$is_fw_module" -eq 1 && /etc/appliance_config.xml ]]; then
        case "$action" in

                on)
		check_url
		log_line "adding dynamic object $objName to cpd_sched " $LOG_FILE
                $CPDIR/bin/cpd_sched_config add "DYOBJ_"$objName -c "$CPDIR/bin/dynam_obj_upd.sh" -v "-a run -o $objName $optin" -e $timeout -r -s
                log_line "Automatic updates of $onjName is ON" $LOG_FILE
                ;;

                off)
		log_line "Turning off dyamic object updates for $objName" $LOG_FILE
                $CPDIR/bin/cpd_sched_config delete "DYOBJ_"$objName -r
                remove_existing_sam_rules
                log_line "Automatic updates of $objName is OFF" $LOG_FILE
                ;;

                stat)
                cpd_sched_config print | awk 'BEGIN{res="OFF"}/Task/{flag=0}/'$objName'/{flag=1}/Active: true/{if(flag)res="ON"}END{print "'$objName' list status is "res}'
				;;
				
		run)
		log_line "running update of dyamic object $objName" $LOG_FILE
		check_url
		if [ -z "$url" ]
		then
			cat "$filein" | dos2unix | convert
		else
		if [ -z "$HTTPS_PROXY" ]
		then
			curl_cli -k -s --cacert $CPDIR/conf/ca-bundle.crt --retry 10 --retry-delay 60 $url | dos2unix | grep -vE '^$'| convert
		else
			curl_cli -k -s --cacert $CPDIR/conf/ca-bundle.crt --retry 10 --retry-delay 60 $url --proxy $HTTPS_PROXY | dos2unix | grep -vE '^$'| convert
		fi
		fi
		log_line "update of dyamic object $objName completed" $LOG_FILE
		;;
				
                *)
		print_help
	esac
fi

