FROM ubuntu:20.04

# Install SNMP daemon and tools
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    snmpd \
    snmp \
    snmp-mibs-downloader \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Download and install additional MIBs
RUN download-mibs

# Create directories
RUN mkdir -p /var/lib/snmp /etc/snmp

# Copy startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose SNMP port
EXPOSE 161/udp

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
