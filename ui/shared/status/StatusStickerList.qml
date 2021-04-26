import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import "../../imports"
import "../../shared"

GridView {
    id: root
    visible: count > 0
    anchors.fill: parent
    cellWidth: 88 * scaleAction.factor
    cellHeight: 88 * scaleAction.factor
    model: stickerList
    focus: true
    clip: true
    signal stickerClicked(string hash, int packId)
    delegate: Item {
        width: stickerGrid.cellWidth
        height: stickerGrid.cellHeight
        Column {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.leftMargin: 4
            ImageLoader {
                width: 80 * scaleAction.factor
                height: 80 * scaleAction.factor
                source: "https://ipfs.infura.io/ipfs/" + url
                onClicked: {
                    root.stickerClicked(hash, packId)
                }
            }
        }
    }
}
