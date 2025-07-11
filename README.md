# Datadog SNMP Network Device Monitoring Simulation with Traps

This Docker setup creates simulated network devices that respond to SNMP queries AND generate SNMP traps, plus a Datadog agent configured to monitor them. Perfect for testing Datadog's Network Device Monitoring (NDM) integration and SNMP trap reception without physical hardware.

## Architecture

The setup includes:
- **3 SNMP Device Simulators**: Router, Switch, and Firewall with trap generation
- **1 Datadog Agent**: Configured to monitor devices and receive SNMP traps
- **Docker Network**: All containers on the same network for communication
- **Automated Trap Generation**: Devices send realistic traps at random intervals

## New Features: SNMP Traps

🚨 **SNMP Trap Support**: Each device now generates realistic SNMP traps including:
- **coldStart** traps on startup
- **linkUp/linkDown** traps for interface changes
- **authenticationFailure** traps for security events
- **Device-specific traps** (BGP peer down, port security violations, high CPU, etc.)

## Prerequisites

- Docker and Docker Compose installed
- Datadog API key

## Quick Start

1. **Clone or download this setup to your local machine**

2. **Configure your Datadog API key**:
   ```bash
   cp .env.template .env
   # Edit .env file and add your Datadog API key
   ```

3. **Start the simulation**:
   ```bash
   ./start-simulation.sh
   ```

4. **Test SNMP trap functionality**:
   ```bash
   ./test-traps.sh all
   ```

5. **Verify SNMP devices are responding**:
   ```bash
   # Test router
   snmpwalk -v2c -c public localhost:161 1.3.6.1.2.1.1.1.0
   
   # Test switch  
   snmpwalk -v2c -c public localhost:1162 1.3.6.1.2.1.1.1.0
   
   # Test firewall
   snmpwalk -v2c -c public localhost:163 1.3.6.1.2.1.1.1.0
   ```

6. **Monitor traps in Datadog**:
   - Go to Logs: https://app.datadoghq.com/logs
   - Filter by `source:snmp` to see trap events
   - Check Network Map for device events

## Device Details

### Router Simulator
- **IP**: 172.20.0.10 (exposed on localhost:161)
- **Type**: Cisco IOS Router
- **SNMP Community**: public
- **System OID**: 1.3.6.1.4.1.9.1.1
- **Trap Types**: coldStart, linkUp/Down, BGP peer events

### Switch Simulator  
- **IP**: 172.20.0.11 (exposed on localhost:1162)
- **Type**: Cisco Catalyst Switch
- **SNMP Community**: public
- **System OID**: 1.3.6.1.4.1.9.1.208
- **Trap Types**: coldStart, linkUp/Down, port security violations

### Firewall Simulator
- **IP**: 172.20.0.12 (exposed on localhost:163)
- **Type**: Palo Alto Firewall
- **SNMP Community**: public
- **System OID**: 1.3.6.1.4.1.25461.2.3.1
- **Trap Types**: coldStart, linkUp/Down, high CPU utilization

### Datadog Agent
- **IP**: 172.20.0.20
- **Trap Port**: 162/udp (exposed on localhost:1162)
- **Community**: public
- **Configuration**: NDM + SNMP traps enabled

## SNMP Trap Details

### Standard Traps Generated
- **coldStart** (`.1.3.6.1.6.3.1.1.5.1`) - Device startup
- **linkUp** (`.1.3.6.1.6.3.1.1.5.4`) - Interface up
- **linkDown** (`.1.3.6.1.6.3.1.1.5.3`) - Interface down
- **authenticationFailure** (`.1.3.6.1.6.3.1.1.5.5`) - Auth failure

### Device-Specific Traps
- **Router**: BGP peer down events
- **Switch**: Port security violations
- **Firewall**: High CPU utilization alerts

### Trap Generation Schedule
- **Initial**: coldStart trap on container startup
- **Periodic**: Random traps every 60-360 seconds
- **Realistic**: Interface up/down events are most common
- **Manual**: Use `./test-traps.sh trigger` for immediate traps

## Supported MIB-II Variables

Each device responds to standard MIB-II OIDs including:
- `1.3.6.1.2.1.1.1.0` - sysDescr
- `1.3.6.1.2.1.1.2.0` - sysObjectID  
- `1.3.6.1.2.1.1.3.0` - sysUpTime
- `1.3.6.1.2.1.1.4.0` - sysContact
- `1.3.6.1.2.1.1.5.0` - sysName
- `1.3.6.1.2.1.1.6.0` - sysLocation
- `1.3.6.1.2.1.1.7.0` - sysServices
- `1.3.6.1.2.1.2.*` - Interface information
- And many more standard MIB-II variables

## Testing Commands

### SNMP Testing Commands

```bash
# Test basic connectivity
snmpget -v2c -c public localhost:161 1.3.6.1.2.1.1.1.0

# Walk the entire MIB tree
snmpwalk -v2c -c public localhost:161 1.3.6.1.2.1

# Test specific MIB-II branches
snmpwalk -v2c -c public localhost:161 1.3.6.1.2.1.1    # System info
snmpwalk -v2c -c public localhost:161 1.3.6.1.2.1.2    # Interfaces
snmpwalk -v2c -c public localhost:161 1.3.6.1.2.1.4    # IP info
```

### SNMP Trap Testing Commands

```bash
# Run all trap tests
./test-traps.sh all

# Send manual test trap
./test-traps.sh test

# Check device trap logs
./test-traps.sh logs

# Check Datadog agent trap logs
./test-traps.sh datadog

# Trigger device-specific traps
./test-traps.sh trigger

# Show trap statistics
./test-traps.sh stats
```

### Datadog Agent Testing

```bash
# Check agent status
docker exec datadog-agent agent status

# Check SNMP integration status
docker exec datadog-agent agent status | grep -A 10 snmp

# Run a connectivity test
docker exec datadog-agent agent check snmp

# Check trap listener status
docker exec datadog-agent agent status | grep -A 10 "snmp_traps"
```

## Monitoring in Datadog

### SNMP Traps in Datadog
1. **Logs**: Navigate to Logs and filter by `source:snmp`
2. **Events**: Check the Events stream for trap-based events
3. **Network Map**: Device events appear as notifications
4. **Dashboards**: Create custom dashboards with trap metrics

### Regular SNMP Metrics
1. **Network Devices** appear in the Datadog Network Map
2. **Metrics** flowing in for each device
3. **Logs** from the SNMP integration
4. **Tags** applied to distinguish between device types

Navigate to:
- **Network** > **Network Map** to see your devices
- **Metrics** > **Explorer** to query SNMP metrics
- **Logs** to see SNMP integration and trap logs

## Customization

### Adding More Devices

To add another device with trap support, add a new service to `docker-compose.yml`:

```yaml
snmp-server:
  build: ./snmp-devices
  container_name: snmp-server-sim
  hostname: server-01
  ports:
    - "164:161/udp"
  environment:
    - DEVICE_TYPE=server
    - DEVICE_NAME=server-01
    - SYS_DESCR=Linux Server Simulator
    - SYS_OBJECT_ID=1.3.6.1.4.1.8072.3.2.10
    - TRAP_DESTINATION=172.20.0.20
    - TRAP_COMMUNITY=public
  depends_on:
    - datadog-agent
  networks:
    snmp-network:
      ipv4_address: 172.20.0.13
```

### Customizing Trap Generation

Edit `snmp-devices/entrypoint.sh` to modify:
- Trap generation frequency
- Trap types and OIDs
- Device-specific trap scenarios
- Trap payloads and variables

### Changing SNMP Communities

Modify the `COMMUNITY` and `TRAP_COMMUNITY` environment variables:

```yaml
environment:
  - COMMUNITY=private
  - TRAP_COMMUNITY=trap-community
```

## Troubleshooting

### SNMP Devices Not Responding

```bash
# Check if containers are running
docker ps

# Check container logs
docker logs snmp-router-sim
docker logs snmp-switch-sim
docker logs snmp-firewall-sim

# Test network connectivity
docker exec datadog-agent ping 172.20.0.10
```

### SNMP Traps Not Being Received

```bash
# Check trap generation logs
./test-traps.sh logs

# Check Datadog agent trap logs
./test-traps.sh datadog

# Verify trap port is open
docker exec datadog-agent netstat -ulnp | grep 162

# Test manual trap
./test-traps.sh test
```

### Datadog Agent Issues

```bash
# Check agent logs
docker logs datadog-agent

# Validate configuration
docker exec datadog-agent agent configcheck

# Check integration status
docker exec datadog-agent agent status
```

### Network Issues

```bash
# Check Docker network
docker network ls
docker network inspect datadog-snmp-simulation_snmp-network

# Test SNMP from host
snmpwalk -v2c -c public localhost:161 1.3.6.1.2.1.1.1.0
```

## Performance Notes

### Trap Generation Impact
- Each device generates 1-6 traps per hour
- Trap generation uses minimal CPU/memory
- No impact on SNMP query performance
- Traps are generated in background processes

### Scaling Considerations
- More devices = more traps = more Datadog log ingestion
- Monitor your Datadog log quota if running long-term
- Adjust trap frequency in `entrypoint.sh` if needed

## Cleanup

To stop and remove all containers:

```bash
./stop-simulation.sh
```

Or manually:

```bash
docker-compose down
```

To remove images as well:

```bash
docker-compose down --rmi all
```

## Security Notes

- This setup uses default SNMP community strings (public)
- Trap community strings are also set to public
- Containers are isolated on a Docker network
- Only intended for testing/simulation purposes
- Do not use these configurations in production

## Next Steps

- Experiment with different device profiles
- Add custom MIB variables and traps
- Create dashboards in Datadog with trap events
- Set up alerting based on specific trap types
- Test SNMP v3 with authentication
- Create custom trap scenarios for testing

## Files Overview

```
datadog-snmp-simulation/
├── docker-compose.yml              # Container orchestration with traps
├── .env.template                   # Environment variables
├── README.md                      # This file
├── start-simulation.sh            # Startup script
├── stop-simulation.sh             # Shutdown script
├── test-traps.sh                  # Trap testing utilities
├── snmp-devices/
│   ├── Dockerfile                 # SNMP device image
│   ├── entrypoint.sh             # Device config + trap generation
│   └── [config directories]      # Device-specific configs
└── datadog-config/
    ├── snmp.d/
    │   └── conf.yaml              # SNMP polling config
    └── snmp_traps.d/
        └── conf.yaml              # SNMP trap config
```

Happy monitoring with SNMP traps! 🚀📡
