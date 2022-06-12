#include <QDebug>
#include <QString>
#include <QProcess>

#include "cloudmusic.h"

using namespace std;

CloudMusic::CloudMusic() {

}

void CloudMusic::changeFileName(QString urlFile, QString fileDir,QString nameSong) {
  array<char, 128> buffer;
  QString QSresult;
  string result;
  string command = "mv -f " + urlFile.toStdString() + " " + fileDir.toStdString() + nameSong.toStdString() + ".mp3";
  QString commandStr = QString::fromStdString(command);
  FILE* pipe = popen(command.c_str(), "r");
  if (!pipe) {
    qDebug() << "Couldn't start command -" << commandStr << "-";
  } else {
    qDebug() << "Command -" << commandStr << "- executed with success.";
  }
  while (fgets(buffer.data(), 128, pipe) != NULL) {
    result += buffer.data();
    QSresult = QString::fromStdString(result);
    QSresult = QSresult.trimmed();
  }
  qDebug() << QSresult;
}
