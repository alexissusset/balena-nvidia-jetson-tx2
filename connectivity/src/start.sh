#!/bin/bash
# Setting DBUS addresss so that we can talk to Modem Manager
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/host/run/dbus/system_bus_socket"

# Setup logging function
function log {
	if [[ "${CONSOLE_LOGGING}" == "1" ]]; then
		echo "[$(date --rfc-3339=seconds)]: $*" >>/data/soracom.log;
		echo "$*";
	else
    	echo "[$(date --rfc-3339=seconds)]: $*" >>/data/soracom.log;
    fi
}

# Check if CONSOLE_LOGGING is set, otherwise indicate that logging is going to /data/soracom.log
if [[ "${CONSOLE_LOGGING}" == "1" ]]; then
	echo "CONSOLE_LOGGING is set to 1, logging to console and /data/soracom.log"
else
	echo "CONSOLE_LOGGING isn't set to 1, logging to /data/soracom.log"
fi


# Start OpenSSHD
if [[ -n "${SSH_PASSWD+x}" ]]; then
	#Set the root password
	echo "root:$SSH_PASSWD" | chpasswd
    mkdir /var/run/sshd \
    && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
	# Check if we already have host keys 
	if [ ! -f /data/openssh/ssh_host_dsa_key ]; then
    	# Take a copy of host keys
    	log "ssh host keys backup do not exists yet, making a copy"
		mkdir /data/openssh
		cp /etc/ssh/ssh_host* /data/openssh/
    else
    	cp /data/openssh/* /etc/ssh/
	fi  
	#Start opensshd
	log "`service ssh start`"
fi

# Start Linux watchdog
log "`service watchdog start`"

# Add Soracom Network Manager connection
log "`python soracom.py`"

# Save current Jetson CPU, GPU and EMC clocks configuration and increase to max power
if [[ -n "${JETSON_OVERCLOCK+x}" ]]; then
    log "`/home/nvidia/jetson_clocks.sh --store ${HOME}/l4t_dfs.conf`"
    log "`/home/nvidia/jetson_clocks.sh`"
fi

# Switching USB Dongle to Modem mode (currently supports FS01BU, AK-20 and MS2131)
if [[ -n "${MODEM_MODE+x}" ]]; then
	for x in 1c9e:98ff 15eb:a403 12d1:14fe
		do
			if (lsusb | grep $x > /dev/null)
			then
				log "Found un-initilized modem. Trying to initialize it ..."
				log "`eval $(echo $x | tr : \  | awk '{print \"/usr/sbin/usb_modeswitch -v $1 -p $2 -J\"}')`"
			fi
		done
fi

# Check if we should disable non-cellular connectivity
if [[ -n "${CELLULAR_ONLY+x}" ]]; then
	log "Starting device in Cellular mode"
	ls /sys/class/net | grep -q wlan0
	if [[ $? -eq 0 ]]; then
		ifconfig wlan0 down
	fi
	ls /sys/class/net | grep -q eth0
	if [[ $? -eq 0 ]]; then
		ifconfig eth0 down
	fi
else
	ls /sys/class/net | grep -q wlan0
	if [[ $? -eq 0 ]]; then
		ifconfig wlan0 up
	fi
	ls /sys/class/net | grep -q eth0
	if [[ $? -eq 0 ]]; then
		ifconfig eth0 up
	fi
fi

# Make sure we catch SIGHUP, SIGINT and SIGTERM
trap "echo 'Stopping main script'; exit" SIGHUP SIGINT SIGTERM

# Run connection check script every 500 seconds
# If Cellular Mode wasn't working, the device will reboot every 15mins until it works
while :
do
	# If a mmcli compatible modem is present, log signal quality
	mmcli -L | grep -q Modem
	if [ $? -eq 0 ]; then
		MODEM_NUMBER=`mmcli -L | grep Modem | head -1 | sed -e 's/\//\ /g' | awk '{print $5}'`
		mmcli -m ${MODEM_NUMBER} | grep state | grep -q connected
		if [ $? -eq 0 ]; then
			# Log signal quality
			if [[ -n "${MODEM_NUMBER+x}" ]]; then
				log "`mmcli -m ${MODEM_NUMBER} | grep 'access tech' | sed -e \"s/'//g\" | sed -e \"s/|//g\" | sed -e \":a;s/^\([[:space:]]*\)[[:space:]]//g\"`"
				log "`mmcli -m ${MODEM_NUMBER} | grep 'operator name' | sed -e \"s/'//g\" | sed -e \"s/|//g\" | sed -e ':a;s/^\([[:space:]]*\)[[:space:]]//g'`"
				log "`mmcli -m ${MODEM_NUMBER} | grep quality | sed -e \"s/'//g\" | awk '{print $2 " " $3 " " $4}'`%"
				log "`mmcli -m ${MODEM_NUMBER} --command='AT+CSQ'`"
			fi
		fi
	fi
	sleep 500;
	# Rotate log files
	log "`logrotate /usr/src/app/logrotate.conf`"
	# Check if internet connectivity is working, reboot if it isn't
	log "`/usr/src/app/reconnect.sh`"
done
