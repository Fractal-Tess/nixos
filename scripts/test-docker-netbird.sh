#!/bin/bash

# Test script to verify Docker can use Netbird DNS
# Run this after applying the NixOS configuration changes

echo "Testing Docker DNS resolution with Netbird..."

# Test 1: Check if Docker daemon is running
echo "1. Checking Docker daemon status..."
if systemctl is-active --quiet docker; then
    echo "✓ Docker daemon is running"
else
    echo "✗ Docker daemon is not running"
    exit 1
fi

# Test 2: Check Docker daemon configuration
echo "2. Checking Docker daemon configuration..."
if docker info | grep -q "100.91.242.113"; then
    echo "✓ Netbird DNS (100.91.242.113) is configured in Docker"
else
    echo "✗ Netbird DNS not found in Docker configuration"
fi

# Test 3: Test DNS resolution from Docker container
echo "3. Testing DNS resolution from Docker container..."
echo "   Running test container with nslookup..."

docker run --rm --dns=100.91.242.113 debian:bullseye-slim nslookup google.com 100.91.242.113

if [ $? -eq 0 ]; then
    echo "✓ DNS resolution through Netbird DNS successful"
else
    echo "✗ DNS resolution through Netbird DNS failed"
fi

# Test 4: Test connectivity to Netbird network
echo "4. Testing connectivity to Netbird network..."
echo "   Running test container to ping Netbird DNS..."

docker run --rm --dns=100.91.242.113 debian:bullseye-slim ping -c 3 100.91.242.113

if [ $? -eq 0 ]; then
    echo "✓ Connectivity to Netbird DNS successful"
else
    echo "✗ Connectivity to Netbird DNS failed"
fi

# Test 5: Test resolution of Netbird domains
echo "5. Testing resolution of Netbird domains..."
echo "   Testing resolution of oracle.netbird.cloud..."

docker run --rm --dns=100.91.242.113 debian:bullseye-slim nslookup oracle.netbird.cloud 100.91.242.113

if [ $? -eq 0 ]; then
    echo "✓ Netbird domain resolution successful"
else
    echo "✗ Netbird domain resolution failed"
fi

echo ""
echo "Test completed. Check the output above for any failures."
echo ""
echo "If tests fail, you may need to:"
echo "1. Rebuild and switch to the new NixOS configuration"
echo "2. Restart the Docker service: sudo systemctl restart docker"
echo "3. Check firewall rules: sudo iptables -L FORWARD"
echo "4. Verify Netbird service is running: sudo systemctl status netbird"
