import QtQuick
import QtQuick.Controls

// Vertical scroll area with the shell's scrollbar. ScrollView would scroll on Up and Down, here they move
// between the controls inside like everywhere else, and the focus ring scrolls each one into view
ScrollView {
    clip: true
    contentWidth: availableWidth

    ScrollBar.vertical: StyledScrollBar {}

    Keys.onPressed: (event) => {
        if (event.key != Qt.Key_Up && event.key != Qt.Key_Down) return
        Window.activeFocusItem?.nextItemInFocusChain(event.key == Qt.Key_Down)?.forceActiveFocus()
        event.accepted = true
    }
}
