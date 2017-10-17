#ifndef FILEMANAGER_H
#define FILEMANAGER_H

#include <QObject>

class FileManager : public QObject
{
    Q_OBJECT

public:
    explicit FileManager(QObject *parent = 0);
    ~FileManager();

public:
    Q_INVOKABLE void deleteFile(QString path);
    Q_INVOKABLE QString saveDownload(QString path);
};

#endif // FILEMANAGER_H

