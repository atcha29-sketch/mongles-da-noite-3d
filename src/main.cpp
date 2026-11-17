#include <QGuiApplication>
#include <QIcon>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QDebug>
#include <cstdio>
#ifndef Q_OS_WASM
#include <QQuickWindow>
#include <QSGRendererInterface>
#endif

#include "backend.h"
#include "arena_instancing.h"
#include "gamepad.h"
#include "theme.h"
#include "translator.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    parser.addOption(QCommandLineOption(
        "vulkan", "Use Vulkan for Qt Quick rendering (desktop builds only)."));
    parser.addOption(QCommandLineOption(
        "opengl", "Use OpenGL instead of Vulkan for Qt Quick rendering."));
    parser.process(app);
#ifndef Q_OS_WASM
    if (parser.isSet("opengl")) {
        QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
        qInfo("Using OpenGL for Qt Quick rendering.");
    } else if (parser.isSet("vulkan")) {
        QQuickWindow::setGraphicsApi(QSGRendererInterface::Vulkan);
        qInfo("Using Vulkan for Qt Quick rendering.");
    } else if (qEnvironmentVariableIsEmpty("QSG_RHI_BACKEND")) {
        QQuickWindow::setGraphicsApi(QSGRendererInterface::Vulkan);
        qInfo("Using Vulkan for Qt Quick rendering; pass --opengl to override.");
    }
#else
    if (parser.isSet("vulkan"))
        qWarning("Vulkan is unavailable in WebAssembly; Qt uses WebGL in the browser.");
    if (parser.isSet("opengl"))
        qInfo("The browser selects its WebGL backend for this WebAssembly build.");
#endif
    app.setApplicationName("mongles-da-noite");
    app.setApplicationVersion("0.1.0-22");
    app.setDesktopFileName("mongles-da-noite");
    app.setWindowIcon(QIcon::fromTheme("mongles-da-noite"));
    QQuickStyle::setStyle("Material");
    qmlRegisterType<ArenaInstancing>("Mongles", 1, 0, "ArenaInstancing");

    Theme theme;
    Translator translator;
    Backend backend;
    Gamepad gamepad;
    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, &app,
                     [](const QList<QQmlError> &warnings) {
        for (const QQmlError &warning : warnings) {
            const QByteArray message = warning.toString().toLocal8Bit();
            std::fprintf(stderr, "QML: %s\n", message.constData());
        }
        std::fflush(stderr);
    });
    app.installTranslator(&translator);
    QObject::connect(&translator, &Translator::changed, &engine, &QQmlEngine::retranslate);
    engine.rootContext()->setContextProperty("translator", &translator);
    engine.rootContext()->setContextProperty("theme", &theme);
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.rootContext()->setContextProperty("gamepad", &gamepad);
    engine.rootContext()->setContextProperty("buildVersion", app.applicationVersion());
    engine.load(QUrl("qrc:/Main.qml"));
    if (engine.rootObjects().isEmpty()) {
        std::fprintf(stderr, "A interface principal não carregou. Veja os erros QML acima.\n");
        return 1;
    }
    return app.exec();
}
