#!/bin/bash

# Test SNMP traps functionality
echo "Testing SNMP Traps functionality..."
echo "==================================="

# Test router traps
echo "Testing Router traps..."
snmptrap -v2c -c public 172.20.0.20:162 "" 1.3.6.1.6.3.1.1.5.1 1.3.6.1.2.1.1.3.0 i 12345 2>/dev/null
echo "  - coldStart trap sent"

snmptrap -v2c -c public 172.20.0.20:162 "" 1.3.6.1.6.3.1.1.5.4 1.3.6.1.2.1.1.3.0 i 12345 2>/dev/null
echo "  - linkUp trap sent"

snmptrap -v2c -c public 172.20.0.20:162 "" 1.3.6.1.6.3.1.1.5.5 1.3.6.1.2.1.1.3.0 i 12345 2>/dev/null
echo "  - authenticationFailure trap sent"

# Test switch traps
echo "Testing Switch traps..."
snmptrap -v2c -c public 172.20.0.20:162 "" 1.3.6.1.6.3.1.1.5.1 1.3.6.1.2.1.1.3.0 i 12345 2>/dev/null
echo "  - coldStart trap sent"

snmptrap -v2c -c public 172.20.0.20:162 "" 1.3.6.1.6.3.1.1.5.3 1.3.6.1.2.1.1.3.0 i 12345 2>/dev/null
echo "  - linkDown trap sent"

# Test firewall traps
echo "Testing Firewall traps..."
snmptrap -v2c -c public 172.20.0.20:162 "" 1.3.6.1.6.3.1.1.5.1 1.3.6.1.2.1.1.3.0 i 12345 2>/dev/null
echo "  - coldStart trap sent"

snmptrap -v2c -c public 172.20.0.20:162 "" 1.3.6.1.6.3.1.1.5.5 1.3.6.1.2.1.1.3.0 i 12345 2>/dev/null
echo "  - authenticationFailure trap sent"

echo ""
echo "All test traps sent successfully!"
echo "Check the Datadog agent logs with: docker logs datadog-agent"
