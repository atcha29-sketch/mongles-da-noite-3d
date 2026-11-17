#pragma once

#include <QObject>
#include <QSet>
#include <QTimer>

struct _SDL_GameController;

class Gamepad : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready CONSTANT)
    Q_PROPERTY(bool connected READ connected NOTIFY changed)
    Q_PROPERTY(qreal leftX READ leftX NOTIFY changed)
    Q_PROPERTY(qreal leftY READ leftY NOTIFY changed)

public:
    explicit Gamepad(QObject *parent = nullptr);
    ~Gamepad() override;

    bool ready() const { return m_ready; }
    bool connected() const { return m_controller != nullptr; }
    qreal leftX() const { return m_leftX; }
    qreal leftY() const { return m_leftY; }

signals:
    void changed();
    void buttonPressed(const QString &button);

private:
    void poll();
    void openController(int deviceIndex);
    void closeController();
    static qreal normalizeAxis(qint16 value);

    QTimer m_timer;
    _SDL_GameController *m_controller = nullptr;
    qint32 m_instanceId = -1;
    qreal m_leftX = 0;
    qreal m_leftY = 0;
    QSet<int> m_pressedButtons;
    bool m_ready = false;
};
