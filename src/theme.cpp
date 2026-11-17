#include "theme.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QStandardPaths>

Theme::Theme(QObject *parent) : QObject(parent)
{
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(80);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] { m_debounce.start(); });
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this] { m_debounce.start(); });
    connect(&m_debounce, &QTimer::timeout, this, &Theme::reload);
#ifndef Q_OS_WASM
    if (!qEnvironmentVariableIsEmpty("HYPRLAND_INSTANCE_SIGNATURE"))
        m_hyprctl = QStandardPaths::findExecutable("hyprctl");
    m_roundingTimeout.setSingleShot(true);
    m_roundingTimeout.setInterval(500);
    connect(&m_roundingTimeout, &QTimer::timeout, &m_roundingProcess, &QProcess::kill);
    connect(&m_roundingProcess, &QProcess::finished, this, [this](int code, QProcess::ExitStatus status) {
        m_roundingTimeout.stop();
        const auto value = QJsonDocument::fromJson(m_roundingProcess.readAllStandardOutput())
                               .object().value("int");
        if (code == 0 && status == QProcess::NormalExit && value.isDouble() && value.toInt(-1) >= 0
            && value.toInt() != m_radius) {
            m_radius = value.toInt();
            emit changed();
        }
    });
    connect(&m_roundingProcess, &QProcess::errorOccurred, this, [this] { m_roundingTimeout.stop(); });
    m_roundingPoll.setInterval(1000);
    connect(&m_roundingPoll, &QTimer::timeout, this, &Theme::refreshRounding);
    if (!m_hyprctl.isEmpty())
        m_roundingPoll.start();
#endif
    reload();
}

Theme::~Theme()
{
#ifndef Q_OS_WASM
    if (m_roundingProcess.state() != QProcess::NotRunning) {
        m_roundingProcess.kill();
        m_roundingProcess.waitForFinished(1000);
    }
#endif
}

void Theme::refreshRounding()
{
#ifndef Q_OS_WASM
    if (m_hyprctl.isEmpty() || m_roundingProcess.state() != QProcess::NotRunning)
        return;
    m_roundingProcess.start(m_hyprctl, {"-j", "getoption", "decoration:rounding"});
    m_roundingTimeout.start();
#endif
}

void Theme::reload()
{
    refreshRounding();
    const auto paths = m_watcher.files() + m_watcher.directories();
    if (!paths.isEmpty())
        m_watcher.removePaths(paths);

    const QString themeDirectory = QDir::homePath() + "/.local/state/omarchy/current/theme";
    QString ancestor = themeDirectory;
    while (!QFileInfo::exists(ancestor) && ancestor != "/")
        ancestor = QFileInfo(ancestor).absolutePath();
    for (const QString &path : {ancestor, QFileInfo(ancestor).absolutePath(), themeDirectory,
                                themeDirectory + "/colors.toml"})
        if (QFileInfo::exists(path))
            m_watcher.addPath(path);

    QFile file(themeDirectory + "/colors.toml");
    if (file.open(QIODevice::ReadOnly)) {
        const auto match = QRegularExpression(
            R"re(^\s*accent\s*=\s*["'](#[0-9a-fA-F]{6})["'])re",
            QRegularExpression::MultilineOption).match(QString::fromUtf8(file.readAll()));
        if (match.hasMatch() && match.captured(1) != m_accent) {
            m_accent = match.captured(1);
            emit changed();
        }
    }
}
