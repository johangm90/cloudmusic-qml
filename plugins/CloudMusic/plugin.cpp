#include <QtQml>
#include <QtQml/QQmlContext>

#include "plugin.h"
#include "cloudmusic.h"

void CloudMusicPlugin::registerTypes(const char *uri) {
    //@uri CloudMusic
    qmlRegisterSingletonType<CloudMusic>(uri, 1, 0, "CloudMusic", [](QQmlEngine*, QJSEngine*) -> QObject* { return new CloudMusic; });
}
