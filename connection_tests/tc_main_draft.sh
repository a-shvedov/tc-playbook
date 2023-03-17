dev1="enp0s8"
dev2="enp0s9"
#run_itter=3

increment_loss_rand="n"
increase_delay="n"
increment_corr="n"
corr_rand="y"
decrement_loss="n"
increase_delay_targetport="n"

make_increment_loss_rand() {

f_name="make_increment_loss_rand"
logfile=$(basename -s .sh ${0})_$(printf '%(%s)T\n' -1)_$f_name.log

check_oldest(){
max_log_files=3
log_pref="$f_name"
log_files=$(ls -t *${log_pref}* 2>/dev/null)
num_log_files=$(echo "$log_files" | wc -l)
if [[ $num_log_files -gt $max_log_files ]]; then echo "Deleting oldest log files..."
    echo "$log_files" | tail -n +$(expr $max_log_files + 1) | xargs rm
fi
}
check_oldest

echo "call func:make_increment_loss_rand" | grep "[[:alnum:]]" --colour=always
declare iface="$dev1"

function preset_filters(){
tc qdisc del dev $iface root netem loss 0.0% 
tc qdisc add dev $iface root netem loss 0.0%
tc qdisc show dev $iface | tee -a $logfile
}
export -f preset_filters

trap 'echo "$f_name interrupted"; exit' INT
while true; do
#for (( c=1; c<=$run_itter; c++)); do

perloss_start="80"
perloss_end="99"
percent_variable_loss="75" #<25>
incperc="1"
sleepvar="1" #user value
delimiter="1000"
date_msec=$(date +"%T.%3N")

declare current_per=$perloss_start
while [ $current_per -lt $perloss_end ]; do
sysrand=$(( $RANDOM + $perloss_start / 4 )) # range: 0 - 100
tailing=`echo $sysrand | tail -c 3 `
percent_variable_loss_rand=$(( $RANDOM + $percent_variable_loss / 4 )) # -""-
echo "$(date +"%T.%3N") Make corrupt interface ${iface} with randow value" ${tailing}"%" "with delay ${sleepvar} sec" | tee -a $logfile
   current_per=$(( $current_per + $incperc ));
   sleepvalue=$(( $current_per / $delimiter + $sleepvar ));
   tc qdisc change dev $iface root netem loss ${sysrand}% ${percent_variable_loss_rand}%;
   tc qdisc show dev $iface | tee -a $logfile
   sleep $sleepvalue ; 
   echo $(date +"%T.%3N") "Ended" | tee -a $logfile
   
   function repair_default(){
   preset_filters #<drop to default state>
   echo $(date +"%T.%3N") "Repair default (${sleepvalue} sec)" | tee -a $logfile
   sleep $sleepvalue ;
   }
   repair_default
done
done
}

make_increase_delay_targetport() {
logfile=$(basename ${0})_$(printf '%(%s)T\n' -1).log
echo "+call func:make_increase_delay_targetport" | grep "[[:alnum:]]" --colour=always
echo "+call func:make_increase_delay_targetport" > $logfile

iface="$dev1" #<dev2>
type_port="dport" #<sport>
tcpdump_type_port="dst" #<src>
port="9000"	#<9000>
start_value="50" #<200>
step_increase="15" #<20>
target_delay="600" #<100>
constsleepvar="5" #default value (sec) #<6>
delimiter="1000" #default value #<1000>

function var_checker(){
if [ -z $iface ]; then cat $0 | grep -E 'iface=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'$iface'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set iface=${iface}"; fi
if [ -z $type_port ]; then cat $0 | grep -E 'type_port=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'$type_port'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set type_port=${type_port}"; fi
if [ -z $port ]; then cat $0 | grep -E 'port=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'$port'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set port=${port}"; fi
if [ -z $start_value ]; then cat $0 | grep -E 'start_value=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'$start_value'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set start_value=${start_value}"; fi
if [ -z $step_increase ]; then cat $0 | grep -E 'step_increase=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'$step_increase'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set step_increase=${step_increase}"; fi
if [ -z $target_delay ]; then cat $0 | grep -E 'target_delay=' --colour=always | grep -v "cat"; printf "\n"; echo "check var::'$target_delay'" | grep "[[:alnum:]]" --colour=always && exit; else echo "Set target_delay=${target_delay}"; fi
printf "\n"
}
function uvk_ckecker() {
started_value=$(ps -awwuuxx| grep -E 'start_proc|sync_proc' | grep -v grep | wc -l)
}
function preset(){
tc qdisc del dev $iface root
tc qdisc del dev $iface root handle 1: prio priomap 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
tc qdisc add dev $iface root handle 1: prio priomap 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
tc qdisc add dev $iface parent 1:2 handle 20: netem delay 0ms
tc filter add dev $iface parent 1:0 protocol ip u32 match ip ${type_port} ${port} 0xffff flowid 1:2
}

function kill_tcpdump_save(){
tcpdump_pid_name=$(ps -ef | grep tcpdump | awk -F ' ' '{print $2}' | head -n 1);
if [ ${tcpdump_pid_name} -eq 1 ]; then :; else killall ${tcpdump_pid_name}; fi
}
export -f kill_tcpdump_save

function tcpdump_save(){
kill_tcpdump_save 2> /dev/null
nohup tcpdump -i $iface $tcpdump_type_port port $port -w ${logfile}_${iface}_${port}.pcap &
}

var_checker | tee -a $logfile
uvk_ckecker
preset 2> /dev/null
tcpdump_save 2> /dev/null

while true; do		#dynamic loop
export -f kill_tcpdump_save
declare current_per=$start_value
while [ ${current_per} -lt ${target_delay} ]; do
proc_count_by_the_fly=$(ps -awwuuxx| grep -E 'start_proc|sync_proc' | grep -v grep | wc -l)
if [ $started_value != $proc_count_by_the_fly ]; 
	then echo $(date +"%T.%3N") "Probably UVK down: ended this work!"; 
	echo $(date +"%T.%3N") "+call func:preset" >> $logfile
	preset 2> /dev/null ;
	tc qdisc show dev $iface >> $logfile ;
	kill_tcpdump_save 2> /dev/null #если остановку uvk инициирует другой процесс, киляния не происходит, поробовать решить через killall; ## ^C (ok); 
	kill -9 $$; 
	else :; fi | tee -a $logfile

sysrand=$(( $RANDOM / 8 )) # range: 0 - 8000
sleepvar=$(($sysrand)) #or <constsleepvar>
sleepvar_rand=$(($sysrand / 1000)) #or <constsleepvar>
sleep_affter_set_count=$(( $constsleepvar / $constsleepvar )) #установка значения меньше таймера сброса

current_per=$(( ${current_per} + ${step_increase} ));
   sleepvalue=$(( $current_per / $delimiter ));
   echo "$(date +"%T.%3N") Delay increased to ${current_per} (target: ${target_delay})" | tee -a $logfile
   tc qdisc change dev $iface parent 1:2 handle 20: netem delay ${current_per}ms ;
   tc qdisc show dev $iface | grep "delay" | grep "[[:alnum:]]" --colour=always
   tc qdisc show dev $iface >> $logfile
   
   function sleep_affter_set(){
   set_value="$sleep_affter_set_count" # <sleepvar_rand> - randon value; <constsleepvar> - установка значения = установке сброса <sleep_affter_set_count> - determine value: '$constsleepvar'/'$constsleepvar'
   echo $(date +"%T.%3N") Sleeping ${set_value} seconds | tee -a $logfile	
   sleep $set_value ;
   echo $(date +"%T.%3N") "Ended" | tee -a $logfile
   }
   sleep_affter_set
   
   function repair_default(){
   test .
   tc qdisc del dev $iface root handle 1: prio priomap 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
   tc qdisc show dev $iface | grep "delay" | grep "[[:alnum:]]" --colour=always
   tc qdisc show dev $iface >> $logfile
   
   tc qdisc add dev $iface root handle 1: prio priomap 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
   tc qdisc add dev $iface parent 1:2 handle 20: netem delay 0.0ms
   tc filter add dev $iface parent 1:0 protocol ip u32 match ip ${type_port} ${port} 0xffff flowid 1:2
   
   function sub_rand(){
   echo $(date +"%T.%3N") "Repair default (${sleepvar_rand} sec)" | tee -a $logfile
   sleep ${sleepvar_rand} ;
   }
   function sub_const(){
   echo $(date +"%T.%3N") "Repair default (${constsleepvar} sec)" | tee -a $logfile
   sleep ${constsleepvar} ;
   }
   #sub_rand
   sub_const
   }
#   repair_default
done
done
}


make_increase_delay() {
#имитация задержек: ожидаемый результат в одиночном режиме - получение некорректных timestamp
logfile=$(basename ${0})_$(printf '%(%s)T\n' -1).log
echo "call func:make_increase_delay" | grep "[[:alnum:]]" --colour=always
echo "call func:make_increase_delay" > $logfile
iface="$dev1"
step_increase="50" #указывается в мсек
target_delay="10000" #"="
pause="1" #начальное значение задержки; итоговое значение на каждый шаг задержки - $sleepvalue
start_value="200"
delimiter="1000"

tc qdisc del dev ${iface} root
tc qdisc add dev ${iface} root netem delay 0.0ms

echo  $(date +"%T.%3N") "Increasing delay for interface ${iface} by ${step_increase}ms from ${5}ms to ${target_delay}ms" | tee -a $logfile
declare current_per=${start_value}
while [ ${current_per} -lt ${target_delay} ]; do
   current_per=$(( ${current_per} + ${step_increase} ));
   sleepvalue=$(( ${current_per} / ${delimiter} + ${pause} ));
   echo "$(date +"%T.%3N") Delay increased to ${current_per} (target: ${target_delay})" | tee -a $logfile
   tc qdisc change dev ${iface} root netem delay ${current_per}ms
   tc qdisc show dev ${iface};
   echo $(date +"%T.%3N") Sleeping ${sleepvalue} seconds | tee -a $logfile	
   sleep ${sleepvalue} ; echo $(date +"%T.%3N") "Ended" | tee -a $logfile
done
	function repair_default(){
	test .
	tc qdisc del dev $iface root netem delay 0.0ms
	tc qdisc show dev $iface | tee -a $logfile
	tc qdisc add dev $iface root netem delay 0.0ms
	echo $(date +"%T.%3N") "Repaired default state" | tee -a $logfile
	}
#repair_default
}


make_increment_corr() {
logfile=$(basename ${0})_$(printf '%(%s)T\n' -1).log
echo "call func:make_increment_corr" | grep "[[:alnum:]]" --colour=always
echo "call func:make_increment_corr" > $logfile
iface="$dev1"
percorrupt_start="80"
percorrupt_end="99"
incperc="1"
sleepvar="3"
delimiter="10000"

tc qdisc del dev ${iface} root
tc qdisc add dev ${iface} root netem corrupt 0.0%

while true; do
declare current_per=${percorrupt_start}
while [ ${current_per} -lt ${percorrupt_end} ]; do
echo $(date +"%T.%3N") "Increasing corrupt percent for interface ${iface} by ${percorrupt_start} to ${percorrupt_end} with delay ${sleepvar} sec" | tee -a $logfile
   current_per=$(( ${current_per} + ${incperc} ));		
declare -x sleepvalue=$(( ${current_per} / ${delimiter} + ${sleepvar} ));
   tc qdisc change dev ${iface} root netem corrupt ${current_per}%;
   tc qdisc show dev ${iface} | tee -a $logfile
   sleep ${sleepvalue} ; 
   echo $(date +"%T.%3N") "Ended" | tee -a $logfile
done
   repair_default(){
   test .
   tc qdisc del dev $iface root netem corrupt 0.0;
  # tc qdisc add dev $iface root netem corrupt 0.0%
   tc qdisc show dev $iface | tee -a $logfile
   echo $(date +"%T.%3N") "Repair default (${sleepvalue} sec)" | tee -a $logfile
   sleep $sleepvalue ;
   }
#  repair_default
done
}

make_corr_rand() {
logfile=$(basename ${0})_$(printf '%(%s)T\n' -1).log
echo "call func:make_corr_rand" | grep "[[:alnum:]]" --colour=always
echo "call func:make_corr_rand" > $logfile
while true; do
iface="$dev1"
percorrupt_start="5"
percorrupt_end="10"
incperc="1"
delay="3"
delimiter="2500" # при <5000> rand >=10сек; при <2500> rand >=15сек; <1250> rand >=30сек; 
date_msec=$(date +"%T.%3N")

tc qdisc del dev ${iface} root
tc qdisc add dev ${iface} root netem corrupt 0.0%

declare current_per=${percorrupt_start}
while [ ${current_per} -lt ${percorrupt_end} ]; do
sysrand=$(( ${RANDOM} + ${percorrupt_start} / 4 )) #correct range: 0 - 100
tailing=`echo $sysrand | tail -c 3 `
echo "$(date +"%T.%3N") Make corrupt interface ${iface} with randow value" ${tailing}"%" | tee -a $logfile
current_per=$(( ${current_per} + ${incperc} ));
sleepvalue_stat=$(( ${current_per} / ${delimiter} + ${delay} )); #check it -ok
sleepvalue_rand=$(( ${RANDOM} / ${delimiter} + ${delay} )); #check it - ok
tc qdisc change dev ${iface} root netem corrupt ${sysrand}%;
tc qdisc show dev ${iface} | tee -a $logfile

function rand_delay(){
pause_time="$sleepvalue_rand"
sleepvar=$((`date +%s` + ${pause_time})); while [ "$sleepvar" -ne `date +%s` ]; 
	do echo -ne "$(date -u --date @$(($sleepvar - `date +%s` )) +%H:%M:%S)\r"; done
}
function stat_delay(){
pause_time="$sleepvalue_stat"
sleepvar=$((`date +%s` + ${pause_time})); while [ "$sleepvar" -ne `date +%s` ]; 
	do echo -ne "$(date -u --date @$(($sleepvar - `date +%s` )) +%H:%M:%S)\r"; done
}
   function rand_delay_log(){
	echo $(date +"%T.%3N") "Applying random delay ${sleepvalue_rand} sec affter setup" | tee -a $logfile
	rand_delay;
	echo $(date +"%T.%3N") "Ended" | tee -a $logfile
   }
   function stat_delay_log(){
	echo $(date +"%T.%3N") "Applying static delay ${sleepvalue_stat} sec affter setup" | tee -a $logfile
	stat_delay ;
   echo $(date +"%T.%3N") "Ended" | tee -a $logfile
   }
   function repair_default(){
   test .
   tc qdisc del dev $iface root netem corrupt 0.0%
   tc qdisc add dev $iface root netem corrupt 0.0%
   tc qdisc show dev $iface | tee -a $logfile
   echo $(date +"%T.%3N") "Repair default (${sleepvalue_rand} sec)" | tee -a $logfile
   sleep $sleepvalue_rand ;
   }
<<comment
   <rand_delay_log>	- установка значения с динамической задержкой
   <stat_delay_log>	- установка значения со статической задержкой
   <repair_default>	- по-умолчанию выставлено значение <sleepvalue_rand> (|| <sleepvalue_stat>)
comment
   rand_delay_log 
   #stat_delay_log
   #repair_default
done
done
}

make_decrement_loss() {
logfile=$(basename ${0})_$(printf '%(%s)T\n' -1).log
echo "call func:make_decrement_loss" | grep "[[:alnum:]]" --colour=always
echo "call func:make_decrement_loss" > $logfile
iface="$dev1"
maxval="100"
percorrupt_decr="99" 
incperc="1"
sleepvar="10"
delimiter="1000"
date_msec=$(date +"%T.%3N")

tc qdisc del dev ${iface} root
tc qdisc add dev ${iface} root netem loss 0.0%

stat_delay(){
test .
pause_time="$sleepvar"
sleepvar_stat=$((`date +%s` + $pause_time)); while [ "$sleepvar" -ne `date +%s` ]; do echo -ne "$(date -u --date @$(($sleepvar - `date +%s` )) +%H:%M:%S)\r"; done
}
declare current_per=$percorrupt_decr
tailing=`echo $percorrupt_decr | tail -c 3 `
while [ $current_per -lt $maxval ]; do
echo "$(date +"%T.%3N") Decremention loop for interface ${iface} with value" ${tailing}"%" "with delay ${sleepvar} sec"  | tee -a $logfile
   current_per=$(( $current_per - $incperc ));
   sleepvalue=$(( $current_per / $delimiter + $sleepvar ));
   tc qdisc change dev ${iface} root netem loss ${current_per}%
   tc qdisc show dev $iface | tee -a $logfile
   #stat_delay
   sleep $sleepvalue ; 
   echo $(date +"%T.%3N") "Ended" | tee -a $logfile
done
}
