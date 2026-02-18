import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.2
import "../logic/Api.js" as Api
import "../logic/Database.js" as Db
import "../components"

Page {
    id: searchPage
    property var appRoot
    property color textColor: appRoot ? appRoot.textColor : "#1f1f1f"
    property color secondaryTextColor: appRoot ? appRoot.secondaryTextColor : "#898B8C"
    property color cardColor: appRoot ? appRoot.cardColor : "#ffffff"
    property color borderColor: appRoot ? appRoot.borderColor : "#d8d8d8"
    property color sectionColor: appRoot ? appRoot.sectionColor : "#333333"
    property color selectedColor: appRoot ? appRoot.selectedColor : "#5d5d5d"
    property color accentColor: appRoot ? appRoot.primaryColor : "#e53446"
    property var searchModel: refineDataModel()
    property int numKeys : dataModel.count
    property var showPopup : true
    property int currentTab: 0
    property int tabAnimDuration: LomiriAnimation.FastDuration

    header: PageHeader {
        title: i18n.tr("Search")
        contents: TextField {
            id: search_query
            inputMethodHints: Qt.ImhNoPredictiveText
            placeholderText: i18n.tr("Search")
            
            signal closePopover()
            
            onVisibleChanged: {
                if (visible) {
                    forceActiveFocus()
                }
            }
            anchors.fill: parent
            anchors.rightMargin: units.gu(2)
            anchors.topMargin: units.gu(1)
            anchors.bottomMargin: units.gu(1)
            onTextChanged: {
                      closePopover();
                      if (numKeys>0) {
                            if (length>0) {
                                  searchModel = refineDataModel();
                                  var properties = {
                                      "model": searchModel,
                                      "itemHeight": search_query.height,
                                      "itemMargins": units.gu(0.5),
                                      "contentWidth": search_query.width,
                                      "textRole": "searchkey",
                                  }
                                  if (refDataModel.count==1) {
                                        var str1 = refDataModel.get(0).searchkey;
                                        var str1b = str1.toLowerCase();
                                        var str2 = search_query.text;
                                        var str2b = str2.toLowerCase();
                                        if (str1b == str2b) {
                                          showPopup = false;
                                        }
                                  } else {
                                    if (refDataModel.count==0) {
                                      showPopup = false;
                                    }
                                  }
                            } else {
                                  var properties = {
                                      "model": dataModel,
                                      "itemHeight": search_query.height,
                                      "itemMargins": units.gu(0.5),
                                      "contentWidth": search_query.width,
                                      "textRole": "searchkey",
                                  }
                            }
                      } else {
                         showPopup = false
                      }
                      if (showPopup) {
                        PopupUtils.open(comboBoxPopup, search_query , properties);
                        forceActiveFocus()
                      } else {
                        search_query.cursorVisible = false
                      }
                      showPopup = true;
            }
            Keys.onReturnPressed: {
                if(search_query.text!=''){
                    Db.insertSearchHistory(search_query.text, 20)
                    populateDataModel()
                    Api.apiSearch(search_query.text, 0, 50, searchApiContext())
                    search_query.cursorVisible = false
                } else {
                    console.log('search parameter is empty')
                }
            }
        }
    }

    Component.onCompleted: { is_visible(false);
              populateDataModel()
              var properties = {
                  "model": dataModel,
                  "itemHeight": search_query.height,
                  "itemMargins": units.gu(0.5),
                  "contentWidth": search_query.width,
                  "textRole": "searchkey",
              }
              PopupUtils.open(comboBoxPopup, search_query, properties); 
              search_query.cursorVisible = true
    }

    function is_visible(value){
        results_tabs.visible = value;
        results_stack.visible = value;
        if (value) {
            currentTab = 0;
        }
    }

    ListModel {
        id: dataModel
    }

    ListModel {
        id: refDataModel
    }

    SongDialog {
        id: song_dialog
    }

    ActivityIndicator {
        id: search_songs_loader
        anchors.centerIn: parent
        z: 1
    }
    ActivityIndicator {
        id: search_albums_loader
        anchors.centerIn: parent
        z: 1
    }
    ActivityIndicator {
        id: search_artists_loader
        anchors.centerIn: parent
        z: 1
    }

    ListModel {
        id: searchSongsModel
    }

    ListModel {
        id: searchAlbumsModel
    }

    ListModel {
        id: searchArtistsModel
    }

    Component {
        id: comboBoxPopup
        Popover {
              id: comboBoxPopOver
          
              implicitHeight: (numKeys * itemHeight <= searchPage.height - searchPage.header.height*2) ? numKeys * itemHeight : (numKeys - Math.floor((numKeys * itemHeight - searchPage.height + searchPage.header.height*2)/itemHeight)) * itemHeight
              contentHeight: Math.min(implicitHeight, listView.count * itemHeight)
              callerMargin: -units.gu(1)
          
              property var model
              property real itemHeight
              property real itemMargins
              property string textRole
              
          
              ScrollView {
                  width: comboBoxPopOver.contentWidth
                  height: comboBoxPopOver.contentHeight
          
                  ListView {
                      id: listView
                      width: comboBoxPopOver.contentWidth
                      height: comboBoxPopOver.contentHeight
                      model: comboBoxPopOver.model
                      clip: true
                      delegate: MouseArea {
                          id: mouseArea
                          anchors {
                              left: parent.left
                              right: parent.right
                          }
                          height: comboBoxPopOver.itemHeight
                          onClicked: {
                              showPopup = false;
                              search_query.text = comboBoxPopOver.model.get(index)[textRole];
                              Api.apiSearch(search_query.text, 0, 50, searchApiContext());
                              PopupUtils.close(comboBoxPopOver);
                          }
                          onPressAndHold: {
                            PopupUtils.open(dialog);
                          }
          
                          hoverEnabled: true
                          
                          Component {
                                 id: dialog
                                 Dialog {
                                     id: dialogue
                                     title: i18n.tr("Item deletion")
                                     text: i18n.tr("The selected element to be deleted from the search list is: ") + " " + comboBoxPopOver.model.get(index)[textRole]
                                     Button {
                                          text: i18n.tr("Delete")
                                          color: LomiriColors.red
                                          onClicked: {
                                             Db.deleteSearchHistory(comboBoxPopOver.model.get(index)[textRole])
                                             populateDataModel()
                                             search_query.textChanged()
                                             PopupUtils.close(dialogue)
                                          }
                                     }
                                     Button {
                                          text: i18n.tr("Return")
                                          color: LomiriColors.graphite
                                          onClicked: PopupUtils.close(dialogue)
                                     }
                                 }
                          }
                          
                          Rectangle {
                            anchors.fill: parent
                            color: cardColor
                            Rectangle {
                                visible: mouseArea.containsMouse
                                anchors.fill: parent
                                color: searchPage.appRoot ? searchPage.appRoot.primaryColor : "red"
                                border.width: units.dp(1)
                                border.color: Qt.darker(color, 1.02)
                                antialiasing: true
                            }
          
                            Label {
                                id: label
                                anchors {
                                    fill: parent
                                    leftMargin: comboBoxPopOver.itemMargins
                                    rightMargin: comboBoxPopOver.itemMargins
                                }
                                text: model[textRole]
                                color: textColor
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
          
                            }
                          }
                      }
                  }
              }

              Connections {
                  target: search_query
                  onClosePopover: PopupUtils.close(comboBoxPopOver)
              }
        }
    }

    Rectangle {
        color: appRoot ? appRoot.pageColor : "transparent"
        anchors {
            top: searchPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: media_player.playbackState != 0 ? units.gu(7.25) : 0
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: results_tabs
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                Layout.topMargin: 0
                height: units.gu(6)
                color: cardColor
                border.color: borderColor
                border.width: 1
                radius: units.gu(1)
                clip: true

                Row {
                    anchors.fill: parent
                    anchors.margins: units.gu(0.6)
                    spacing: units.gu(0.6)

                    Rectangle {
                        id: tabSongs
                        width: (parent.width - units.gu(1.2)) / 3
                        height: parent.height
                        radius: units.gu(0.8)
                        color: searchPage.currentTab === 0 ? accentColor : "transparent"
                        border.color: searchPage.currentTab === 0 ? accentColor : borderColor
                        border.width: 1
                        Label {
                            anchors.centerIn: parent
                            text: i18n.tr("Songs")
                            color: searchPage.currentTab === 0 ? (appRoot ? appRoot.inverseTextColor : "#fff") : textColor
                            fontSize: "small"
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: searchPage.currentTab = 0
                        }
                    }

                    Rectangle {
                        id: tabAlbums
                        width: (parent.width - units.gu(1.2)) / 3
                        height: parent.height
                        radius: units.gu(0.8)
                        color: searchPage.currentTab === 1 ? accentColor : "transparent"
                        border.color: searchPage.currentTab === 1 ? accentColor : borderColor
                        border.width: 1
                        Label {
                            anchors.centerIn: parent
                            text: i18n.tr("Albums")
                            color: searchPage.currentTab === 1 ? (appRoot ? appRoot.inverseTextColor : "#fff") : textColor
                            fontSize: "small"
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: searchPage.currentTab = 1
                        }
                    }

                    Rectangle {
                        id: tabArtists
                        width: (parent.width - units.gu(1.2)) / 3
                        height: parent.height
                        radius: units.gu(0.8)
                        color: searchPage.currentTab === 2 ? accentColor : "transparent"
                        border.color: searchPage.currentTab === 2 ? accentColor : borderColor
                        border.width: 1
                        Label {
                            anchors.centerIn: parent
                            text: i18n.tr("Artists")
                            color: searchPage.currentTab === 2 ? (appRoot ? appRoot.inverseTextColor : "#fff") : textColor
                            fontSize: "small"
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: searchPage.currentTab = 2
                        }
                    }
                }
            }

            Item {
                id: results_stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                Layout.topMargin: 0
                Layout.bottomMargin: 0

                Rectangle {
                    id: songs_layout
                    color: cardColor
                    anchors.fill: parent
                    visible: opacity > 0
                    opacity: searchPage.currentTab === 0 ? 1 : 0
                    Behavior on opacity {
                        LomiriNumberAnimation { duration: tabAnimDuration }
                    }

                    Rectangle {
                        id: songs_title
                        color: sectionColor
                        width: parent.width
                        height: units.gu(5)
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(1)
                            anchors.verticalCenter: parent.verticalCenter
                            text: i18n.tr("Songs")
                            fontSize: "large"
                            color: textColor
                        }
                    }

                    ActionSelectionPopover {
                        id: context_menu
                        z: 999

                        function close() {
                            context_menu.hide()
                            songsList.index = -1
                        }

                        delegate: ListItem {

                            contentItem.anchors {
                                leftMargin: units.gu(2)
                                rightMargin: units.gu(2)
                            }

                            Icon {
                                id: icon
                                width: units.gu(3)
                                height: width
                                name: action.name
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Label {
                                text: action.text
                                anchors.left: icon.right
                                anchors.leftMargin: units.gu(2)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        actions: ActionList {

                            Action {
                                text: i18n.tr("Download")
                                name: "save"
                                onTriggered: {
                                    Api.download(searchSongsModel.get(songsList.index).id, searchSongsModel.get(songsList.index).name, searchSongsModel.get(songsList.index).artist)
                                    context_menu.close()
                                }
                            }
                            Action {
                                text: i18n.tr("Add to playlist")
                                name: "add-to-playlist"
                                onTriggered: {
                                    song_dialog.get_playlists()
                                    song_dialog.model_song.clear()
                                    song_dialog.model_song.append(searchSongsModel.get(songsList.index))
                                    song_dialog.open_dialog()
                                    context_menu.close()
                                }
                            }
                            Action {
                                text: i18n.tr("Add to queue")
                                name: "navigation-menu"
                                onTriggered: {
                                    playing_page.songs_list.push(searchSongsModel.get(songsList.index).id)
                                    media_player.additem((searchPage.appRoot ? searchPage.appRoot.server : "") + 'play/' + searchSongsModel.get(songsList.index).id + '/' + (searchPage.appRoot && searchPage.appRoot.settings ? searchPage.appRoot.settings.streaming_quality : "320"))
                                    playing_page.model_queue.append(searchSongsModel.get(songsList.index))
                                    context_menu.close()
                                    messager.show_message(i18n.tr("Song added to queue"), 3)
                                }
                            }
                            Action {
                                text: i18n.tr("Go to album")
                                name: "slideshow"
                                onTriggered: {
                                    album_page.cargar(searchSongsModel.get(songsList.index).album_id);
                                    pagestack.push(albumPage);
                                    context_menu.close()
                                }
                            }
                            Action {
                                text: i18n.tr("Go to artist")
                                name: "contact"
                                onTriggered: {
                                    artist_page.cargar(searchSongsModel.get(songsList.index).artist_id);
                                    pagestack.push(artistPage);
                                    context_menu.close()
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: songs_view
                        color: "transparent"
                        anchors.top: songs_title.bottom
                        anchors.bottom: parent.bottom
                        width: parent.width
                        Item {
                            width: parent.width
                            height: parent.height
                            ListView {
                                id: songsList
                                property int index: -1
                                clip: true
                                model: searchSongsModel
                                width: parent.width
                                height: parent.height
                                boundsBehavior: Flickable.StopAtBounds
                                delegate: ListItem {
                                    contentItem.anchors {
                                        leftMargin: units.gu(2)
                                        rightMargin: units.gu(2)
                                        topMargin: units.gu(1)
                                        bottomMargin: units.gu(1)
                                    }

                                    color: songsList.index == index ? selectedColor : "transparent"

                                    Label {
                                        id: lbl_name
                                        text: name
                                        elide: Label.ElideRight
                                        anchors.left: parent.left
                                        anchors.right: lbl_duration.left
                                        color: textColor
                                    }

                                    Label {
                                        id: lbl_artist
                                        text: artist
                                        fontSize: "small"
                                        color: secondaryTextColor
                                        elide: Label.ElideRight
                                        anchors.left: parent.left
                                        anchors.right: lbl_duration.left
                                        anchors.bottom: parent.bottom
                                    }

                                    Label {
                                        id: lbl_duration
                                        text: Api.durationToString(duration)
                                        width: units.gu(5)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: item_menu.left
                                        horizontalAlignment: Text.AlignRight
                                        color: secondaryTextColor
                                    }

                                    MouseArea {
                                        id: item_menu
                                        width: units.gu(5)
                                        height: parent.height
                                        anchors.right: parent.right
                                        onClicked: {
                                            if(songsList.index == index) {
                                                context_menu.close()
                                            } else {
                                                songsList.index = index
                                            }

                                            context_menu.caller = item_menu
                                            context_menu.show()
                                        }

                                        Icon {
                                            height: units.gu(3)
                                            width: height
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: "contextual-menu"
                                        }
                                    }

                                    onClicked: {
                                        var songs = [];
                                        var songs_ids = [];
                                        playing_page.model_queue.clear()
                                        for(var i = 0; i < searchSongsModel.count; i++) {
                                            songs.push((searchPage.appRoot ? searchPage.appRoot.server : "") + 'play/' + searchSongsModel.get(i).id + '/' + (searchPage.appRoot && searchPage.appRoot.settings ? searchPage.appRoot.settings.streaming_quality : "320"));
                                            songs_ids.push(searchSongsModel.get(i).id);
                                            playing_page.model_queue.append(searchSongsModel.get(i));
                                        }
                                        pagestack.push(playingPage);
                                        playing_page.songs_list = songs_ids
                                        media_player.setPlaylist(songs, index)
                                    }
                                }
                            }
                            Scrollbar {
                                flickableItem: songsList
                                align: Qt.AlignTrailing
                            }
                        }
                    }
                }

                Rectangle {
                    id: albums_layout
                    color: cardColor
                    anchors.fill: parent
                    visible: opacity > 0
                    opacity: searchPage.currentTab === 1 ? 1 : 0
                    Behavior on opacity {
                        LomiriNumberAnimation { duration: tabAnimDuration }
                    }

                    Rectangle {
                        id: albums_title
                        color: sectionColor
                        width: parent.width
                        height: units.gu(5)
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(1)
                            anchors.verticalCenter: parent.verticalCenter
                            text: i18n.tr("Albums")
                            fontSize: "large"
                            color: textColor
                        }
                    }

                    Rectangle {
                        id: albums_view
                        color: "transparent"
                        anchors.top: albums_title.bottom
                        anchors.bottom: parent.bottom
                        width: parent.width
                        Item {
                            width: parent.width
                            height: parent.height
                            ListView {
                                id: albums_list
                                property int index: 0
                                clip: true
                                model: searchAlbumsModel
                                width: parent.width
                                height: parent.height
                                boundsBehavior: Flickable.StopAtBounds
                                delegate: ListItem {
                                    id: albumlist
                                    contentItem.anchors {
                                        leftMargin: units.gu(2)
                                        rightMargin: units.gu(2)
                                        topMargin: units.gu(1)
                                        bottomMargin: units.gu(1)
                                    }
                                    Label {
                                        id: lbl__album_name
                                        text: name
                                        elide: Label.ElideRight
                                        anchors.left: parent.left
                                        anchors.right: lbl__album_size.left
                                        color: textColor
                                    }

                                    Label {
                                        id: lbl__album_artist
                                        text: artist
                                        fontSize: "small"
                                        color: secondaryTextColor
                                        elide: Label.ElideRight
                                        anchors.left: parent.left
                                        anchors.right: lbl__album_size.left
                                        anchors.bottom: parent.bottom
                                    }

                                    Label {
                                        id: lbl__album_size
                                        text: size
                                        width: units.gu(5)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.right
                                        horizontalAlignment: Text.AlignRight
                                        color: secondaryTextColor
                                    }

                                    onClicked: {
                                        album_page.cargar(id);
                                        pagestack.push(albumPage);
                                    }
                                }
                            }
                            Scrollbar {
                                flickableItem: albums_list
                                align: Qt.AlignTrailing
                            }
                        }
                    }
                }

                Rectangle {
                    id: artists_layout
                    color: cardColor
                    anchors.fill: parent
                    visible: opacity > 0
                    opacity: searchPage.currentTab === 2 ? 1 : 0
                    Behavior on opacity {
                        LomiriNumberAnimation { duration: tabAnimDuration }
                    }

                    Rectangle {
                        id: artists_title
                        color: sectionColor
                        width: parent.width
                        height: units.gu(5)
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(1)
                            anchors.verticalCenter: parent.verticalCenter
                            text: i18n.tr("Artists")
                            fontSize: "large"
                            color: textColor
                        }
                    }

                    Rectangle {
                        id: artists_view
                        color: "transparent"
                        anchors.top: artists_title.bottom
                        anchors.bottom: parent.bottom
                        width: parent.width
                        clip: true

                        GridView {
                            id: artistsView
                            anchors {
                                margins: 0
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            z: 1
                            width: parent.width
                            height: parent.height
                            cellWidth: (searchPage.appRoot ? searchPage.appRoot.width : width) > units.gu(25) ? (parent.width/Math.ceil(parent.width/units.gu(25))) : (parent.width)
                            cellHeight: cellWidth + units.gu(4)
                            model: searchArtistsModel
                            cacheBuffer: 1000

                            delegate: MouseArea {
                                width: artistsView.cellWidth
                                height: artistsView.cellHeight
                                Column {
                                    id: delegateitem
                                    anchors.fill: parent
                                    Image {
                                        id: wimage
                                        width: parent.width
                                        height: parent.height - units.gu(4)
                                        source: image ? image : "../graphics/default.png"
                                        clip: true
                                        cache: true
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                    Rectangle {
                                        color: cardColor
                                        border.color: borderColor
                                        border.width: 1
                                        width: artistsView.cellWidth
                                        height: units.gu(4)
                                        Label {
                                            text: name
                                            width: artistsView.cellWidth
                                            anchors.margins: units.gu(2)
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.verticalCenter: parent.verticalCenter
                                            elide: Text.ElideRight
                                            fontSize: "medium"
                                            color: textColor
                                        }
                                    }
                                }

                                onClicked: {
                                    artist_page.cargar(id);
                                    pagestack.push(artistPage);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    function populateDataModel() {
        dataModel.clear()
        var history = Db.getSearchHistory(20)
        for (var i = 0; i < history.length; i++) {
            var keyWord = history[i]
            dataModel.append({"searchkey": keyWord})
        }
    }

    function searchApiContext() {
        return {
            setVisible: is_visible,
            songsModel: searchSongsModel,
            albumsModel: searchAlbumsModel,
            artistsModel: searchArtistsModel,
            songsLoader: search_songs_loader,
            albumsLoader: search_albums_loader,
            artistsLoader: search_artists_loader
        }
    }

    function refineDataModel() {
      refDataModel.clear()
      if (search_query.text != "") {
          for (var i=0; i < dataModel.count; i++) {
              var keyWord = dataModel.get(i).searchkey
              var keyWordApp = keyWord.toLowerCase();
              var checkStr = search_query.text.toLowerCase();
              var resultStr = keyWordApp.indexOf(checkStr);
              if (resultStr == 0) {
                refDataModel.append({"searchkey": keyWord})
              }
          }
      }
      if (search_query.text == null) {
        return dataModel
      } else {
        return refDataModel
      }
    }
}
