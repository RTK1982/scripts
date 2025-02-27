#!/bin/bash

# Get a list of all Docker network names
network_names=$(docker network ls --format "{{.Name}}")

# Loop through each network name
for network in $network_names; do
  echo "Eigenschaften Netzwerk: $network"
  echo "--------------------------------------"
  
  # Inspect the network and filter the output
  docker network inspect "$network" | grep -E '"Name":|"Id":|"Driver":|"Subnet":|"Gateway":|("Name"| "EndpointID"| "MacAddress"| "IPv4Address")' | \
  sed 's/^[[:space:]]*//' | \
  awk '1; /IPv4Address/ {print "--------------------------------------"}'

  echo "--------------------------------------"
  echo ""
done
