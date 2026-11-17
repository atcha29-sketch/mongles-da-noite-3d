#include "gamepad.h"

#include <SDL.h>

#include <QDebug>
#include <QtMath>

Gamepad::Gamepad(QObject *parent) : QObject(parent)
{
    if (SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) < 0) {
        qWarning() << "Controller support is unavailable:" << SDL_GetError();
        return;
    }

    m_ready = true;
    SDL_GameControllerEventState(SDL_ENABLE);
    for (int i = 0; i < SDL_NumJoysticks() && !m_controller; ++i)
        openController(i);

    m_timer.setInterval(16);
    connect(&m_timer, &QTimer::timeout, this, &Gamepad::poll);
    m_timer.start();
}

Gamepad::~Gamepad()
{
    m_timer.stop();
    closeController();
    if (m_ready)
        SDL_QuitSubSystem(SDL_INIT_GAMECONTROLLER);
}

qreal Gamepad::normalizeAxis(qint16 value)
{
    constexpr qreal deadzone = 0.18;
    const qreal axis = value < 0 ? value / 32768.0 : value / 32767.0;
    const qreal magnitude = qAbs(axis);
    if (magnitude <= deadzone)
        return 0;
    return (axis < 0 ? -1 : 1) * (magnitude - deadzone) / (1 - deadzone);
}

static QString controllerButtonName(int button)
{
    switch (button) {
    case SDL_CONTROLLER_BUTTON_A: return "a";
    case SDL_CONTROLLER_BUTTON_B: return "b";
    case SDL_CONTROLLER_BUTTON_X: return "x";
    case SDL_CONTROLLER_BUTTON_Y: return "y";
    case SDL_CONTROLLER_BUTTON_START: return "start";
    case SDL_CONTROLLER_BUTTON_DPAD_UP: return "up";
    case SDL_CONTROLLER_BUTTON_DPAD_DOWN: return "down";
    case SDL_CONTROLLER_BUTTON_DPAD_LEFT: return "left";
    case SDL_CONTROLLER_BUTTON_DPAD_RIGHT: return "right";
    case SDL_CONTROLLER_BUTTON_LEFTSHOULDER: return "leftShoulder";
    case SDL_CONTROLLER_BUTTON_RIGHTSHOULDER: return "rightShoulder";
    default: return {};
    }
}

void Gamepad::openController(int deviceIndex)
{
    if (m_controller || !SDL_IsGameController(deviceIndex))
        return;

    m_controller = SDL_GameControllerOpen(deviceIndex);
    if (!m_controller) {
        qWarning() << "Could not open game controller:" << SDL_GetError();
        return;
    }

    m_instanceId = SDL_JoystickInstanceID(SDL_GameControllerGetJoystick(m_controller));
    emit changed();
}

void Gamepad::closeController()
{
    if (m_controller)
        SDL_GameControllerClose(m_controller);
    m_controller = nullptr;
    m_instanceId = -1;
    m_leftX = 0;
    m_leftY = 0;
    m_pressedButtons.clear();
}

void Gamepad::poll()
{
    SDL_PumpEvents();
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_CONTROLLERDEVICEADDED && !m_controller)
            openController(event.cdevice.which);
        else if (event.type == SDL_CONTROLLERDEVICEREMOVED
                 && event.cdevice.which == m_instanceId) {
            closeController();
            for (int i = 0; i < SDL_NumJoysticks() && !m_controller; ++i)
                openController(i);
            emit changed();
        }
    }

    if (!m_controller)
        return;

    SDL_GameControllerUpdate();
    for (int i = 0; i < SDL_CONTROLLER_BUTTON_MAX; ++i) {
        const bool pressed = SDL_GameControllerGetButton(
            m_controller, static_cast<SDL_GameControllerButton>(i));
        const bool wasPressed = m_pressedButtons.contains(i);
        if (pressed && !wasPressed) {
            const QString name = controllerButtonName(i);
            if (!name.isEmpty())
                emit buttonPressed(name);
            m_pressedButtons.insert(i);
        } else if (!pressed && wasPressed) {
            m_pressedButtons.remove(i);
        }
    }

    const qreal nextX = normalizeAxis(SDL_GameControllerGetAxis(
        m_controller, SDL_CONTROLLER_AXIS_LEFTX));
    const qreal nextY = normalizeAxis(SDL_GameControllerGetAxis(
        m_controller, SDL_CONTROLLER_AXIS_LEFTY));
    if (qAbs(nextX - m_leftX) > 0.01 || qAbs(nextY - m_leftY) > 0.01) {
        m_leftX = nextX;
        m_leftY = nextY;
        emit changed();
    }
}
