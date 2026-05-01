pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property color background: "#1e1e2e"
    property color foreground: "#cdd6f4"
    property color primary:    "#89b4fa"
    property color secondary:  "#f38ba8"
    property color text:       "#ffffff"

    property FileView pywalWatcher: FileView {

        path: "/home/tomi/.cache/wal/colors.json"
        watchChanges: true
        
        onFileChanged: {
            this.reload();
        }
        
        onLoaded: {
            try {
                var pywal = JSON.parse(this.text());
                
                root.background = pywal.special.background;
                root.foreground = pywal.special.foreground;
                
                root.primary    = pywal.colors.color4; 
                root.secondary  = pywal.colors.color6;
                root.text       = pywal.special.foreground;

                Settings.wallpaper = "file://" + pywal.wallpaper;

            } catch (e) {
                console.log("Could not load or parse Pywal colors: " + e);
            }
        }
    }
}