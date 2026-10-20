pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import qs.services.network

Singleton {
    id: root

    property bool wifi: true
    property bool ethernet: false

    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property Connection wifiConnectTarget
    readonly property list<Connection> wifiNetworks: []
    readonly property Connection active: wifiNetworks.find(n => n.active) ?? null
    property string wifiStatus: "disconnected"

    property string networkName: ""
    property int networkStrength

    property string icon: root.ethernet
        ? "lan"
        : (root.wifiEnabled && root.wifiStatus === "connected") 
            ? (
                Network.networkStrength > 80 ? "wifi-4" :
                Network.networkStrength > 60 ? "wifi-3" :
                Network.networkStrength > 40 ? "wifi-2" :
                Network.networkStrength > 20 ? "wifi-1" :
                "wifi-0"
            )
            : (root.wifiStatus === "connecting")
                ? "wifi-connecting"
                : (root.wifiStatus === "disconnected")
                    ? "wifi-find"
                    : (root.wifiStatus === "disabled")
                        ? "no-wifi"
                        : "wifi-bad"

    function enableWifi(enabled = true): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi(): void {
        enableWifi(!wifiEnabled)
    }

    function rescanWifi(): void {
        if (wifiScanning || !wifiEnabled) return
        wifiScanning = true;
        rescanProcess.running = true;
    }

    function connectToWifiNetwork(conn: Connection): void {
        conn.askingPassword = false;
        root.wifiConnectTarget = conn;
        // We use this instead of `nmcli connection up SSID` because this also creates a connection profile
        connectProc.exec(["nmcli", "device", "wifi", "connect", conn.bssid, "name", conn.ssid])
    }

    function disconnectWifiNetwork(): void {
        if (active) disconnectProc.exec(["nmcli", "connection", "down", active.ssid]);
    }

    function changePassword(network: Connection, password: string): void {
        network.askingPassword = false;
        root.wifiConnectTarget = network;
        connectProc.exec({
            "environment": {
                "PASSWORD": password,
                "BSSID": network.bssid,
                "SSID": network.ssid
            },
            "command": [
                "bash", "-c", 
                'nmcli connection delete "$SSID" >/dev/null 2>&1; nmcli device wifi connect "$BSSID" password "$PASSWORD" name "$SSID"'
            ]
        })
    }

    Process {
        id: enableWifiProc
    }

    Process {
        id: connectProc
/*         environment: ({
            LANG: "C",
            LC_ALL: "C"
        }) */
        stdout: SplitParser {
            onRead: line => {
                getNetworks.running = true
            }
        }
        stderr: SplitParser {
            onRead: line => {
                // print("err:", line)
                if (line.includes("Secrets were required")) {
                    root.wifiConnectTarget.askingPassword = true
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            // Open networks can't need a password, so only secured ones ask for it on failure
            if (root.wifiConnectTarget)
                root.wifiConnectTarget.askingPassword = (exitCode !== 0 && root.wifiConnectTarget.isSecure)
            root.wifiConnectTarget = null
            getNetworks.running = true
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        // Reset on exit, so a failed or empty scan can't leave it stuck
        onExited: {
            wifiScanning = false;
            getNetworks.running = true;
        }
    }

    // Status update
    function update() {
        updateConnectionType.startCheck();
        wifiStatusProcess.running = true
        updateNetworkName.running = true;
        updateNetworkStrength.running = true;
    }

    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    Process {
        id: updateConnectionType
        property string buffer
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE d status && nmcli -t -f CONNECTIVITY g"]
        running: true

        function startCheck() {
            buffer = "";
            updateConnectionType.running = true;
        }

        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }

        onExited: (exitCode, exitStatus) => {

            const lines = updateConnectionType.buffer.trim().split('\n');
            const connectivity = lines.pop() // none, limited, full

            let hasEthernet = false;
            let hasWifi = false;
            let wifiStatus = "disconnected";

            lines.forEach(line => {

                if (line.includes("ethernet") && line.includes("connected"))
                    hasEthernet = true;
                else if (line.includes("wifi:")) {

                    if (line.includes("disconnected")) {
                        wifiStatus = "disconnected"
                    }
                    else if (line.includes("connected")) {
                        
                        hasWifi = true;
                        wifiStatus = "connected"

                        if (connectivity === "limited") {
                            hasWifi = false;
                            wifiStatus = "limited"
                        }
                    }
                    else if (line.includes("connecting")) {
                        wifiStatus = "connecting"
                    }
                    else if (line.includes("unavailable")) {
                        wifiStatus = "disabled"
                    }
                }
            });

            root.wifiStatus = wifiStatus;
            root.ethernet = hasEthernet;
            root.wifi = hasWifi;
        }
    }

    Process {
        id: updateNetworkName
        command: ["sh", "-c", "nmcli -t -f NAME c show --active | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.networkName = data;
            }
        }
    }

    Process {
        id: updateNetworkStrength
        running: true
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\\*/{if (NR!=1) {print $2}}'"]
        stdout: SplitParser {
            onRead: data => {
                root.networkStrength = parseInt(data);
            }
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        Component.onCompleted: running = true
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: getNetworks
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
/*         environment: ({
            LANG: "C",
            LC_ALL: "C"
        }) */
        stdout: StdioCollector {
            onStreamFinished: {
                
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3],
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] || ""
                    };

                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();

                for (const network of allNetworks) {

                    const existing = networkMap.get(network.ssid);
                    
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
                    }
                }

                const wifiNetworks = Array.from(networkMap.values());

                const rNetworks = root.wifiNetworks;

                const destroyed = rNetworks.filter(rn => !wifiNetworks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of wifiNetworks) {
                    
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(connObj.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    Component {
        id: connObj

        Connection {}
    }
}