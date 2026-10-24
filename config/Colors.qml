pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property color background: "#1e1e2e"
    property color backgroundSubtle: "#ffffff"
    
    property color foreground: "#cdd6f4"
    property color foregroundHover: "#cdd6f4"
    property color foregroundActive: "#cdd6f4"

    property color primary: "#ffffff"
    property color primaryHover: "#ffffff"
    property color primaryActive: "#ffffff"
    
    property color secondary:  "#f38ba8"
    property color secondaryHover:  "#f38ba8"
    property color secondaryActive:  "#f38ba8"

    property color text:       "#ffffff"
    property color textHover:       "#ffffff"
    property color textActive:       "#ffffff"

    property double hover: 1.5
    property double active: 2

    property FileView pywalWatcher: FileView {

        path: "/home/tomi/.cache/wal/colors.json"
        watchChanges: true
        
        onFileChanged: {
            this.reload();
        }
        
        onLoaded: {
            try {
                var pywal = JSON.parse(this.text());
                
                root.background = "#0a0a0a" /*pywal.special.background*/;
                root.foreground = "#f4f1f2";
                // lighter() can't brighten pure black, so tint with the foreground instead
                root.backgroundSubtle = Qt.tint(root.background, Qt.alpha(root.foreground, 0.07))
                root.foregroundHover = Qt.darker(root.foreground, root.hover);
                root.foregroundActive = Qt.darker(root.foreground, root.active);
                
                root.primary = "#D71921"; 
                root.primaryHover = Qt.darker(root.primary, root.hover); 
                root.primaryActive = Qt.darker(root.primary, root.active); 

                root.secondary = pywal.colors.color6;
                root.secondaryHover = Qt.darker(root.secondary, root.hover);
                root.secondaryActive = Qt.darker(root.secondary, root.active);

                root.text = "#f4f1f2";
                root.textHover = Qt.darker(root.text, root.hover);
                root.textActive = Qt.darker(root.text, root.active);

                Settings.wallpaper = "file://" + pywal.wallpaper;

            } catch (e) {
                console.log("Could not load or parse Pywal colors: " + e);
            }
        }
    }
}