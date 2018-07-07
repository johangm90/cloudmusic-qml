#include <QtQml>
#include <QtQml/QQmlContext>

#include "plugin.h"
#include "apu.h"

void ApuPlugin::registerTypes(const char *uri) {
    //@uri Apu
    qmlRegisterSingletonType<Apu>(uri, 1, 0, "Apu", [](QQmlEngine*, QJSEngine*) -> QObject* { return new Apu; });
}
