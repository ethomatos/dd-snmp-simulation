#!/bin/bash

echo "🛑 Stopping Datadog SNMP Network Device Simulation"
echo "=================================================="

# Stop containers
echo "🏗️  Stopping containers..."
docker-compose down

echo "🧹 Cleanup completed!"
echo ""
echo "To remove images as well, run:"
echo "  docker-compose down --rmi all"
echo ""
echo "To start again, run:"
echo "  ./start-simulation.sh"
