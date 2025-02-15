import QtQuick 2.13
import "../../../../../shared"
import "../../../../../imports"
import QtGraphicalEffects 1.0

Item {
    property bool longChatText: true
    property bool veryLongChatText: chatsModel.plainText(message).length >
                                    (appSettings.useCompactMode ? Constants.limitLongChatTextCompactMode : Constants.limitLongChatText)
    property bool readMore: false
    property alias textField: chatText

    id: root
    visible: contentType == Constants.messageType || isEmoji
    z: 51

    implicitHeight: visible ? (showMoreLoader.active ? childrenRect.height - 10 : chatText.height) : 0

    // This function is to avoid the binding loop warning
    function setWidths() {
        if (longChatText) {
            root.width = undefined
            chatText.width = Qt.binding(function () {return root.width})
        } else {
            chatText.width = Qt.binding(function () {return chatText.implicitWidth})
            root.width = Qt.binding(function () {return chatText.width})
        }
    }

    Component.onCompleted: {
        root.setWidths()
    }

    StyledTextEdit {
        id: chatText
        visible: !showMoreLoader.active || root.readMore
        textFormat: Text.RichText
        wrapMode: Text.Wrap
        font.pixelSize: Style.current.primaryTextFontSize
        readOnly: true
        selectByMouse: true
        color: Style.current.textColor
        height: root.veryLongChatText && !root.readMore ? Math.min(implicitHeight, 200) : implicitHeight
        clip: true
        onLinkActivated: function (link) {
            if(link.startsWith("#")) {
                const chatType = chatsModel.communities.activeCommunity.active ? Constants.chatTypeCommunity : Constants.chatTypePublic;
                const foundChatType = chatsModel.joinChat(link.substring(1), chatType);
                if (foundChatType === Constants.chatTypePublic && chatsModel.communities.activeCommunity.active) {
                    chatsModel.communities.activeCommunity.active = false
                    appMain.changeAppSection(Constants.chat)
                }
                return;
            }

            if (link.startsWith('//')) {
                let pk = link.replace("//", "");
                const userProfileImage = appMain.getProfileImage(pk)
                openProfilePopup(chatsModel.userNameOrAlias(pk), pk, userProfileImage || utilsModel.generateIdenticon(pk))
                return;
            }

            const data = Utils.getLinkDataForStatusLinks(link)
            if (data && data.callback) {
                return data.callback()
            }


            appMain.openLink(link)
        }

        onLinkHovered: {
            cursorShape: Qt.PointingHandCursor
        }

        text: {
            if(contentType === Constants.stickerType) return "";
            let msg = Utils.linkifyAndXSS(message);
            if(isEmoji) {
                return Emoji.parse(msg, Emoji.size.middle);
            } else {
                return Utils.getMessageWithStyle(Emoji.parse(msg), appSettings.useCompactMode, isCurrentUser)
            }
        }
    }

    Loader {
        id: mask
        anchors.fill: chatText
        active: showMoreLoader.active
        visible: false
        sourceComponent: LinearGradient {
            start: Qt.point(0, 0)
            end: Qt.point(0, chatText.height)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "white" }
                GradientStop { position: 0.85; color: "white" }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    Loader {
        id: opMask
        active: showMoreLoader.active && !root.readMore
        anchors.fill: chatText
        sourceComponent: OpacityMask {
            source: chatText
            maskSource: mask
        }
    }

    Loader {
        id: showMoreLoader
        active: root.veryLongChatText
        anchors.top: chatText.bottom
        anchors.topMargin: - Style.current.padding
        anchors.horizontalCenter: parent.horizontalCenter
        sourceComponent: Component {
            SVGImage {
                id: emojiImage
                width: 256
                height: 44
                fillMode: Image.PreserveAspectFit
                source: "../../../../img/read-more.svg"
                z: 100
                rotation: root.readMore ? 180 : 0
                MouseArea {
                    z: 101
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.readMore = !root.readMore
                    }
                }
            }
        }
    }
}
