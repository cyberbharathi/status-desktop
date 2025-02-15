import QtQuick 2.13
import Qt.labs.platform 1.1
import QtQuick.Controls 2.13
import QtQuick.Window 2.13
import QtQuick.Layouts 1.13
import QtQml.Models 2.13
import QtGraphicalEffects 1.13
import QtQuick.Dialogs 1.3
import "../../../../shared"
import "../../../../imports"
import "../components"
import "./samples/"
import "./MessageComponents"

ScrollView {
    id: root

    property alias chatLogView: chatLogView
    
    property var messageList: MessagesData {}
    property bool loadingMessages: false
    property real scrollY: chatLogView.visibleArea.yPosition * chatLogView.contentHeight
    property int newMessages: 0

    property string hoveredMessage
    property string activeMessage

    function setHovered(messageId, hovered) {
        if (hovered) {
            hoveredMessage = messageId
        } else if (hoveredMessage === messageId) {
            hoveredMessage = ""
        }
    }

    function setMessageActive(messageId, active) {
        if (active) {
            activeMessage = messageId
        } else if (activeMessage === messageId) {
            activeMessage = ""
        }
    }

    contentItem: chatLogView
    Layout.fillWidth: true
    Layout.fillHeight: true

    height: parent.height
    ScrollBar.vertical.policy: chatLogView.contentHeight > chatLogView.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ListView {
        property string currentNotificationChatId

        id: chatLogView
        anchors.fill: parent
        anchors.bottomMargin: Style.current.bigPadding
        spacing: appSettings.useCompactMode ? 0 : 4
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: {
            if (utilsModel.getOs() === Constants.windows) {
                return 5000
            }
            return 10000
        }
        verticalLayoutDirection: ListView.BottomToTop

        // This header and Connections is to create an invisible padding so that the chat identifier is at the top
        // The Connections is necessary, because doing the check inside teh ehader created a binding loop (the contentHeight includes the header height
        // If the content height is smaller than the full height, we "show" the padding so that the chat identifier is at the top, otherwise we disable the Connections
        header: Item {
            height: 0
            width: chatLogView.width
        }
        Connections {
            id: contentHeightConnection
            enabled: true
            target: chatLogView
            onContentHeightChanged: {
                if (chatLogView.contentItem.height - chatLogView.headerItem.height < chatLogView.height) {
                    chatLogView.headerItem.height = chatLogView.height - (chatLogView.contentItem.height - chatLogView.headerItem.height) - 36
                } else {
                    chatLogView.headerItem.height = 0
                    contentHeightConnection.enabled = false
                }
            }
        }


        Timer {
            id: timer
        }

        Button {
            readonly property int buttonPadding: 5

            id: scrollDownButton
            visible: false
            height: 32
            width: nbMessages.width + arrowImage.width + 2 * Style.current.halfPadding + (nbMessages.visible ? scrollDownButton.buttonPadding : 0)
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: Style.current.padding
            background: Rectangle {
                color: Style.current.buttonSecondaryColor
                border.width: 0
                radius: 16
            }
            onClicked: {
                root.newMessages = 0
                scrollDownButton.visible = false
                chatLogView.scrollToBottom(true)
            }

            StyledText {
                id: nbMessages
                visible: root.newMessages > 0
                width: visible ? implicitWidth : 0
                text: root.newMessages
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                color: Style.current.pillButtonTextColor
                font.pixelSize: 15
                anchors.leftMargin: Style.current.halfPadding
            }

            SVGImage {
                id: arrowImage
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: nbMessages.right
                source: "../../../img/leave_chat.svg"
                anchors.leftMargin: nbMessages.visible ? scrollDownButton.buttonPadding : 0
                rotation: -90

                ColorOverlay {
                    anchors.fill: parent
                    source: parent
                    color: Style.current.pillButtonTextColor
                }
            }

            MouseArea {
               cursorShape: Qt.PointingHandCursor
               anchors.fill: parent
               onPressed: mouse.accepted = false
            }
        }

        function scrollToBottom(force, caller) {
            if (!force && !chatLogView.atYEnd) {
                // User has scrolled up, we don't want to scroll back
                return false
            }
            if (caller && caller !== chatLogView.itemAtIndex(chatLogView.count - 1)) {
                // If we have a caller, only accept its request if it's the last message
                return false
            }
            // Call this twice and with a timer since the first scroll to bottom might have happened before some stuff loads
            // meaning that the scroll will not actually be at the bottom on switch
            // Add a small delay because images, even though they say they say they are loaed, they aren't shown yet
            Qt.callLater(chatLogView.positionViewAtBeginning)
            timer.setTimeout(function() {
                 Qt.callLater(chatLogView.positionViewAtBeginning)
            }, 100);
            return true
        }

        function clickOnNotification(chatId) {
            applicationWindow.show()
            applicationWindow.raise()
            applicationWindow.requestActivate()
            chatsModel.setActiveChannel(chatId)
            appMain.changeAppSection(Constants.chat)
        }

        Connections {
            target: chatsModel
            onMessagesLoaded: {
                loadingMessages = false;
            }

            onSendingMessage: {
                chatLogView.scrollToBottom(true)
            }

            onSendingMessageFailed: {
                sendingMsgFailedPopup.open();
            }

            onNewMessagePushed: {
                if (!chatLogView.scrollToBottom()) {
                    root.newMessages++
                }
            }

            onAppReady: {
                chatLogView.scrollToBottom(true)
            }

            onMessageNotificationPushed: function(chatId, msg, messageType, chatType, timestamp, identicon, username, hasMention, isAddedContact, channelName) {
                if (appSettings.notificationSetting == Constants.notifyAllMessages || 
                    (appSettings.notificationSetting == Constants.notifyJustMentions && hasMention)) {
                    if (chatType === Constants.chatTypeOneToOne && !appSettings.allowNotificationsFromNonContacts && !isAddedContact) {
                        return
                    }
                    if (chatId === chatsModel.activeChannel.id && applicationWindow.active === true) {
                        // Do not show the notif if we are in the channel already and the window is active and focused
                        return
                    }

                    chatLogView.currentNotificationChatId = chatId

                    let name;
                    if (appSettings.notificationMessagePreviewSetting === Constants.notificationPreviewAnonymous) {
                        name = "Status"
                    } else if (chatType === Constants.chatTypePublic) {
                        name = chatId
                    } else {
                        name = chatType === Constants.chatTypePrivateGroupChat ? Utils.filterXSS(channelName) : Utils.removeStatusEns(username)
                    }

                    let message;
                    if (appSettings.notificationMessagePreviewSetting > Constants.notificationPreviewNameOnly) {
                        switch(messageType){
                        //% "Image"
                        case Constants.imageType: message = qsTrId("image"); break
                        //% "Sticker"
                        case Constants.stickerType: message = qsTrId("sticker"); break
                        default: message = msg // don't parse emojis here as it emits HTML
                        }
                    } else {
                        //% "You have a new message"
                        message = qsTrId("you-have-a-new-message")
                    }

                    currentlyHasANotification = true
                    if (appSettings.useOSNotifications && systemTray.supportsMessages) {
                        systemTray.showMessage(name,
                                               message,
                                               SystemTrayIcon.NoIcon,
                                               Constants.notificationPopupTTL)
                    } else {
                        notificationWindow.notifyUser(chatId, name, message, chatType, identicon, chatLogView.clickOnNotification)
                    }
                }
            }
        }

        Connections {
            target: chatsModel.communities

             onMembershipRequestChanged: function (communityName, accepted) {
                systemTray.showMessage("Status",
                                       accepted ? qsTr("You have been accepted into the ‘%1’ community").arg(communityName) :
                                                  qsTr("Your request to join the ‘%1’ community was declined").arg(communityName),
                                       SystemTrayIcon.NoIcon,
                                       Constants.notificationPopupTTL)
            }

            onMembershipRequestPushed: function (communityName, pubKey) {
                systemTray.showMessage(qsTr("New membership request"),
                                       qsTr("%1 asks to join ‘%2’").arg(Utils.getDisplayName(pubKey)).arg(communityName),
                                       SystemTrayIcon.NoIcon,
                                       Constants.notificationPopupTTL)
            }
        }

        Connections {
            target: systemTray
            onMessageClicked: {
                chatLogView.clickOnNotification(chatLogView.currentNotificationChatId)
            }
        }

        property var loadMsgs : Backpressure.oneInTime(chatLogView, 500, function() {
            if(loadingMessages) return;
            loadingMessages = true;
            chatsModel.loadMoreMessages();
        });

        onContentYChanged: {
            scrollDownButton.visible = (contentHeight - (scrollY + height) > 400)
            if(scrollY < 500){
                loadMsgs();
            }
        }


        model: messageListDelegate
        section.property: "sectionIdentifier"
        section.criteria: ViewSection.FullString
    }

    MessageDialog {
        id: sendingMsgFailedPopup
        standardButtons: StandardButton.Ok
        //% "Failed to send message."
        text: qsTrId("failed-to-send-message-")
        icon: StandardIcon.Critical
    }

    DelegateModelGeneralized {
        id: messageListDelegate
        lessThan: [
            function(left, right) { return left.clock > right.clock }
        ]

        model: messageList

        delegate: Message {
            id: msgDelegate
            fromAuthor: model.fromAuthor
            chatId: model.chatId
            userName: model.userName
            alias: model.alias
            localName: model.localName
            message: model.message
            plainText: model.plainText
            identicon: model.identicon
            isCurrentUser: model.isCurrentUser
            timestamp: model.timestamp
            sticker: model.sticker
            contentType: model.contentType
            outgoingStatus: model.outgoingStatus
            responseTo: model.responseTo
            authorCurrentMsg: msgDelegate.ListView.section
            // The previous message is actually the nextSection since we reversed the list order
            authorPrevMsg: msgDelegate.ListView.nextSection
            imageClick: imagePopup.openPopup.bind(imagePopup)
            messageId: model.messageId
            emojiReactions: model.emojiReactions
            linkUrls: model.linkUrls
            communityId: model.communityId
            hasMention: model.hasMention
            stickerPackId: model.stickerPackId
            prevMessageIndex: {
                // This is used in order to have access to the previous message and determine the timestamp
                // we can't rely on the index because the sequence of messages is not ordered on the nim side
                if (msgDelegate.DelegateModel.itemsIndex < messageListDelegate.items.count - 1) {
                    return messageListDelegate.items.get(msgDelegate.DelegateModel.itemsIndex + 1).model.index
                }
                return -1;
            }
            scrollToBottom: chatLogView.scrollToBottom
            timeout: model.timeout
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
