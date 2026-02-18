import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.2
import "../logic/Format.js" as Format
import "../logic/RequestBus.js" as RequestBus
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
    property color overlayColor: appRoot && appRoot.designTokens ? appRoot.designTokens.color.overlay : "#55000000"
    property real spacingSmall: appRoot ? appRoot.spacingSmall : units.gu(0.8)
    property real spacingMedium: appRoot ? appRoot.spacingMedium : units.gu(1.2)
    property real sideInset: spacingMedium + spacingSmall
    property real popupItemMargin: spacingSmall * 0.6
    property real sectionTabsHeight: units.gu(6)
    property real sectionTitleHeight: units.gu(5)
    property real sectionTitleInset: spacingSmall + units.gu(0.2)
    property real gridBreakpoint: units.gu(25)
    property real artistCaptionHeight: units.gu(4)
    property string titleTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.title : "large"
    property string bodyTextSize: appRoot && appRoot.designTokens ? appRoot.designTokens.typography.body : "medium"
    property var searchModel: refineDataModel()
    property int numKeys : dataModel.count
    property var showPopup : true
    property int currentTab: 0
    property int tabAnimDuration: LomiriAnimation.FastDuration
    property bool searchLoading: false
    property int pendingSearchRequests: 0
    property string requestContext: "search_" + String(Date.now())

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
            anchors.rightMargin: sideInset
            anchors.topMargin: spacingSmall + units.gu(0.2)
            anchors.bottomMargin: spacingSmall + units.gu(0.2)
            onTextChanged: {
                      closePopover();
                      if (numKeys>0) {
                            if (length>0) {
                                  searchModel = refineDataModel();
                                  var properties = {
                                      "model": searchModel,
                                      "itemHeight": search_query.height,
                                      "itemMargins": popupItemMargin,
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
                                      "itemMargins": popupItemMargin,
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
                      if (search_query.text && search_query.text.length >= 2) {
                          searchDebounce.restart()
                      } else {
                          searchDebounce.stop()
                          searchLoading = false
                      }
            }
            Keys.onReturnPressed: {
                if(search_query.text!=''){
                    searchDebounce.stop()
                    executeSearch(search_query.text, true)
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
                  "itemMargins": popupItemMargin,
                  "contentWidth": search_query.width,
                  "textRole": "searchkey",
              }
              PopupUtils.open(comboBoxPopup, search_query, properties); 
              search_query.cursorVisible = true
    }

    Component.onDestruction: {
        RequestBus.cancelContext(requestContext)
    }

    Timer {
        id: searchDebounce
        interval: 350
        repeat: false
        onTriggered: {
            if (search_query.text && search_query.text.length >= 2) {
                executeSearch(search_query.text, false)
            }
        }
    }

    function formatDate(date) {
        var y = date.getFullYear()
        var m = date.getMonth() + 1
        var d = date.getDate()
        return y + "-" + (m < 10 ? ("0" + m) : m) + "-" + (d < 10 ? ("0" + d) : d)
    }

    function finishSearchRequest() {
        pendingSearchRequests -= 1
        if (pendingSearchRequests <= 0) {
            is_visible(true)
            searchLoading = false
        }
    }

    function runSearchRust(query, limit) {
        if (!appRoot || !appRoot.cloudApi) {
            return false
        }
        RequestBus.cancelContext(requestContext)
        is_visible(false)
        searchSongsModel.clear()
        searchAlbumsModel.clear()
        searchArtistsModel.clear()
        search_songs_loader.running = true
        search_albums_loader.running = true
        search_artists_loader.running = true
        searchLoading = true
        pendingSearchRequests = 3
        var songsRequestId = RequestBus.createId("search_songs")
        var albumsRequestId = RequestBus.createId("search_albums")
        var artistsRequestId = RequestBus.createId("search_artists")

        RequestBus.registerRequest(songsRequestId, {
            context: requestContext,
            onSuccess: function(data) {
                if (data && data.songs) {
                    for (var i = 0; i < data.songs.length; i++) {
                        searchSongsModel.append(data.songs[i])
                    }
                }
            },
            onError: function(err) {
                console.log(err)
            },
            onFinally: function() {
                search_songs_loader.running = false
                finishSearchRequest()
            }
        })
        RequestBus.registerRequest(albumsRequestId, {
            context: requestContext,
            onSuccess: function(data) {
                if (data && data.albums) {
                    for (var j = 0; j < data.albums.length; j++) {
                        var album = data.albums[j]
                        var publishTime = album.publish_time ? album.publish_time : 0
                        searchAlbumsModel.append({
                            id: album.id,
                            name: album.name,
                            artist: album.artist,
                            date: formatDate(new Date(publishTime)),
                            size: album.size,
                            image: album.image ? album.image : "../graphics/default.png",
                            big_image: album.big_image ? album.big_image : "../graphics/default.png",
                            source: "netease"
                        })
                    }
                }
            },
            onError: function(err2) {
                console.log(err2)
            },
            onFinally: function() {
                search_albums_loader.running = false
                finishSearchRequest()
            }
        })
        RequestBus.registerRequest(artistsRequestId, {
            context: requestContext,
            onSuccess: function(data) {
                if (data && data.artists) {
                    for (var k = 0; k < data.artists.length; k++) {
                        searchArtistsModel.append(data.artists[k])
                    }
                }
            },
            onError: function(err3) {
                console.log(err3)
            },
            onFinally: function() {
                search_artists_loader.running = false
                finishSearchRequest()
            }
        })

        appRoot.cloudApi.searchAsync(String(query), "1", Number(limit), songsRequestId)
        appRoot.cloudApi.searchAsync(String(query), "10", Number(limit), albumsRequestId)
        appRoot.cloudApi.searchAsync(String(query), "100", Number(limit), artistsRequestId)
        return true
    }

    Connections {
        target: appRoot && appRoot.cloudApi ? appRoot.cloudApi : null
        onRequestFinished: function(requestId, ok, payloadJson, error) {
            RequestBus.dispatch(requestId, ok, payloadJson, error)
        }
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
        visible: false
    }
    ActivityIndicator {
        id: search_albums_loader
        anchors.centerIn: parent
        z: 1
        visible: false
    }
    ActivityIndicator {
        id: search_artists_loader
        anchors.centerIn: parent
        z: 1
        visible: false
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
              callerMargin: -(spacingSmall + units.gu(0.2))
          
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
                              searchDebounce.stop()
                              executeSearch(search_query.text, true);
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
                                color: accentColor
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
            bottomMargin: media_player.playbackState != 0 ? (appRoot && appRoot.layoutPlayerInset ? appRoot.layoutPlayerInset : units.gu(7.25)) : 0
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
                height: sectionTabsHeight
                color: "transparent"

                SegmentedTabs {
                    anchors.fill: parent
                    labels: [i18n.tr("Songs"), i18n.tr("Albums"), i18n.tr("Artists")]
                    currentIndex: searchPage.currentTab
                    activeColor: accentColor
                    textColor: searchPage.textColor
                    activeTextColor: appRoot ? appRoot.inverseTextColor : "#ffffff"
                    borderColor: searchPage.borderColor
                    backgroundColor: searchPage.cardColor
                    onSelected: function(index) { searchPage.currentTab = index }
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
                        height: sectionTitleHeight
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: sectionTitleInset
                            anchors.verticalCenter: parent.verticalCenter
                            text: i18n.tr("Songs")
                            fontSize: titleTextSize
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
                                leftMargin: sideInset
                                rightMargin: sideInset
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
                                anchors.leftMargin: sideInset
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        actions: ActionList {

                            Action {
                                text: i18n.tr("Download")
                                name: "save"
                                onTriggered: {
                                    if (searchPage.appRoot && searchPage.appRoot.requestSongDownload) {
                                        searchPage.appRoot.requestSongDownload(
                                            searchSongsModel.get(songsList.index).id,
                                            searchSongsModel.get(songsList.index).name,
                                            searchSongsModel.get(songsList.index).artist
                                        )
                                    }
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
                                text: (songsList.index >= 0 && Db.isLikedSong(searchSongsModel.get(songsList.index).id, searchSongsModel.get(songsList.index).source))
                                      ? i18n.tr("Remove from Favorites")
                                      : i18n.tr("Add to Favorites")
                                name: (songsList.index >= 0 && Db.isLikedSong(searchSongsModel.get(songsList.index).id, searchSongsModel.get(songsList.index).source))
                                      ? "like"
                                      : "unlike"
                                onTriggered: {
                                    var liked = Db.toggleLikedSong(searchSongsModel.get(songsList.index))
                                    messager.show_message(liked ? i18n.tr("Added to Favorites") : i18n.tr("Removed from Favorites"), 3)
                                    context_menu.close()
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
                                delegate: SongListItem {
                                    title: name
                                    subtitle: artist
                                    durationText: Format.durationToString(duration)
                                    coverSource: image
                                    albumId: album_id
                                    selected: songsList.index == index
                                    rowTextColor: textColor
                                    rowSecondaryTextColor: secondaryTextColor
                                    selectedColor: searchPage.selectedColor
                                    onMenuClicked: {
                                        if (songsList.index == index) {
                                            context_menu.close()
                                        } else {
                                            songsList.index = index
                                        }
                                        context_menu.caller = caller
                                        context_menu.show()
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
                        height: sectionTitleHeight
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: sectionTitleInset
                            anchors.verticalCenter: parent.verticalCenter
                            text: i18n.tr("Albums")
                            fontSize: titleTextSize
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
                                clip: true
                                model: searchAlbumsModel
                                width: parent.width
                                height: parent.height
                                boundsBehavior: Flickable.StopAtBounds
                                delegate: AlbumListItem {
                                    title: name
                                    subtitle: artist ? (date ? (artist + " • " + date) : artist) : (date ? date : "")
                                    metaText: i18n.tr("%1 song", "%1 songs", size).arg(size)
                                    coverSource: image
                                    albumId: id
                                    rowTextColor: textColor
                                    rowSecondaryTextColor: secondaryTextColor
                                    selectedColor: searchPage.selectedColor
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
                        height: sectionTitleHeight
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: sectionTitleInset
                            anchors.verticalCenter: parent.verticalCenter
                            text: i18n.tr("Artists")
                            fontSize: titleTextSize
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
                            cellWidth: (searchPage.appRoot ? searchPage.appRoot.width : width) > gridBreakpoint ? (parent.width/Math.ceil(parent.width/gridBreakpoint)) : (parent.width)
                            cellHeight: cellWidth + artistCaptionHeight
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
                                        height: parent.height - artistCaptionHeight
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
                                        height: artistCaptionHeight
                                        Label {
                                            text: name
                                            width: artistsView.cellWidth
                                            anchors.margins: sideInset
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.verticalCenter: parent.verticalCenter
                                            elide: Text.ElideRight
                                            fontSize: bodyTextSize
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

        Rectangle {
            anchors.fill: parent
            color: overlayColor
            visible: searchLoading
            z: 200

            ActivityIndicator {
                anchors.centerIn: parent
                running: searchLoading
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

    function executeSearch(query, saveHistory) {
        if (!query || query.length === 0) {
            return
        }
        if (saveHistory) {
            Db.insertSearchHistory(query, 20)
            populateDataModel()
        }
        if (!runSearchRust(query, 50)) {
            searchLoading = false
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
