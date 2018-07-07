#ifndef APUPLUGIN_H
#define APUPLUGIN_H

#include <QQmlExtensionPlugin>

class ApuPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri);
};

#endif
