TEMPLATE = aux
TARGET = apu

RESOURCES += apu.qrc

COMPONENTS_FILES += $$files(components/*.qml,true) \
                    $$files(components/*.js,true)

GRAPHICS_FILES += $$files(graphics/*.svg,true) \
                  $$files(graphics/*.png,true) \
                  $$files(graphics/*.png,true)

LOGIC_FILES += $$files(logic/*.qml,true) \
               $$files(logic/*.js,true)

THEMES_FILES += $$files(themes/*.qml,true) \
                $$files(themes/*.js,true)

UI_FILES += $$files(ui/*.qml,true) \
            $$files(ui/*.js,true)

QML_FILES += $$files(*.qml,true) \
             $$files(*.js,true)

CONF_FILES +=  apu.apparmor \
               apu.png

AP_TEST_FILES += tests/autopilot/run \
                 $$files(tests/*.py,true)

OTHER_FILES += $${CONF_FILES} \
               $${COMPONENTS_FILES} \
               $${GRAPHICS_FILES} \
               $${LOGIC_FILES} \
               $${THEMES_FILES} \
               $${UI_FILES} \
               $${QML_FILES} \
               $${AP_TEST_FILES} \
               apu.desktop 

#specify where the components module files are installed to
components_files.path = /apu/components
components_files.files += $${COMPONENTS_FILES}

#specify where the graphics module files are installed to
graphics_files.path = /apu/graphics
graphics_files.files += $${GRAPHICS_FILES}

#specify where the logic module files are installed to
logic_files.path = /apu/logic
logic_files.files += $${LOGIC_FILES}

#specify where the logic module files are installed to
themes_files.path = /apu/themes
themes_files.files += $${THEMES_FILES}

#specify where the logic module files are installed to
ui_files.path = /apu/ui
ui_files.files += $${UI_FILES}

#specify where the qml/js files are installed to
qml_files.path = /apu
qml_files.files += $${QML_FILES}

#specify where the config files are installed to
config_files.path = /apu
config_files.files += $${CONF_FILES}

#install the desktop file, a translated version is automatically created in 
#the build directory
desktop_file.path = /apu
desktop_file.files = $$OUT_PWD/apu.desktop 
desktop_file.CONFIG += no_check_exist 

INSTALLS+=config_files components_files graphics_files logic_files themes_files ui_files qml_files desktop_file

DISTFILES += \
    ui/Artist.qml \
    components/Player.qml \
    ui/Album.qml \
    ui/NowPlaying.qml \
    logic/Database.js \
    ui/NewAlbums.qml \
    ui/Search.qml \
    ui/SettingsPage.qml \
    ui/Playlists.qml \
    components/PlayerToolbar.qml \
    ui/PlaylistDetail.qml \
    ui/About.qml \
    ui/SearchHistory.qml \
    components/TabsList.qml \
    ui/Credits.qml \
    components/HeaderListItem.qml \
    components/SongDialog.qml \
    components/Messager.qml \
    ui/Queue.qml \
    components/DownloadDialog.qml \
    components/ChangeLogListItem.qml \
    components/ChangeLogDialog.qml

