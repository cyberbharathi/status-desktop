import QtQuick 2.13
import QtQuick.Controls 2.13
import QtGraphicalEffects 1.13
import "../../../../shared"
import "../../../../shared/status"
import "../../../../imports"
import "."

Rectangle {
    id: root
    height: 220
    anchors.left: parent.left
    anchors.leftMargin: Style.current.padding
    anchors.right: parent.right
    anchors.rightMargin: Style.current.padding
    border.color: Style.current.border
    radius: 16
    color: Style.current.transparent

    SVGImage {
        anchors.top: parent.top
        anchors.topMargin: -6
        anchors.horizontalCenter: parent.horizontalCenter
        source: "../../../img/chatEmptyHeader.svg"
        width: 66
        height: 50
    }

    StatusIconButton {
        icon.name: "close"
        id: closeImg
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        icon.height: 20
        icon.width: 20
        iconColor: Style.current.darkGrey
        onClicked: {
            let hiddenBannerIds = appSettings.hiddenCommunityWelcomeBanners
            hiddenBannerIds.push(chatsModel.communities.activeCommunity.id)
            appSettings.hiddenCommunityWelcomeBanners = hiddenBannerIds
            root.visible = false
        }
    }

    StyledText {
        id: welcomeText
        //% "Welcome to your community!"
        text: qsTrId("welcome-to-your-community-")
        anchors.top: parent.top
        anchors.topMargin: 60
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 15
        wrapMode: Text.WordWrap
        anchors.right: parent.right
        anchors.rightMargin: Style.current.xlPadding
        anchors.left: parent.left
        anchors.leftMargin: Style.current.xlPadding
    }

    StatusButton {
        id: addMembersBtn
        //% "Add members"
        text: qsTrId("add-members")
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: manageBtn.top
        anchors.bottomMargin: Style.current.halfPadding
        onClicked: openPopup(inviteFriendsToCommunityPopup)
    }

    StatusButton {
        id: manageBtn
        //% "Manage community"
        text: qsTrId("manage-community")
        type: "secondary"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.current.padding
        onClicked: {
          communityProfilePopup.communityId = chatsModel.communities.activeCommunity.id;
          communityProfilePopup.name = chatsModel.communities.activeCommunity.name;
          communityProfilePopup.description = chatsModel.communities.activeCommunity.description;
          communityProfilePopup.access = chatsModel.communities.activeCommunity.access;
          communityProfilePopup.nbMembers = chatsModel.communities.activeCommunity.nbMembers;
          communityProfilePopup.isAdmin = chatsModel.communities.activeCommunity.admin;
          communityProfilePopup.source = chatsModel.communities.activeCommunity.thumbnailImage
          communityProfilePopup.communityColor = chatsModel.communities.activeCommunity.communityColor
          communityProfilePopup.open()
        }
    }
}
