#!/bin/bash

set -e

echo "🚀 Starting Datadog SNMP Network Device Simulation with Traps"
echo "============================================================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Please copy .env.template to .env and add your Datadog API key:"
    echo "  cp .env.template .env"
    echo "  # Edit .env file and add your DD_API_KEY"
    exit 1
fi

# Source environment variables
source .env

# Check if API key is set
if [ -z "$DD_API_KEY" ] || [ "$DD_API_KEY" = "your_datadog_api_key_here" ]; then
    echo "❌ Datadog API key not configured!"
    echo "Please edit .env file and set your DD_API_KEY"
    exit 1
fi

echo "✅ Configuration validated"

# Start containers
echo "🏗️  Building and starting containers..."
docker-compose up -d

echo "⏳ Waiting for containers to be ready..."
sleep 15

# Check if containers are running
echo "🔍 Checking container status..."
docker-compose ps

# Test SNMP connectivity
echo "🧪 Testing SNMP connectivity..."
if command -v snmpget &> /dev/null; then
    echo "Testing Router (localhost:161)..."
    snmpget -v2c -c public localhost:161 1.3.6.1.2.1.1.1.0 2>/dev/null && echo "✅ Router responding" || echo "❌ Router not responding"
    
    echo "Testing Switch (localhost:1162)..."
    snmpget -v2c -c public localhost:1162 1.3.6.1.2.1.1.1.0 2>/dev/null && echo "✅ Switch responding" || echo "❌ Switch not responding"
    
    echo "Testing Firewall (localhost:163)..."
    snmpget -v2c -c public localhost:163 1.3.6.1.2.1.1.1.0 2>/dev/null && echo "✅ Firewall responding" || echo "❌ Firewall not responding"
else
    echo "⚠️  snmp tools not installed locally - skipping connectivity test"
    echo "You can install them with: brew install net-snmp (on macOS)"
fi

# Test trap functionality
echo "📡 Testing SNMP trap functionality..."
if [ -x ./test-traps.sh ]; then
    echo "Running trap connectivity test..."
    ./test-traps.sh test 2>/dev/null && echo "✅ Trap test successful" || echo "⚠️  Trap test failed (may need snmp tools)"
else
    echo "⚠️  test-traps.sh not found or not executable"
fi

# Check trap generation
echo "🔍 Checking trap generation..."
sleep 5
trap_count=0
for container in snmp-router-sim snmp-switch-sim snmp-firewall-sim; do
    if docker logs $container 2>/dev/null | grep -qi "trap\|sending" | head -1; then
        trap_count=$((trap_count + 1))
    fi
done

if [ $trap_count -gt 0 ]; then
    echo "✅ Trap generation active ($trap_count/3 devices)"
else
    echo "⚠️  No trap activity detected yet (may take a few minutes)"
fi

echo ""
echo "🎉 Simulation is running with SNMP Traps!"
echo "=========================================="
echo "📊 Datadog Monitoring:"
echo "  • Network Map: https://app.datadoghq.com/network/map"
echo "  • Metrics Explorer: https://app.datadoghq.com/metric/explorer"
echo "  • Logs (Traps): https://app.datadoghq.com/logs (filter: source:snmp)"
echo "  • Events: https://app.datadoghq.com/event/stream"
echo ""
echo "🛠️  Testing Commands:"
echo "  ./test-traps.sh all                       # Test all trap functionality"
echo "  ./test-traps.sh trigger                   # Generate device-specific traps"
echo "  ./test-traps.sh logs                      # Check trap generation logs"
echo "  docker logs datadog-agent | grep trap     # Check agent trap logs"
echo ""
echo "�� Management Commands:"
echo "  docker logs datadog-agent                 # Check agent logs"
echo "  docker exec datadog-agent agent status   # Check agent status"
echo "  docker-compose logs                       # View all container logs"
echo "  docker-compose down                       # Stop simulation"
echo ""
echo "📡 SNMP Trap Features:"
echo "  • Automatic trap generation every 1-6 minutes"
echo "  • Device-specific traps (BGP, port security, CPU alerts)"
echo "  • Standard MIB-II traps (coldStart, linkUp/Down, authFailure)"
echo "  • Datadog trap reception and processing"
echo ""
echo "Happy monitoring with SNMP traps! 🚀📡"
