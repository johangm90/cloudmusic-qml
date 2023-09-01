#include <QFile>
#include <QDebug>
#include <QDir>
#include <QStandardPaths>

#include "filemanager.h"

FileManager::FileManager(QObject *parent):
    QObject(parent)
{
    // Remove any downloads that haven't been collected previously (because we were closed before they finished)
    QString downloadManagerPath = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QDir::separator() + "lomiri-download-manager" + QDir::separator() + "apu.johangm90";
    QDir downloadDir(downloadManagerPath);
    if (downloadDir.exists()) {
        downloadDir.removeRecursively();
    }
}

FileManager::~FileManager() {

}

void FileManager::deleteFile(QString path) {
    QFile file(path);
    if (file.exists()) {
        file.remove();
    }
}

QString FileManager::saveDownload(QString origPath) {
    QString destination = QStandardPaths::writableLocation(QStandardPaths::DataLocation) + QDir::separator() + "Downloads";
    QDir destDir(destination);
    if(!destDir.exists()) {
        destDir.mkpath(destination);
    }
    QFileInfo fi(origPath);
    QFile *destFile;
    QString filePath;
    int attempts = 0;
    do {
        filePath = destination + QDir::separator() + fi.fileName();
        if (attempts > 0) {
            filePath += "." + QString::number(attempts);
        }
        destFile = new QFile(filePath);
        attempts++;
    } while (destFile->exists());
    QFile::rename(origPath, filePath);
    return filePath;
}
