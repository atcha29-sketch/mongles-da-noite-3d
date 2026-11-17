QT += core gui qml quick quick3d quickcontrols2 multimedia

wasm {
    QMAKE_CXXFLAGS += -sUSE_SDL=2
    QMAKE_LFLAGS += -sUSE_SDL=2
} else {
    CONFIG += link_pkgconfig
    PKGCONFIG += sdl2
}

CONFIG += c++17 release
TARGET = mongles-da-noite
TEMPLATE = app

HEADERS += \
    src/backend.h \
    src/arena_instancing.h \
    src/gamepad.h \
    src/theme.h \
    src/translator.h

SOURCES += \
    src/main.cpp \
    src/backend.cpp \
    src/arena_instancing.cpp \
    src/gamepad.cpp \
    src/theme.cpp \
    src/translator.cpp

RESOURCES += src/resources.qrc
