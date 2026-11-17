#include "translator.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QRegularExpression>

Translator::Translator(QObject *parent) : QTranslator(parent)
{
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(80);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] { m_debounce.start(); });
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this] { m_debounce.start(); });
    connect(&m_debounce, &QTimer::timeout, this, &Translator::reload);
    reload();
}

QString Translator::translate(const char *, const char *sourceText, const char *, int) const
{
    return m_strings.value(QString::fromUtf8(sourceText));
}

void Translator::reload()
{
    const auto paths = m_watcher.files() + m_watcher.directories();
    if (!paths.isEmpty())
        m_watcher.removePaths(paths);

    const QString languageFile = QDir::homePath() + "/.config/omarchy/language";
    const QString directory = QFileInfo(languageFile).absolutePath();
    if (QFileInfo::exists(directory))
        m_watcher.addPath(directory);
    if (QFileInfo::exists(languageFile))
        m_watcher.addPath(languageFile);

    // O jogo sai em português brasileiro por padrão e mantém essa localização
    // mesmo quando o ambiente gráfico está configurado em outro idioma.
    QString language = "pt-BR";
    QFile selected(languageFile);
    if (selected.open(QIODevice::ReadOnly)) {
        const QString candidate = QString::fromUtf8(selected.readLine()).trimmed();
        if (QRegularExpression("^pt(-[A-Za-z]{2})?$", QRegularExpression::CaseInsensitiveOption)
                .match(candidate).hasMatch())
            language = "pt-BR";
    }

    if (language == m_language)
        return;

    QHash<QString, QString> strings;
    QStringList candidates{"en", language.section('-', 0, 0), language};
    candidates.removeDuplicates();
    for (const QString &code : candidates) {
        QFile catalog(":/i18n/" + code + ".json");
        if (!catalog.open(QIODevice::ReadOnly))
            continue;
        const auto object = QJsonDocument::fromJson(catalog.readAll()).object();
        for (auto it = object.begin(); it != object.end(); ++it)
            if (it.value().isString())
                strings.insert(it.key(), it.value().toString());
    }

    m_language = language;
    m_strings = strings;
    const QLocale locale(language);
    QLocale::setDefault(locale);
    QGuiApplication::setLayoutDirection(locale.textDirection());
    emit changed();
}
