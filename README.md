# *WireGuard* - *Site 2 Site* with *Kathara*

This explains how to generate a network with *Kathara*, that connects two sites with a *WireGuard* tunnel.
```
Endpoint A1   /==WireGuard==\   Endpoint B1
         \   //             \\   /
         Host A - Internet - Host B
         /                       \
Endpoint A2                     Endpoint B2
```

As the hosts are connected, the endpoints don't even know about the *WireGuard* tunnel. They are connected as they would be in a *LAN* (*Local Area Network*). This could be used by an organisation to connect two sites to each other, as this way the information transmitted over the internet is encrypted.

## Network Configuration
In more technical terms, a network configuration from one endpoint to another looks like the following - this depicts the connection from Endpoint A1 - Host A - Internet Router - Host B - Endpoint B1. The *WireGuard* interface is added on the right, but is actually configured another way.

```bash
ip address add 192.168.1.2/24 dev eth0
ip route add default via 192.168.1.1
|
ip address add 192.168.1.1/24 dev eth0
ip route add 10.0.0.4/30 via 10.0.0.2
ip address add 10.0.0.1/30 dev eth1
|                 ip address 10.100.0.1 wg0
|                                         |
ip address add 10.0.0.2/30 dev eth0       |
ip route add 192.168.1.0/24 via 10.0.0.1  |
sysctl -w net.ipv4.ip_forward=1           |
ip route add 192.168.2.0/24 via 10.0.0.5  |
ip address add 10.0.0.6/30 dev eth1       |
|                                         |
|                 ip address 10.100.0.2 wg0
ip address add 10.0.0.5/30 dev eth1
ip route add 10.0.0.0/30 via 10.0.0.6
ip address add 192.168.2.1/24 dev eth0
|
ip route add default via 192.168.2.1
ip address add 192.168.2.2/24 dev eth0
```

## Setup extracting the *WireGuard* handshakes

To be able to extract the *WireGuard* handshakes, a make command needs to be issued.

```bash
cd WireGuard/contrib/examples/extract-handshakes/
make
```

On Ubuntu 24 the `extract_handshakes.sh` script needed to be adapted slightly.

```diff
diff --git a/contrib/examples/extract-handshakes/extract-handshakes.sh b/contrib/examples/extract-handshakes/extract-handshakes.sh
index f794ffe..0141153 100755
--- a/contrib/examples/extract-handshakes/extract-handshakes.sh
+++ b/contrib/examples/extract-handshakes/extract-handshakes.sh
@@ -43,7 +43,7 @@ turn_off() {
 }
 
 trap turn_off INT TERM EXIT
-echo "p:wireguard/idxadd index_hashtable_insert ${ARGS[*]}" >> /sys/kernel/debug/tracing/kprobe_events
+echo "p:wireguard/idxadd wg_index_hashtable_insert ${ARGS[*]}" >> /sys/kernel/debug/tracing/kprobe_events
 echo 1 > /sys/kernel/debug/tracing/events/wireguard/idxadd/enable
 
 unpack_u64() {
```

## Run the lab

To run the lab the following commands can be used inside the directory of the repository.

```bash
# Populate the network
kathara lstart

# Capture the traffic running through the internet router
kathara exec inet "tcpdump -i any -w /shared/inet.pcap" &

# Get keys of the WireGuard channel
sudo ./WireGuard/contrib/examples/extract-handshakes/extract-handshakes.sh > keylog.log &

# Exchange keys of hosts and set up the WireGuard channel
bash setup_vpn.sh

# Generate traffic on the WireGuard channel
kathara exec a1 "ping -c 5 192.168.2.2"

# Analyze the captured traffic with Wireshark, consider the keys
wireshark shared/inet.pcap --log-level=debug -owg.keylog_file:keylog.log

# Stop the lab
kathara wipe
```

This way the `inet.pcap` file can be analyzed in *Wireshark* and it shows the expected *WireGuard* packets. Dissecting *WireGuard* packets is included in the latest versions of *Wireshark*.

## References
- For the general lab: https://www.procustodibus.com/blog/2020/12/wireguard-site-to-site-config/
- For dissecting *WireGuard* with *Wireshark*: https://blog.salrashid.dev/articles/2022/wireguard_wireshark/