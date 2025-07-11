#!/bin/bash

# Set default values
DEVICE_TYPE=${DEVICE_TYPE:-router}
DEVICE_NAME=${DEVICE_NAME:-device-01}
SYS_DESCR=${SYS_DESCR:-"Generic Network Device"}
SYS_OBJECT_ID=${SYS_OBJECT_ID:-1.3.6.1.4.1.8072.3.2.10}
COMMUNITY=${COMMUNITY:-public}
TRAP_COMMUNITY=${TRAP_COMMUNITY:-public}
TRAP_DESTINATION=${TRAP_DESTINATION:-172.20.0.20}
TRAP_PORT=${TRAP_PORT:-162}

# Create snmpd configuration
cat > /etc/snmp/snmpd.conf << SNMPCONF
# Basic SNMP configuration
rocommunity $COMMUNITY default

# Trap configuration
trapsink $TRAP_DESTINATION $TRAP_COMMUNITY
trap2sink $TRAP_DESTINATION $TRAP_COMMUNITY

# System information
sysServices 76
sysLocation "Docker Container Lab"
sysContact "admin@example.com"
sysName "$DEVICE_NAME"
sysDescr "$SYS_DESCR"
sysObjectID $SYS_OBJECT_ID

# Interface information simulation
interface lo 24 1000000000
interface eth0 6 1000000000

# Disable AgentX
master agentx

# Log settings
logOption n

# Allow all OIDs to be accessed
view systemview included .1
view systemview included .1.3.6.1.2.1.1
view systemview included .1.3.6.1.2.1.2
view systemview included .1.3.6.1.2.1.3
view systemview included .1.3.6.1.2.1.4
view systemview included .1.3.6.1.2.1.5
view systemview included .1.3.6.1.2.1.6
view systemview included .1.3.6.1.2.1.7
view systemview included .1.3.6.1.2.1.8
view systemview included .1.3.6.1.2.1.9
view systemview included .1.3.6.1.2.1.10
view systemview included .1.3.6.1.2.1.11

# Create some fake data for different device types
SNMPCONF

# Add device-specific configuration
case $DEVICE_TYPE in
    router)
        cat >> /etc/snmp/snmpd.conf << ROUTERCONF
# Router-specific OIDs
override 1.3.6.1.2.1.1.1.0 octet_str "$SYS_DESCR"
override 1.3.6.1.2.1.1.2.0 objid $SYS_OBJECT_ID
override 1.3.6.1.2.1.1.3.0 timeticks 12345600
override 1.3.6.1.2.1.1.4.0 octet_str "Network Administrator"
override 1.3.6.1.2.1.1.5.0 octet_str "$DEVICE_NAME"
override 1.3.6.1.2.1.1.6.0 octet_str "Docker Container Lab"
override 1.3.6.1.2.1.1.7.0 integer 76

# Interface counters
override 1.3.6.1.2.1.2.1.0 integer 2
override 1.3.6.1.2.1.2.2.1.1.1 integer 1
override 1.3.6.1.2.1.2.2.1.1.2 integer 2
override 1.3.6.1.2.1.2.2.1.2.1 octet_str "lo"
override 1.3.6.1.2.1.2.2.1.2.2 octet_str "eth0"
override 1.3.6.1.2.1.2.2.1.3.1 integer 24
override 1.3.6.1.2.1.2.2.1.3.2 integer 6
override 1.3.6.1.2.1.2.2.1.5.1 gauge 10000000
override 1.3.6.1.2.1.2.2.1.5.2 gauge 1000000000
override 1.3.6.1.2.1.2.2.1.10.1 counter 1000000
override 1.3.6.1.2.1.2.2.1.10.2 counter 50000000
override 1.3.6.1.2.1.2.2.1.16.1 counter 1000000
override 1.3.6.1.2.1.2.2.1.16.2 counter 25000000
ROUTERCONF
        ;;
    switch)
        cat >> /etc/snmp/snmpd.conf << SWITCHCONF
# Switch-specific OIDs
override 1.3.6.1.2.1.1.1.0 octet_str "$SYS_DESCR"
override 1.3.6.1.2.1.1.2.0 objid $SYS_OBJECT_ID
override 1.3.6.1.2.1.1.3.0 timeticks 23456700
override 1.3.6.1.2.1.1.4.0 octet_str "Network Administrator"
override 1.3.6.1.2.1.1.5.0 octet_str "$DEVICE_NAME"
override 1.3.6.1.2.1.1.6.0 octet_str "Docker Container Lab"
override 1.3.6.1.2.1.1.7.0 integer 76

# More interfaces for switch
override 1.3.6.1.2.1.2.1.0 integer 24
SWITCHCONF
        ;;
    firewall)
        cat >> /etc/snmp/snmpd.conf << FIREWALLCONF
# Firewall-specific OIDs
override 1.3.6.1.2.1.1.1.0 octet_str "$SYS_DESCR"
override 1.3.6.1.2.1.1.2.0 objid $SYS_OBJECT_ID
override 1.3.6.1.2.1.1.3.0 timeticks 34567800
override 1.3.6.1.2.1.1.4.0 octet_str "Security Administrator"
override 1.3.6.1.2.1.1.5.0 octet_str "$DEVICE_NAME"
override 1.3.6.1.2.1.1.6.0 octet_str "Docker Container Lab"
override 1.3.6.1.2.1.1.7.0 integer 76
FIREWALLCONF
        ;;
esac

# Create trap generation script
cat > /usr/local/bin/generate_traps.sh << 'TRAPSCRIPT'
#!/bin/bash

DEVICE_TYPE=${DEVICE_TYPE:-router}
DEVICE_NAME=${DEVICE_NAME:-device-01}
TRAP_DESTINATION=${TRAP_DESTINATION:-172.20.0.20}
TRAP_COMMUNITY=${TRAP_COMMUNITY:-public}

# Function to send coldStart trap
send_coldstart() {
    snmptrap -v 2c -c $TRAP_COMMUNITY $TRAP_DESTINATION "" .1.3.6.1.6.3.1.1.5.1 \
        .1.3.6.1.2.1.1.3.0 t 123456 \
        .1.3.6.1.2.1.1.5.0 s "$DEVICE_NAME"
}

# Function to send interface up trap
send_interface_up() {
    local interface_id=$1
    snmptrap -v 2c -c $TRAP_COMMUNITY $TRAP_DESTINATION "" .1.3.6.1.6.3.1.1.5.4 \
        .1.3.6.1.2.1.1.3.0 t 123456 \
        .1.3.6.1.2.1.2.2.1.1.0 i $interface_id \
        .1.3.6.1.2.1.2.2.1.7.0 i 1
}

# Function to send interface down trap
send_interface_down() {
    local interface_id=$1
    snmptrap -v 2c -c $TRAP_COMMUNITY $TRAP_DESTINATION "" .1.3.6.1.6.3.1.1.5.3 \
        .1.3.6.1.2.1.1.3.0 t 123456 \
        .1.3.6.1.2.1.2.2.1.1.0 i $interface_id \
        .1.3.6.1.2.1.2.2.1.7.0 i 2
}

# Function to send authentication failure trap
send_auth_failure() {
    snmptrap -v 2c -c $TRAP_COMMUNITY $TRAP_DESTINATION "" .1.3.6.1.6.3.1.1.5.5 \
        .1.3.6.1.2.1.1.3.0 t 123456
}

# Function to send device-specific traps
send_device_specific_traps() {
    case $DEVICE_TYPE in
        router)
            # BGP peer down trap (simulated)
            snmptrap -v 2c -c $TRAP_COMMUNITY $TRAP_DESTINATION "" .1.3.6.1.4.1.9.9.187.1.2.1 \
                .1.3.6.1.2.1.1.3.0 t 123456 \
                .1.3.6.1.4.1.9.9.187.1.2.2.1.5.1 s "192.168.1.1"
            ;;
        switch)
            # Port security violation trap (simulated)
            snmptrap -v 2c -c $TRAP_COMMUNITY $TRAP_DESTINATION "" .1.3.6.1.4.1.9.9.315.1.2.1 \
                .1.3.6.1.2.1.1.3.0 t 123456 \
                .1.3.6.1.4.1.9.9.315.1.2.2.1.1.1 i 24 \
                .1.3.6.1.4.1.9.9.315.1.2.2.1.2.1 s "00:11:22:33:44:55"
            ;;
        firewall)
            # High CPU utilization trap (simulated)
            snmptrap -v 2c -c $TRAP_COMMUNITY $TRAP_DESTINATION "" .1.3.6.1.4.1.25461.2.1.3.2.0.1 \
                .1.3.6.1.2.1.1.3.0 t 123456 \
                .1.3.6.1.4.1.25461.2.1.3.2.1.1.2.1 i 95
            ;;
    esac
}

# Main trap generation loop
while true; do
    sleep_time=$((RANDOM % 300 + 60))  # Random sleep between 60-360 seconds
    
    # Generate random trap
    trap_type=$((RANDOM % 10))
    
    case $trap_type in
        0|1)
            echo "$(date): Sending interface up trap"
            send_interface_up $((RANDOM % 4 + 1))
            ;;
        2)
            echo "$(date): Sending interface down trap"
            send_interface_down $((RANDOM % 4 + 1))
            ;;
        3)
            echo "$(date): Sending authentication failure trap"
            send_auth_failure
            ;;
        4|5)
            echo "$(date): Sending device-specific trap"
            send_device_specific_traps
            ;;
        *)
            echo "$(date): Sending coldStart trap"
            send_coldstart
            ;;
    esac
    
    echo "$(date): Sleeping for $sleep_time seconds"
    sleep $sleep_time
done
TRAPSCRIPT

chmod +x /usr/local/bin/generate_traps.sh

# Start SNMP daemon in background
echo "Starting SNMP daemon for $DEVICE_TYPE device: $DEVICE_NAME"
snmpd -f -Lo -c /etc/snmp/snmpd.conf &

# Wait for SNMP daemon to start
sleep 5

# Send initial coldStart trap
echo "Sending initial coldStart trap"
snmptrap -v 2c -c $TRAP_COMMUNITY $TRAP_DESTINATION "" .1.3.6.1.6.3.1.1.5.1 \
    .1.3.6.1.2.1.1.3.0 t 123456 \
    .1.3.6.1.2.1.1.5.0 s "$DEVICE_NAME"

# Start trap generation in background
echo "Starting trap generation process"
/usr/local/bin/generate_traps.sh &

# Keep the main process running
wait
