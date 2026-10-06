import QtQuick

// Preview-only stub of SDDM's SddmComponents.TextConstants.
// The real module ships with sddm-greeter; qddm only instantiates it.
QtObject {
    property string welcomeText: "Welcome"
    property string username: "Username"
    property string password: "Password"
    property string login: "Login"
    property string loginFailedText: "Login Failed"
    property string rebootButton: "Reboot"
    property string shutdownButton: "Shut Down"
}
