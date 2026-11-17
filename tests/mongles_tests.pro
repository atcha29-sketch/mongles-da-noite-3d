QT += core gui multimedia testlib
CONFIG += c++17 testcase
TARGET = mongles_tests
TEMPLATE = app

INCLUDEPATH += ../src
HEADERS += ../src/backend.h ../src/translator.h
SOURCES += mongles_tests.cpp ../src/backend.cpp ../src/translator.cpp
