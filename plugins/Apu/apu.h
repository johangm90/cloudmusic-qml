#ifndef APU_H
#define APU_H

#include <QObject>

class Apu: public QObject {
    Q_OBJECT

public:
    Apu();
    ~Apu() = default;

    Q_INVOKABLE void speak();
};

#endif
