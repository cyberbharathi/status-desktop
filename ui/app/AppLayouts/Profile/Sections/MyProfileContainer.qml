import QtQuick 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import "../../../../imports"
import "../../../../shared"
import "../../../../shared/status"

Item {
    property string ensName: profileModel.profile.preferredUsername || ""
    property string username: profileModel.profile.username
    property string pubkey: profileModel.profile.pubKey

    id: profileHeaderContent
    clip: true
    height: parent.height
    Layout.fillWidth: true

    Component {
        id: changeProfileModalComponent
        ChangeProfilePicModal {}
    }

    Item {
        id: profileImgNameContainer
        anchors.top: parent.top
        anchors.topMargin: 64
        width: profileContainer.profileContentWidth

        anchors.horizontalCenter: parent.horizontalCenter

        height: this.childrenRect.height

        Item {
            id: profileImgContainer
            width: profileImg.width
            height: profileImg.height

            RoundedImage {
                id: profileImg
                width: 64 * scaleAction.factor
                height: 64 * scaleAction.factor
                border.width: 1
                border.color: Style.current.border
                source: profileModel.profile.thumbnailImage || ""
                smooth: false
                antialiasing: true
            }

            RoundedIcon {
                source: "../../../img/pencil.svg"
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -3
                anchors.right: parent.right
                anchors.rightMargin: -3
                width: 24 * scaleAction.factor
                height: 24 * scaleAction.factor
                border.width: 1
                border.color: Style.current.background
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const popup = changeProfileModalComponent.createObject(profileHeaderContent);
                    popup.open()
                }
            }
        }

        StyledText {
            id: profileName
            text: ensName !== "" ? ensName : username
            anchors.left: profileImgContainer.right
            anchors.leftMargin: Style.current.halfPadding
            anchors.top: profileImgContainer.top
            anchors.topMargin: 4
            font.weight: Font.Bold
            font.pixelSize: 20 * scaleAction.factor
        }

        Address {
            id: pubkeyText
            text: ensName !== "" ? username : pubkey
            anchors.bottom: profileImgContainer.bottom
            anchors.left: profileName.left
            anchors.bottomMargin: 4
            width: 200 * scaleAction.factor
            font.pixelSize: 15 * scaleAction.factor
        }

        StatusIconButton {
            id: qrCodeButton
            anchors.right: parent.right
            height: 32 * scaleAction.factor
            width: 32 * scaleAction.factor
            radius: 8
            anchors.verticalCenter: profileImgContainer.verticalCenter
            icon.name: "qr-code-icon"
            iconColor: Style.current.textColor
            onClicked: {
                qrCodePopup.open()
            }
        }

        Separator {
            id: lineSeparator
            anchors.top: profileImgContainer.bottom
            anchors.topMargin: 36

        }
    }

    ModalPopup {
        id: qrCodePopup
        width: 420 * scaleAction.factor
        height: 420 * scaleAction.factor
        Image {
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: profileModel.qrCode(pubkey)
            anchors.verticalCenterOffset: 20
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height: 312 * scaleAction.factor
            width: 312 * scaleAction.factor
            mipmap: true
            smooth: false
        }
    }

    Column {
        anchors.right: profileImgNameContainer.right
        anchors.left: profileImgNameContainer.left
        spacing: Style.current.bigPadding
        anchors.top: profileImgNameContainer.bottom
        anchors.topMargin: Style.current.smallPadding

        TextWithLabel {
            //% "Chat key"
            label: qsTrId("chat-key")
            text: pubkey.substring(0, 13) + "..." + pubkey.substring(pubkey.length - 13)
            textToCopy: pubkey
        }

        TextWithLabel {
            //% "Share Profile URL"
            label: qsTrId("share-profile-url")
            text: `${Constants.userLinkPrefix}${pubkey.substring(0, 5)}...${pubkey.substring(pubkey.length - 5)}`
            textToCopy: Constants.userLinkPrefix + pubkey
        }
    }
}

/*##^##
Designer {
    D{i:0;formeditorColor:"#ffffff"}
}
##^##*/
