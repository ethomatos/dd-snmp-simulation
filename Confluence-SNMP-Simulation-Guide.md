# Datadog SNMP Network Device Monitoring - Docker Simulation Lab with Traps

## Overview

This guide provides a complete Docker-based simulation environment for testing Datadog's Network Device Monitoring (NDM) and SNMP integration capabilities with **full SNMP trap support**. The setup eliminates the need for physical network hardware by creating containerized SNMP-enabled devices that respond to queries AND generate realistic SNMP traps just like real network equipment.

## Business Value

- **Cost Savings**: No need for physical network devices for testing
- **Comprehensive Testing**: Both SNMP polling and trap reception testing
- **Rapid Prototyping**: Quickly test NDM configurations and trap handling
- **Training**: Safe environment for learning SNMP and network monitoring
- **CI/CD Integration**: Automated testing of monitoring configurations and alerting
- **Event-Driven Monitoring**: Test proactive monitoring scenarios with traps
- **Scalability**: Easy to add/remove simulated devices and trap scenarios

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Host (MacBook Pro)                    │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   SNMP Router   │  │   SNMP Switch   │  │ SNMP Firewall   │ │
│  │  172.20.0.10    │  │  172.20.0.11    │  │  172.20.0.12    │ │
│  │   Port: 161     │  │   Port: 161     │  │   Port: 161     │ │
│  │  📡 Trap Gen    │  │  📡 Trap Gen    │  │  📡 Trap Gen    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│           │                     │                     │         │
│           └─────────────────────┼─────────────────────┘         │
│                                 │ SNMP Traps (Port 162)         │
│  ┌────────┴─────────────────────┴─────────────────────┴──────┐  │
│  │              Docker Network (172.20.0.0/16)              │  │
│  └────────────────────────────┬─────────────────────────────┘  │
│                               │                                │
│  ┌─────────────────────────────┴─────────────────────────────┐  │
│  │                 Datadog Agent                             │  │
│  │            (NDM/SNMP Integration)                         │  │
│  │              🎯 Trap Listener                             │  │
│  │                172.20.0.20                               │  │
│  └───────────────────────────────────────────────────────────┘  │
│                               │                                │
└───────────────────────────────┼────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │    Datadog Cloud      │
                    │ (Metrics, Logs, Events)│
                    └───────────────────────┘
```

## New Feature: SNMP Trap Support 🚨

### What's New
- **Automated Trap Generation**: Each device generates realistic SNMP traps
- **Trap Reception**: Datadog agent configured to receive and process traps
- **Device-Specific Traps**: Different trap types per device category
- **Realistic Scenarios**: Interface changes, security events, performance alerts
- **Testing Tools**: Comprehensive trap testing utilities

### Trap Types Supported

| Trap Type | OID | Description | Frequency |
|-----------|-----|-------------|-----------|
| coldStart | .1.3.6.1.6.3.1.1.5.1 | Device startup | On container start |
| linkUp | .1.3.6.1.6.3.1.1.5.4 | Interface up | Random intervals |
| linkDown | .1.3.6.1.6.3.1.1.5.3 | Interface down | Random intervals |
| authenticationFailure | .1.3.6.1.6.3.1.1.5.5 | Auth failure | Occasional |
| BGP Peer Down | .1.3.6.1.4.1.9.9.187.1.2.1 | Router-specific | Router only |
| Port Security Violation | .1.3.6.1.4.1.9.9.315.1.2.1 | Switch-specific | Switch only |
| High CPU Utilization | .1.3.6.1.4.1.25461.2.1.3.2.0.1 | Firewall-specific | Firewall only |

## Simulated Devices

| Device Type | IP Address   | SNMP Port | Trap Dest | Device Model | System OID |
|-------------|-------------|-----------|-----------|--------------|-------------|
| Router      | 172.20.0.10 | 161       | 172.20.0.20:162 | Cisco IOS Router | 1.3.6.1.4.1.9.1.1 |
| Switch      | 172.20.0.11 | 161       | 172.20.0.20:162 | Cisco Catalyst Switch | 1.3.6.1.4.1.9.1.208 |
| Firewall    | 172.20.0.12 | 161       | 172.20.0.20:162 | Palo Alto Firewall | 1.3.6.1.4.1.25461.2.3.1 |
| Datadog Agent | 172.20.0.20 | 162 (traps) | - | Agent | - |

## Prerequisites

### Required Software
- **Docker Desktop**: Latest version
- **Docker Compose**: v3.8+ support
- **Datadog Account**: With API key access
- **SNMP Tools** (optional, for testing): `brew install net-snmp` on macOS

### Required Access
- Datadog API key with appropriate permissions
- Docker Hub access (for pulling base images)

## Setup Instructions

### Step 1: Download the Simulation Files

The simulation consists of the following enhanced file structure:

```
datadog-snmp-simulation/
├── docker-compose.yml              # Enhanced with trap support
├── .env.template
├── README.md
├── start-simulation.sh
├── stop-simulation.sh
├── test-traps.sh                   # 🆕 Trap testing utilities
├── snmp-devices/
│   ├── Dockerfile
│   ├── entrypoint.sh               # 🆕 Enhanced with trap generation
│   └── [config directories]
└── datadog-config/
    ├── snmp.d/
    │   └── conf.yaml              # SNMP polling config
    └── snmp_traps.d/              # 🆕 Trap configuration
        └── conf.yaml
```

Contact your DevOps team or download from the shared repository.

### Step 2: Environment Configuration

1. **Navigate to the simulation directory**:
   ```bash
   cd datadog-snmp-simulation
   ```

2. **Create environment file**:
   ```bash
   cp .env.template .env
   ```

3. **Configure your Datadog API key**:
   Edit `.env` file and replace `your_datadog_api_key_here` with your actual API key:
   ```bash
   DD_API_KEY=your_actual_api_key_here
   DD_SITE=datadoghq.com  # Change if using different Datadog site
   ```

### Step 3: Start the Simulation

**Option A: Using the convenience script (recommended)**:
```bash
./start-simulation.sh
```

**Option B: Manual startup**:
```bash
docker-compose up -d
```

### Step 4: Verify Setup

1. **Check container status**:
   ```bash
   docker-compose ps
   ```

2. **Test SNMP connectivity**:
   ```bash
   # Test each device
   snmpget -v2c -c public localhost:161 1.3.6.1.2.1.1.1.0  # Router
   snmpget -v2c -c public localhost:1162 1.3.6.1.2.1.1.1.0  # Switch
   snmpget -v2c -c public localhost:163 1.3.6.1.2.1.1.1.0  # Firewall
   ```

3. **Test SNMP trap functionality**:
   ```bash
   ./test-traps.sh all
   ```

4. **Check Datadog agent logs**:
   ```bash
   docker logs datadog-agent
   ```

## Monitoring in Datadog

### SNMP Traps in Datadog

#### Location 1: Logs
- Navigate to **Logs** → **Live Search**
- Filter by `source:snmp`
- Look for trap events with specific OIDs

#### Location 2: Events Stream
- Go to **Events** → **Event Stream**
- Filter by `source:snmp-traps`
- See trap-triggered events

#### Location 3: Network Map
- Navigate to **Network** → **Network Map**
- Device events appear as notifications on device nodes
- Trap-based alerts show as colored indicators

### Regular SNMP Metrics
- **Metrics Explorer**: Search for metrics starting with `snmp.*`
- **Dashboards**: Create custom dashboards combining polling and trap data
- **Alerts**: Set up alerts on both metric thresholds and trap events

## Testing Scenarios

### Basic SNMP Queries
```bash
# System information
snmpwalk -v2c -c public localhost:161 1.3.6.1.2.1.1

# Interface information
snmpwalk -v2c -c public localhost:161 1.3.6.1.2.1.2
```

### SNMP Trap Testing

#### Automated Testing
```bash
# Run all trap tests
./test-traps.sh all

# Check trap generation logs
./test-traps.sh logs

# View Datadog agent trap logs
./test-traps.sh datadog

# Show trap statistics
./test-traps.sh stats
```

#### Manual Trap Testing
```bash
# Send test trap directly
./test-traps.sh test

# Trigger device-specific traps
./test-traps.sh trigger

# Send custom trap
snmptrap -v 2c -c public localhost:1162 "" .1.3.6.1.6.3.1.1.5.1 \
  .1.3.6.1.2.1.1.3.0 t 123456 \
  .1.3.6.1.2.1.1.5.0 s "test-device"
```

### Datadog Integration Tests
```bash
# Check agent status
docker exec datadog-agent agent status

# Test SNMP polling
docker exec datadog-agent agent check snmp

# Test trap reception
docker exec datadog-agent agent status | grep -A 10 "snmp_traps"
```

## Advanced Testing Scenarios

### Scenario 1: Interface Flapping
Test rapid interface up/down events:
```bash
# Generate multiple interface events
for i in {1..5}; do
  docker exec snmp-router-sim snmptrap -v 2c -c public 172.20.0.20 "" .1.3.6.1.6.3.1.1.5.3 \
    .1.3.6.1.2.1.1.3.0 t 123456 \
    .1.3.6.1.2.1.2.2.1.1.0 i $i
  sleep 2
done
```

### Scenario 2: Security Events
Test authentication failures:
```bash
# Generate auth failure traps
./test-traps.sh trigger
```

### Scenario 3: Performance Alerts
Test high utilization scenarios:
```bash
# Check firewall high CPU trap
docker logs snmp-firewall-sim | grep -i "high cpu"
```

## Troubleshooting

### Common Issues

#### 1. Traps Not Being Received
**Symptoms**: No trap events in Datadog logs

**Diagnosis**:
```bash
# Check trap generation
./test-traps.sh logs

# Verify trap listener
docker exec datadog-agent netstat -ulnp | grep 162

# Test trap port
telnet localhost 162
```

**Solutions**:
- Verify port 162 is not blocked
- Check Datadog agent trap configuration
- Ensure containers can reach 172.20.0.20

#### 2. Trap Generation Stopped
**Symptoms**: No recent trap activity in device logs

**Diagnosis**:
```bash
# Check trap processes
./test-traps.sh stats

# Verify background processes
docker exec snmp-router-sim ps aux | grep generate_traps
```

**Solutions**:
- Restart containers: `docker-compose restart`
- Check container logs for errors
- Verify script permissions

#### 3. Datadog Agent Trap Config Issues
**Symptoms**: Agent logs show trap configuration errors

**Diagnosis**:
```bash
# Check agent configuration
docker exec datadog-agent agent configcheck

# Verify trap config
docker exec datadog-agent cat /etc/datadog-agent/conf.d/snmp_traps.d/conf.yaml
```

**Solutions**:
- Verify trap community strings match
- Check YAML syntax
- Restart agent: `docker restart datadog-agent`

### Log Analysis Commands

```bash
# Device trap generation logs
docker logs snmp-router-sim | grep -i trap
docker logs snmp-switch-sim | grep -i trap
docker logs snmp-firewall-sim | grep -i trap

# Datadog agent trap logs
docker logs datadog-agent | grep -i trap
docker logs datadog-agent | grep -i snmp

# Real-time trap monitoring
docker logs -f datadog-agent | grep trap
```

## Advanced Configuration

### Custom Trap Scenarios

Edit `snmp-devices/entrypoint.sh` to add custom trap types:

```bash
# Add custom trap function
send_custom_trap() {
    snmptrap -v 2c -c $TRAP_COMMUNITY $TRAP_DESTINATION "" .1.3.6.1.4.1.9999.1.1.1 \
        .1.3.6.1.2.1.1.3.0 t 123456 \
        .1.3.6.1.4.1.9999.1.1.2 s "Custom event occurred"
}
```

### Trap Frequency Adjustment

Modify trap generation timing:
```bash
# In entrypoint.sh, change sleep time
sleep_time=$((RANDOM % 300 + 60))  # 60-360 seconds
# To:
sleep_time=$((RANDOM % 60 + 30))   # 30-90 seconds (more frequent)
```

### SNMP v3 Trap Configuration

For SNMP v3 traps with authentication:
```bash
# Add to snmpd.conf
createUser trapuser MD5 trappassword DES trapencryption
```

## Performance Considerations

### Trap Volume
- **Low**: 1-6 traps per device per hour
- **Medium**: 10-20 traps per device per hour  
- **High**: 50+ traps per device per hour

### Datadog Impact
- Each trap = 1 log entry in Datadog
- Monitor your log ingestion quota
- Consider filtering traps by importance

### Resource Usage
- **CPU**: Minimal impact (<1% per device)
- **Memory**: ~10MB additional per device
- **Network**: ~1KB per trap

## Maintenance

### Regular Tasks

1. **Monitor trap generation**:
   ```bash
   ./test-traps.sh stats
   ```

2. **Clean up old containers**:
   ```bash
   docker system prune -f
   ```

3. **Update configurations**:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

### Scaling Considerations

- **Adding devices**: Each device adds ~1-6 traps/hour
- **Trap frequency**: Adjust based on testing needs
- **Datadog quotas**: Monitor log ingestion limits
- **Network load**: Consider trap batching for high volumes

## Security Considerations

### Current Setup
- Uses default SNMP community strings (public)
- Trap community strings set to public
- No authentication for trap reception
- Containers isolated on Docker network

### Production Recommendations
- Implement SNMP v3 with authentication
- Use custom community strings
- Enable network segmentation
- Regular security updates of base images
- Consider trap filtering and rate limiting

## Stopping the Simulation

**Option A: Using convenience script**:
```bash
./stop-simulation.sh
```

**Option B: Manual shutdown**:
```bash
docker-compose down
```

**Complete cleanup**:
```bash
docker-compose down --rmi all
```

## Support and Resources

### Internal Support
- **DevOps Team**: Docker/infrastructure issues
- **Monitoring Team**: Datadog configuration and trap handling
- **Network Team**: SNMP protocol questions
- **Security Team**: Trap authentication and security

### External Resources
- [Datadog SNMP Traps Documentation](https://docs.datadoghq.com/network_monitoring/devices/snmp_traps/)
- [SNMP Trap Protocol Reference](https://tools.ietf.org/html/rfc3416)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

### Useful Links
- **Datadog Network Map**: https://app.datadoghq.com/network/map
- **Datadog Logs**: https://app.datadoghq.com/logs
- **Datadog Events**: https://app.datadoghq.com/event/stream

---

## Appendix

### Trap Testing Reference

| Command | Purpose |
|---------|---------|
| `./test-traps.sh test` | Send test trap |
| `./test-traps.sh trigger` | Generate device-specific traps |
| `./test-traps.sh logs` | Check trap generation logs |
| `./test-traps.sh datadog` | Check Datadog trap logs |
| `./test-traps.sh stats` | Show trap statistics |
| `./test-traps.sh all` | Run all tests |

### Common Trap OIDs

| OID | Standard Name | Description |
|-----|---------------|-------------|
| .1.3.6.1.6.3.1.1.5.1 | coldStart | Device restart |
| .1.3.6.1.6.3.1.1.5.2 | warmStart | Device warm restart |
| .1.3.6.1.6.3.1.1.5.3 | linkDown | Interface down |
| .1.3.6.1.6.3.1.1.5.4 | linkUp | Interface up |
| .1.3.6.1.6.3.1.1.5.5 | authenticationFailure | Auth failure |

### Port Mapping Reference

| Container | Internal Port | External Port | Purpose |
|-----------|---------------|---------------|---------|
| snmp-router-sim | 161/udp | 161/udp | SNMP queries |
| snmp-switch-sim | 161/udp | 162/udp | SNMP queries |
| snmp-firewall-sim | 161/udp | 163/udp | SNMP queries |
| datadog-agent | 162/udp | 162/udp | SNMP traps |

### Datadog Trap Filtering

To filter traps in Datadog:
```
# In Logs, use filters like:
source:snmp @trap.oid:.1.3.6.1.6.3.1.1.5.1  # Only coldStart traps
source:snmp @device.type:router               # Only router traps
source:snmp @trap.severity:critical          # Only critical traps
```

---

*Document Version: 2.0*  
*Last Updated: [Current Date]*  
*Maintained by: [Your Team Name]*  
*Enhanced with: SNMP Trap Support*
