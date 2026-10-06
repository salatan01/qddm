import QtQuick
import QtQuick.Window

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

    // ── Preview HUD (outside the theme) ───────────────────────────
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 14
        width: hudRow.implicitWidth + 24
        height: 30
        radius: 15
        color: "#66000000"
        border.color: "#44c9a063"
        z: 9999
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

    // Function keys are ignored by TextInput, so they reach us even while
    // typing a password. Letters would not — hence F-keys, not letters.
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            Qt.quit()
            event.accepted = true
        } else if (event.key === Qt.Key_F1) {
            mockConfig.videoMode = mockConfig.videoMode === "random" ? "sequence"
                : mockConfig.videoMode === "sequence" ? "fixed" : "random"
            console.log("preview: mode -> " + mockConfig.videoMode)
            event.accepted = true
        } else if (event.key === Qt.Key_F2) {
            mockConfig.playback = mockConfig.playback === "0" ? "1"
                : mockConfig.playback === "1" ? "2" : "0"
            console.log("preview: playback -> " + mockConfig.playback)
            event.accepted = true
        } else if (event.key === Qt.Key_F3) {
            mockConfig.showTitle = mockConfig.showTitle === "true" ? "false" : "true"
            event.accepted = true
        } else if (event.key === Qt.Key_F4) {
            mockConfig.repeat = mockConfig.repeat === "true" ? "false" : "true"
            console.log("preview: repeat -> " + mockConfig.repeat)
            event.accepted = true
        }
    }

    Component.onCompleted: console.log("preview: knobs mode=" + mockConfig.videoMode
        + " playback=" + mockConfig.playback + " repeat=" + mockConfig.repeat
        + " videos=" + mockConfig.videoPath)
}
