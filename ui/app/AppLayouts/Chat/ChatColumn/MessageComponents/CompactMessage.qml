import QtQuick 2.13
import QtGraphicalEffects 1.13
import "../../../../../shared"
import "../../../../../shared/status"
import "../../../../../imports"

Item {
    property var clickMessage: function () {}
    property int chatHorizontalPadding: Style.current.halfPadding
    property int chatVerticalPadding: 7
    property string linkUrls: ""
    property int contentType: 2
    property var container
    property bool isCurrentUser: false
    property bool isHovered: typeof hoveredMessage !== "undefined" && hoveredMessage === messageId
    property bool isMessageActive: typeof activeMessage !== "undefined" && activeMessage === messageId
    property bool headerRepeatCondition: (authorCurrentMsg !== authorPrevMsg || shouldRepeatHeader || dateGroupLbl.visible || chatReply.active)

    id: root

    width: parent.width
    height: messageContainer.height + messageContainer.anchors.topMargin
            + (dateGroupLbl.visible ? dateGroupLbl.height + dateGroupLbl.anchors.topMargin : 0)

    MouseArea {
        enabled: !placeholderMessage
        anchors.fill: messageContainer
        acceptedButtons: Qt.RightButton
        onClicked: messageMouseArea.clicked(mouse)
    }

    ChatButtons {
        contentType: root.contentType
        parentIsHovered: root.isHovered
        onHoverChanged: hovered && setHovered(messageId, hovered)
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.top: messageContainer.top
        // This is not exactly like the design because the hover becomes messed up with the buttons on top of another Message
        anchors.topMargin: -Style.current.halfPadding
    }

    Loader {
        active: typeof messageContextMenu !== "undefined"
        sourceComponent: Component {
            Connections {
                enabled: root.isMessageActive
                target: messageContextMenu
                onClosed: setMessageActive(messageId, false)
            }
        }
    }

    DateGroup {
        id: dateGroupLbl
    }

    Rectangle {
        property alias chatText: chatText

        id: messageContainer
        anchors.top: dateGroupLbl.visible ? dateGroupLbl.bottom : parent.top
        anchors.topMargin: dateGroupLbl.visible ? Style.current.padding : 0
        height: childrenRect.height
                + (chatName.visible || emojiReactionLoader.active ? Style.current.halfPadding : 0)
                + (chatName.visible && emojiReactionLoader.active ? Style.current.padding : 0)
                + (!chatName.visible && chatImageContent.active ? 6 : 0)
                + (emojiReactionLoader.active ? emojiReactionLoader.height: 0)
                + (retry.visible && !chatTime.visible ? Style.current.smallPadding : 0)
        width: parent.width

        color: root.isHovered || isMessageActive ? (hasMention ? Style.current.mentionMessageHoverColor : Style.current.backgroundHoverLight) :
                                                   (hasMention ? Style.current.mentionMessageColor : Style.current.transparent)

        ChatReply {
            id: chatReply
            anchors.left: chatImage.left
            longReply: active && textFieldImplicitWidth > width
            container: root.container
            chatHorizontalPadding: root.chatHorizontalPadding
            anchors.right: parent.right
            anchors.rightMargin: Style.current.padding
        }

        UserImage {
            id: chatImage
            active: isMessage && headerRepeatCondition
            anchors.left: parent.left
            anchors.leftMargin: Style.current.padding
            anchors.top: chatReply.active ? chatReply.bottom : parent.top
            anchors.topMargin: Style.current.smallPadding
        }

        UsernameLabel {
            id: chatName
            visible: isMessage && headerRepeatCondition
            anchors.leftMargin: root.chatHorizontalPadding
            anchors.top: chatImage.top
            anchors.left: chatImage.right
        }

        ChatTime {
            id: chatTime
            visible: headerRepeatCondition
            anchors.verticalCenter: chatName.verticalCenter
            anchors.left: chatName.right
            anchors.leftMargin: 4
            color: Style.current.secondaryText
        }

        Item {
            id: messageContent
            height: childrenRect.height + (isEmoji ? 2 : 0)
            anchors.top: chatName.visible ? chatName.bottom :
                                            chatReply.active ? chatReply.bottom : parent.top
            anchors.left: chatImage.right
            anchors.leftMargin: root.chatHorizontalPadding
            anchors.right: parent.right
            anchors.rightMargin: root.chatHorizontalPadding

            ChatText {
                readonly property int leftPadding: chatImage.anchors.leftMargin + chatImage.width + root.chatHorizontalPadding
                id: chatText
                anchors.top: parent.top
                anchors.topMargin: isEmoji ? 2 : 0
                anchors.left: parent.left
                anchors.right: parent.right
                // using a padding instead of a margin let's us select text more easily
                anchors.leftMargin: -leftPadding
                textField.leftPadding: leftPadding
                textField.rightPadding: Style.current.bigPadding
            }

            Loader {
                id: chatImageContent
                active: isImage
                anchors.top: parent.top
                anchors.topMargin: active ? 6 : 0
                z: 51

                sourceComponent: Component {
                    ChatImage {
                        imageSource: image
                        imageWidth: 200
                        onClicked: root.clickMessage(false, false, true, image)
                        container: root.container
                    }
                }
            }

            Loader {
                id: stickerLoader
                active: contentType === Constants.stickerType
                anchors.top: parent.top
                anchors.topMargin: active ? Style.current.halfPadding : 0
                sourceComponent: Component {
                    Rectangle {
                        id: stickerContainer
                        color: Style.current.transparent
                        border.color: root.isHovered ? Qt.darker(Style.current.border, 1.1) : Style.current.border
                        border.width: 1
                        radius: 16
                        width: stickerId.width + 2 * root.chatVerticalPadding
                        height: stickerId.height + 2 * root.chatVerticalPadding

                        Sticker {
                            id: stickerId
                            anchors.top: parent.top
                            anchors.topMargin: root.chatVerticalPadding
                            anchors.left: parent.left
                            anchors.leftMargin: root.chatVerticalPadding
                            contentType: root.contentType
                            container: root.container
                        }
                    }
                }
            }

            MessageMouseArea {
                id: messageMouseArea
                anchors.fill: stickerLoader.active ? stickerLoader : chatText
            }

            Loader {
                id: linksLoader
                active: !!root.linkUrls
                anchors.top: chatText.bottom
                anchors.topMargin: active ? Style.current.halfPadding : 0

                sourceComponent: Component {
                    LinksMessage {
                        linkUrls: root.linkUrls
                        container: root.container
                        isCurrentUser: root.isCurrentUser
                    }
                }
            }

            Loader {
                id: audioPlayerLoader
                active: isAudio
                anchors.top: parent.top
                anchors.topMargin: active ? Style.current.halfPadding : 0

                sourceComponent: Component {
                    AudioPlayer {
                        audioSource: audio
                    }
                }
            }

            Loader {
                id: transactionBubbleLoader
                active: contentType === Constants.transactionType
                anchors.top: parent.top
                anchors.topMargin: active ? (chatName.visible ? 4 : 6) : 0
                sourceComponent: Component {
                    TransactionBubble {}
                }
            }

            Loader {
                active: contentType === Constants.communityInviteType
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: active ? 8 : 0
                sourceComponent: Component {
                    id: invitationBubble
                    InvitationBubble {
                        communityId: container.communityId
                    }
                }
            }
        }


        Retry {
            id: retry
            anchors.left: chatTime.visible ? chatTime.right : messageContent.left
            anchors.leftMargin: chatTime.visible ? chatHorizontalPadding : 0
            anchors.top: chatTime.visible ? undefined : messageContent.bottom
            anchors.topMargin: chatTime.visible ? 0 : -4
            anchors.verticalCenter: chatTime.visible ? chatTime.verticalCenter : undefined
        }
    }

    Loader {
        active: hasMention
        height: messageContainer.height
        anchors.left: messageContainer.left

        sourceComponent: Component {
            Rectangle {
                id: mentionBorder
                color: Style.current.mentionColor
                width: 2
                height: parent.height
            }
        }
    }

    HoverHandler {
        enabled: typeof messageContextMenu !== "undefined" && typeof profilePopupOpened !== "undefined" && !messageContextMenu.opened && !profilePopupOpened && !popupOpened
        onHoveredChanged: setHovered(messageId, hovered)
    }

    Loader {
        id: emojiReactionLoader
        active: emojiReactionsModel.length
        anchors.bottom: messageContainer.bottom
        anchors.bottomMargin: Style.current.halfPadding
        anchors.left: messageContainer.left
        anchors.leftMargin: messageContainer.chatText.textField.leftPadding

        sourceComponent: Component {
            EmojiReactions {
                onHoverChanged: setHovered(messageId, hovered)
            }
        }
    }
}
