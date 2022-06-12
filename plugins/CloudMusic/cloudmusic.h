#ifndef CloudMusic_H
#define CloudMusic_H

#include <QObject>

class CloudMusic: public QObject {
    Q_OBJECT

public:
    CloudMusic();
    ~CloudMusic() = default;

    Q_INVOKABLE void changeFileName(const QString urlFile, const QString fileName, const QString nameSong);
};

#endif
