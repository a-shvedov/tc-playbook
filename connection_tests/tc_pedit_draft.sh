#!/bin/bash

tc_edit_loop(){

#while true; do

dev="enp0s8"
type_port="sport" 																
data_type="u32" 
sleep_value_set_time="1"
sleep_value_reset_time="1"
hex_const="00000000"

#rand-control:
section_min="70"
section_max="190"													

logfile=$(basename -s .sh ${0})_$(printf '%(%s)T\n' -1).log

check_oldest(){
max_log_files=3
log_pref="basename -s .sh ${0}"
log_files=$(ls -t *${log_pref}* 2>/dev/null)
num_log_files=$(echo "$log_files" | wc -l)
if [[ $num_log_files -gt $max_log_files ]]; then echo "Deleting oldest log files..."
    echo "$log_files" | tail -n +$(expr $max_log_files + 1) | xargs rm
fi
}
check_oldest

function var_checker(){
test .
if [ -z $dev ]; then cat $0 | grep -E 'dev=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'dev'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set dev=${dev}"; fi
if [ -z $type_port ]; then cat $0 | grep -E 'type_port=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'type_port'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set type_port=${type_port}"; fi
if [ -z $num_port ]; then cat $0 | grep -E 'num_port=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'num_port'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set num_port=${num_port}"; fi
if [ -z $section ]; then cat $0 | grep -E 'section=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'section'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set section=${section}"; fi
if [ -z $sleep_value_set_time ]; then cat $0 | grep -E 'sleep_value_set_time=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'sleep_value_set_time'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set sleep_value_set_time=${sleep_value_set_time}"; fi
if [ -z $sleep_value_reset_time ]; then cat $0 | grep -E 'sleep_value_reset_time=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'sleep_value_reset_time'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set sleep_value_reset_time=${sleep_value_reset_time}"; fi
printf "\n"
}
var_checker | tee $logfile

function sub_counter_set_time(){
pause_time="$sleep_value_set_time"
sleepvar=$((`date +%s` + $pause_time)); while [ "$sleepvar" -ne `date +%s` ]; do echo -ne "$(date -u --date @$(($sleepvar - `date +%s` )) +%H:%M:%S)\r"; done
}
function sub_counter_reset_time(){
pause_time="$sleep_value_reset_time"
sleepvar=$((`date +%s` + $pause_time)); while [ "$sleepvar" -ne `date +%s` ]; do echo -ne "$(date -u --date @$(($sleepvar - `date +%s` )) +%H:%M:%S)\r"; done
}

function main(){
rule_add(){
tc qdisc replace dev ${dev} root handle 1: htb ;
tc qdisc add dev ${dev} ingress handle ffff: ;
}
function rule_del(){
tc qdisc del dev ${dev} root handle 1: htb ;
tc qdisc del dev ${dev} ingress handle ffff ;
}
export -f rule_del
function set_value(){
#loop-state:>>
hex_low=$(tailing_low=$(cat /dev/urandom | hexdump -vn4 -e'4/4 "%08X" 1 "\n"'); echo 000000000$tailing_low | cut -c 1-8)
hex_rand=$(cat /dev/urandom | hexdump -vn4 -e'4/4 "%08X" 1 "\n"')

section=$(shuf -i $section_min-$section_max -n 1) #or: <123>
#section="92" #or: <123>
set_hex="$hex_rand"	#or: <hex_const>/<hex_low>/<hex_rand>
ports_list=($(cat port.list)); for each in "${ports_list[@]}"; do num_port=$each; done
#num_port="5030"

tc filter add dev ${dev} parent 1: u32 \
match ip ${type_port} ${num_port} 0xffff \
action pedit \
munge offset $((${section} & ~3)) ${data_type} set 0x${set_hex} \
pipe \
action csum \
tcp

}
while true; do {
echo "$(date +"%T.%3N") Applying filter" | tee -a $logfile
rule_add
set_value

function diff_timer(){
echo "$(date +"%T.%3N") Set timer affter use rule: [type_port: <${type_port}> num_port: <${num_port}> section: <${section}> hex value: <$(echo ${set_hex} | tail -c 8)>] (${sleep_value_set_time}sec) (check real sec: <$((${section} & ~3))>)" | tee -a $logfile
sub_counter_set_time
echo $(date +"%T.%3N") "Ended" | tee -a $logfile
}
function eq_timer(){
echo "$(date +"%T.%3N") Set timer affter use rule: [type_port: <${type_port}> num_port: <${num_port}> section: <${section}> hex value: <$(echo ${set_hex} | tail -c 8)>] (${sleep_value_reset_time}sec) (check real sec: <$((${section} & ~3))>)" | tee -a $logfile
sub_counter_reset_time
echo $(date +"%T.%3N") "Ended" | tee -a $logfile
}
:<<comment
eq_timers:		sleep_value_set_time  ==  sleep_value_reset_time / таймер сброса значения == таймеру установки значения
diff_timer:	sleep_value_set_time  !=  sleep_value_reset_time ;
использование таймеров <diff_timer> <eq_timer> не является обязательным условием
comment
diff_timer
#eq_timer

echo "$(date +"%T.%3N") Reset rule to default " | tee -a $logfile
rule_del 
sub_counter_reset_time	
} done
}

main #2>&1 | tee -a

}
