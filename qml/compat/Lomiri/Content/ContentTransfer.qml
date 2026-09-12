pragma Singleton
import QtQuick 2.7

QtObject {
    enum SelectionType {
        Single = 0,
        Multiple = 1
    }
    enum State {
        Created = 0,
        InProgress = 1,
        Charged = 2,
        Collected = 3,
        Aborted = 4,
        Finalized = 5,
        Downloading = 6,
        Downloaded = 7
    }
}
