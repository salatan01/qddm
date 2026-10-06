import QtQuick
import QtQuick.Window
import Qt.labs.folderlistmodel

// preview.qml — qddm live harness. Check the theme WITHOUT logging out:
//   ./preview.sh
//
// Mocks the SDDM greeter context (sddm / userModel / sessionModel / config /
// keyboard) via dynamic scope so themes/qddm/Main.qml loads unmodified.
// Needs the SddmComponents stub (preview-imports/, wired by preview.sh).
//
// TEST KNOBS — edit defaults below, or switch live with function keys:
//   F1  cycle mode      random -> sequence -> fixed
//   F2  cycle playback  0 (forever) -> 1 (once) -> 2 (twice) -> 0
//   F3  toggle title pill
//   F4  toggle repeat
//   Esc quit
// Password "qddm" succeeds (console only), anything else fails like SDDM.
Window {
    id: win
    width: 1920; height: 1080
    visibility: Window.FullScreen
    color: "black"
    title: "qddm preview"

    // ── Test knobs ────────────────────────────────────────────────
    QtObject {
        id: mockConfig
        property string videoMode: "random"
        property string playback: "0"
        property string repeat: "true"
        property string fixedFile: ""
        property string showTitle: "true"
        // Your library. Absolute host path also exercises the
        // videoAbsolutePath (git-annex) code path used on NixOS.
        property string videoPath: "/home/superkat01/qSets/qDDM"
    }

    // ── Mock SDDM context (names Main.qml expects) ────────────────
    property var config: mockConfig
    property var keyboard: mockKeyboard
    property var sddm: mockSddm
    property var userModel: mockUserModel
    property var sessionModel: mockSessionModel

    QtObject {
        id: mockKeyboard
        property bool numLock: false
    }

    QtObject {
        id: mockSddm
        property string hostName: "preview"
        signal loginSucceeded()
        signal loginFailed()
        function login(user, pass, session) {
            console.log("preview: login user=" + user + " session=" + session)
            if (pass === "qddm") {
                console.log("preview: auth SUCCEEDED (hint password was right)")
                loginSucceeded()
            } else {
                loginFailed()
            }
        }
        function reboot() { console.log("preview: reboot ignored") }
        function powerOff() { console.log("preview: powerOff ignored") }
    }

    ListModel {
        id: mockUserModel
        property int lastIndex: 0
        property string lastUser: "superkat01"
        function rowCount() { return count }
        ListElement { name: "superkat01"; realName: "Super Kat" }
        ListElement { name: "guest"; realName: "Guest" }
    }

    ListModel {
        id: mockSessionModel
        property int lastIndex: 0
        function rowCount() { return count }
        ListElement { name: "niri" }
        ListElement { name: "hyprland" }
    }

    Loader {
        id: themeLoader
        anchors.fill: parent
        source: "themes/qddm/Main.qml"
        onLoaded: console.log("preview: theme loaded")
        onStatusChanged: {
            if (status === Loader.Error) console.warn("preview: theme FAILED to load")
        }
    }

    // Independent probe of the video dir: tells "no videos found" apart
    // from "theme broken" without touching Main.qml internals.
    FolderListModel {
        id: dirProbe
        folder: mockConfig.videoPath !== "" ? ("file://" + mockConfig.videoPath) : Qt.resolvedUrl("themes/qddm/videos")
        nameFilters: ["*.mp4", "*.mkv", "*.webm"]
        showDirs: false
        onStatusChanged: {
            if (status === FolderListModel.Ready)
                console.log("preview: dirProbe found " + count + " video(s)")
        }
    }

    // ── Preview HUD (outside the theme) ───────────────────────────
    // Line 1: knobs. Line 2: diagnostics — theme status + video count.
    // If the screen is otherwise blank, line 2 names the culprit.
    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 14
        spacing: 8
        z: 9999
        Rectangle {
            width: hudRow.implicitWidth + 24
            height: 30
            radius: 15
            color: "#66000000"
            border.color: "#44c9a063"
            Row {
                id: hudRow
                anchors.centerIn: parent
                spacing: 8
                Text { text: "PREVIEW"; color: "#c9a063"; font.pixelSize: 11; font.bold: true }
                Text {
                    text: mockConfig.videoMode + " · x" + mockConfig.playback
                        + (mockConfig.repeat === "true" ? " · repeat" : " · once")
                        + (mockConfig.showTitle === "true" ? " · title" : "")
                        + " · pw=qddm · F1/F2/F3/F4 · Esc quits"
                    color: "#aaffffff"; font.pixelSize: 11
                }
            }
        }
        Rectangle {
            width: diagRow.implicitWidth + 24
            height: 30
            radius: 15
            color: "#66000000"
            border.color: win.diagOk ? "#4455ff88" : "#44ff5555"
            Row {
                id: diagRow
                anchors.centerIn: parent
                spacing: 8
                Text { text: "DIAG"; color: "#c9a063"; font.pixelSize: 11; font.bold: true }
                Text {
                    text: themeLoader.status === Loader.Error ? "THEME FAILED (see console)"
                        : themeLoader.status !== Loader.Ready ? "theme loading…"
                        : dirProbe.status !== FolderListModel.Ready ? "scanning videos…"
                        : dirProbe.count + " video(s): " + mockConfig.videoPath
                    color: win.diagOk ? "#aaffffff" : "#ffaaaa"; font.pixelSize: 11
                }
            }
        }
    }

    readonly property bool diagOk: themeLoader.status === Loader.Ready
        && dirProbe.status === FolderListModel.Ready && dirProbe.count > 0

    // Full-screen fallback: if the theme itself fails to compile/load,
    // say so on screen instead of leaving a mysterious black window.
    Rectangle {
        anchors.fill: parent
        z: 9998
        visible: themeLoader.status === Loader.Error
        color: "#180000"
        Column {
            anchors.centerIn: parent
            spacing: 10
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "THEME FAILED TO LOAD"
                color: "#ff6666"; font.pixelSize: 22; font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "open a terminal and read the console output"
                color: "#ccffffff"; font.pixelSize: 13
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "usual cause: QtMultimedia / Qt5Compat QML modules missing"
                color: "#88ffffff"; font.pixelSize: 12
            }
        }
    }

    // Function keys are ignored by TextInput, and Shortcuts fire
    // regardless of which item has focus — unlike Keys, which cannot
    // attach to a Window at all.
    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }
    Shortcut {
        sequence: "F1"
        onActivated: {
            mockConfig.videoMode = mockConfig.videoMode === "random" ? "sequence"
                : mockConfig.videoMode === "sequence" ? "fixed" : "random"
            console.log("preview: mode -> " + mockConfig.videoMode)
        }
    }
    Shortcut {
        sequence: "F2"
        onActivated: {
            mockConfig.playback = mockConfig.playback === "0" ? "1"
                : mockConfig.playback === "1" ? "2" : "0"
            console.log("preview: playback -> " + mockConfig.playback)
        }
    }
    Shortcut {
        sequence: "F3"
        onActivated: {
            mockConfig.showTitle = mockConfig.showTitle === "true" ? "false" : "true"
        }
    }
    Shortcut {
        sequence: "F4"
        onActivated: {
            mockConfig.repeat = mockConfig.repeat === "true" ? "false" : "true"
            console.log("preview: repeat -> " + mockConfig.repeat)
        }
    }

    Component.onCompleted: console.log("preview: knobs mode=" + mockConfig.videoMode
        + " playback=" + mockConfig.playback + " repeat=" + mockConfig.repeat
        + " videos=" + mockConfig.videoPath)
}
