# Installing and using [rtorrent](https://rakshasa.github.io/rtorrent/) on SME9.2

## Prerequisites

* [Configure the EPEL Repository](https://wiki.contribs.org/Epel#tab=For_SME_9_x)

## Installation

```
yum --enablerepo=epel install rtorrent
```

## Configuration
Note: I ran these instructions as root.  **This is a bad idea**.
You should create an unprivileged user account with access to the desired ibay and run rtorrent only as that user.

### rtorrent configuration

* copy the default rtorrent.rc file to your home directory

```
cp /usr/share/doc/rtorrent-0.9.4/rtorrent.rc ~/.rtorrent.rc
vi ~/.rtorrent.rc
# on my system I made the changes noted in the diff output below...
```

<details><summary>diff -u /usr/share/doc/rtorrent-0.9.4/rtorrent.rc ./.rtorrent.rc</summary>

```
--- /usr/share/doc/rtorrent-0.9.4/rtorrent.rc	2012-10-31 04:55:45.000000000 -0400
+++ ./.rtorrent.rc	2021-01-23 09:19:22.233319802 -0500
@@ -3,7 +3,7 @@
 # uncomment the options you wish to enable.
 
 # Maximum and minimum number of peers to connect to per torrent.
-#min_peers = 40
+min_peers = 3
 #max_peers = 100
 
 # Same as above but for seeding completed torrents (-1 = same as downloading)
@@ -14,8 +14,8 @@
 #max_uploads = 15
 
 # Global upload and download rate in KiB. "0" for unlimited.
-#download_rate = 0
-#upload_rate = 0
+#download_rate = 300
+#upload_rate = 300
 
 # Default directory to save the downloaded torrents.
 #directory = ./
@@ -44,6 +44,7 @@
 
 # Port range to use for listening.
 #port_range = 6890-6999
+port_range = 49164-49164
 
 # Start opening ports at a random position within the port range.
 #port_random = no
@@ -73,12 +74,12 @@
 # "auto" (start and stop DHT as needed), or "on" (start DHT immediately).
 # The default is "off". For DHT to work, a session directory must be defined.
 # 
-# dht = auto
+dht = auto
 
 # UDP port to use for DHT. 
 # 
-# dht_port = 6881
+dht_port = 6881
 
 # Enable peer exchange (for torrents not marked private)
 #
-# peer_exchange = yes
+peer_exchange = yes
```

</details>

### SME Service Configuration

Create a SME "service" to control firewall settings related to the ports configured for rtorrent

```
config set rtorrent service TCPPorts '6881,49164' UDPPorts '6881,49164' access public status enabled
signal-event remoteaccess-update
```

### Firewall Configuration

If your SME server is in "server-only" mode behind a firewally, you will need to add a rule in your firewall to forward the rtorrent ports (6881 and 49164 in this howto) to the SME server. 

## Testing and Using rtorrent

The ubuntu torrent download seems to work well as a test torrent...

```
mkdir -p /home/e-smith/files/ibays/Primary/html/torrents
cd /home/e-smith/files/ibays/Primary/html/torrents
rtorrent https://releases.ubuntu.com/20.04/ubuntu-20.04.1-live-server-amd64.iso.torrent
```

* ```rtorrent -h``` displays a help screen
* Press Ctrl-q to quit and exit

<details><summary>Press down arrow to select a torrent</summary>

```
                                             *** rTorrent 0.9.4/0.13.4 - office:22427 ***
[View: main]
*  ubuntu-20.04.1-live-server-amd64.iso
*            265.9 /  914.0 MB Rate:   0.0 / 2245.8 KB Uploaded:     0.0 MB [27%]  0d  0:04 [   R: 0.00 low]
*
```

</details>

<details><summary>Press right arrow to see details</summary>

```
                                                 *** ubuntu-20.04.1-live-server-amd64.iso ***
                 IP              UP     DOWN   PEER   CT/RE/LO  QS    DONE  REQ   SNUB  FAILED
Peer list        108.45.182.211  0.0    16.2   0.0    l /Ui/ui  0/16   99   2727               DelugeTorrent 1.3.15.0
                 158.69.244.241  0.0    32.8   0.0    l /Un/ci  0/17  100   1925               libTorrent 0.13.6.0
Info             185.21.216.143  0.0    377.6  0.0    l /Un/ci  0/68  100   1965               libTorrent 0.13.6.0
                 5.196.74.53     0.0    180.9  0.0    l /Un/ci  0/51  100   1947               libTorrent 0.13.8.0
File list        195.154.150.121 0.0    39.1   0.0    l /Un/ci  0/25  100   428                libTorrent 0.13.6.0
                 51.158.148.183  0.0    22.8   0.0    l /Un/ci  0/18  100   2646               libTorrent 0.13.8.0
Tracker list     83.149.106.206  0.0    22.2   0.0    l /Un/ci  0/20  100   2673               libTorrent 0.13.7.0
                 213.227.140.4   0.0    234.3  0.0    l /Un/ci  0/57  100   1955               libTorrent 0.13.8.0
Chunks seen	 78.142.107.43   0.0    17.8   0.0    l /Un/ci  0/18  100   443                libTorrent 0.13.7.0
                 167.248.166.105 0.0    1.5    10.2   l /Un/ci  0/3   100   411                uTorrent 2.2.1.0
Transfer list    128.211.255.116 0.0    41.0   0.0    l /Un/ci  0/23  100   2633               Transmission 3.0.0.0
                 193.11.162.193  0.0    32.6   0.0    l /Un/ci  0/21  100   2634               Transmission 2.9.4.0
                 51.178.172.112  0.0    30.5   0.0    l /Un/ci  0/24  100   482                Transmission 2.9.4.0
                 213.163.240.69  0.0    2.3    0.0    R /Un/ci  0/4   100   1963               Transmission 2.9.4.0
                 80.210.74.155   0.0    44.3   0.0    l /Un/ci  0/19  100   2718               Transmission 2.9.2.0
                 104.152.133.135 0.0    0.0    0.0    R /Qn/ci  0/0   100                      Transmission 3.0.0.0
                 185.34.241.59   0.0    7.4    0.0    R /Un/ci  0/9   100   1954               Transmission 2.9.4.0
                 77.56.26.88     0.0    4.8    0.0    l /Un/ci  0/6   100   1945               DelugeTorrent 1.3.15.0
                 109.195.163.32  0.0    23.9   0.0    l /Un/ci  0/21  100   3620               Transmission 2.9.4.0
                 154.3.42.41     0.0    211.6  0.0    l /Un/ci  0/45  100   1977               Transmission 3.0.0.0
                 45.81.32.125    0.0    219.5  0.0    l /Un/ci  0/56  100   1972               Transmission 3.0.0.0
                 51.174.215.38   0.0    27.9   0.0    l /Un/ci  0/22  100   2669               Transmission 3.0.0.0
                 185.149.90.25   0.0    19.9   0.0    l /Un/ci  0/18  100   2661               libTorrent 0.13.6.0
                 94.114.55.88    0.0    344.2  0.0    l /Un/ci  0/73  100   1980               Transmission 3.0.0.0
                 87.68.165.225   0.0    5.0    0.0    R /Un/ci  0/6   100   616                Transmission 2.9.4.0
                 125.161.141.217 0.0    1.8    0.0    l /Un/ci  0/3   100   2708               Transmission 2.9.4.0
                 91.219.25.170   0.0    5.5    0.0    l /Un/ci  0/7   100   2660               Transmission 3.0.0.0
                 185.51.60.103   0.0    18.0   0.0    l /Un/ci  0/15  100   2720               Unknown
                 82.38.32.45     0.0    18.4   0.0    R /Un/ci  0/18  100   2661               Transmission 2.9.2.0
            93.1 /  914.0 MB Rate:   0.0 / 1595.6 KB Uploaded:     0.0 MB [ 8%]  0d  0:08 [   R: 0.00 low]
Peers: 72(76) Min/Max: 13/200 Slots: U:3/51 D:0/50 U/I/C/A: 1/1/71/1 Unchoked: 1/50 Failed: 0
[ :1772]
[Throttle  51/off KB] [Rate   4.7/1603.1 KB] [Port: 49164]                            [U 1/20] [D 50/0] [H 0/32] [S 8/81/768] [F 1/128]
```

</details>

* Keep rtorrent running in the background using [the linux screen command](https://www.howtogeek.com/662422/how-to-use-linuxs-screen-command/)

* Monitor network connections from bash using ``` netstat -an |egrep "6881|49164"```

### Running rtorrent as a non-privileged user

Since rtorrent needs to be remotely accessible to the world, it is a good idea to run as a non-privileged user to avoid problems that might crop up due to bugs in the program or other issues.

The "user" in question can be an ibay on SME Server.

1. Create an ibay to use for running rtorrent and as the download destination for torrents
  * Information bay name: ```rtorrent```
  * Description: ```torrents```
  * Group: ```Everyone```
  * User access via file sharing or user ftp: ```Write=group, Read=group```
  * Public access via web or anonymous ftp: ```Entire internet (no password required)```
  * Execution of dynamic content (CGI, PHP, SSI): ```Enabled```<br>
    (not required for rtorrent itself, but maybe you would later want to install [ruTorrent](https://github.com/Novik/ruTorrent))
  * Force secure connections: ```Enabled```<br>
    (not required for rtorrent, but why not?)

1. Create rtorrent configuration file
  
  ```
  cp /usr/share/doc/rtorrent-0.9.4/rtorrent.rc /home/e-smith/files/ibays/rtorrent/files/.rtorrent.rc
  vi /home/e-smith/files/ibays/rtorrent/files/.rtorrent.rc
  #
  # set the options appropriate for your situation
  # the rest of this howto assumes that you set at least these options:
  #
  # directory = /home/e-smith/files/ibays/rtorrent/html/torrents
  # port_range = 49164-49164
  # dht_port = 6881
  # peer_exchange = yes
  ```
  
1. Set some ibay details...

  ```
  # create a folder for downloads 
  # put it in 'html' to be web-visible
  # put it in 'files' to be SMB-visible (and change the value of 'directory' in .rtorrent.rc...)
  mkdir -p /home/e-smith/files/ibays/rtorrent/html/torrents
  
  #
  # Allow the ibay group ("shared") to write in the new folder
  chmod g+w /home/e-smith/files/ibays/rtorrent/html/torrents
  ```
  
1. Run (& test)

  ```
  sudo -u rtorrent rtorrent https://releases.ubuntu.com/20.04/ubuntu-20.04.1-live-server-amd64.iso.torrent
  ```

Notes on setting the download directory and other options:

* The default setting for the download directory in rtorrent is ```"./"```.  This would let you specify the directory when you run rtorrent like this:

  ```
  cd /home/e-smith/files/ibays/rtorrent/html/torrents
  sudo -u rtorrent rtorrent https://releases.ubuntu.com/20.04/ubuntu-20.04.1-live-server-amd64.iso.torrent
  ```
  

