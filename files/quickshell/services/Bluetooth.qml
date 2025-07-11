pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool powered
    property bool discovering
    readonly property list<Device> devices: []

    Process {
        running: true
        command: ["bluetoothctl"]
        stdout: SplitParser {
            onRead: {
                getInfo.running = true;
                getDevices.running = true;
            }
        }
    }

    Process {
        id: getInfo

        running: true
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.powered = text.includes("Powered: yes");
                root.discovering = text.includes("Discovering: yes");
            }
        }
    }

    Process {
        id: getDevices

        running: true
        command: ["sh", "-c", `
bluetoothctl devices | grep "^Device" | while read -r line; do
    addr=$(echo "$line" | awk '{print $2}')
    bluetoothctl info "$addr"
    echo
done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const devices = text.trim().split("\n\n").map(d => ({
                            name: d.match(/Name: (.*)/)[1],
                            alias: d.match(/Alias: (.*)/)[1],
                            address: d.match(/Device ([0-9A-Z:]{17})/)[1],
                            icon: d.match(/Icon: (.*)/)[1],
                            connected: d.includes("Connected: yes"),
                            paired: d.includes("Paired: yes"),
                            trusted: d.includes("Trusted: yes")
                        }));
                const rDevices = root.devices;

                const destroyed = rDevices.filter(rd => !devices.find(d => d.address === rd.address));
                for (const device of destroyed)
                    rDevices.splice(rDevices.indexOf(device), 1).forEach(d => d.destroy());

                for (const device of devices) {
                    const match = rDevices.find(d => d.address === device.address);
                    if (match) {
                        match.lastIpcObject = device;
                    } else {
                        rDevices.push(deviceComp.createObject(root, {
                            lastIpcObject: device
                        }));
                    }
                }
            }
        }
    }

    component Device: QtObject {
        required property var lastIpcObject
        readonly property string name: lastIpcObject.name
        readonly property string alias: lastIpcObject.alias
        readonly property string address: lastIpcObject.address
        readonly property string icon: lastIpcObject.icon
        readonly property bool connected: lastIpcObject.connected
        readonly property bool paired: lastIpcObject.paired
        readonly property bool trusted: lastIpcObject.trusted
    }

    Component {
        id: deviceComp

        Device {}
    }
}
