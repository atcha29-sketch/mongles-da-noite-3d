#include "arena_instancing.h"

#include <QVariantMap>
#include <QVector3D>
#include <QtMath>

namespace {
QColor actorColor(const QString &category, const QVariantMap &entity, int stage)
{
    static const QColor enemyColors[5][3] = {
        {QColor("#72857b"), QColor("#76616c"), QColor("#829252")},
        {QColor("#bb9b61"), QColor("#668e58"), QColor("#be6a4e")},
        {QColor("#9873bc"), QColor("#65517f"), QColor("#8170a0")},
        {QColor("#e86ca7"), QColor("#48b9c3"), QColor("#7665d4")},
        {QColor("#ad686b"), QColor("#c7b49a"), QColor("#62515b")}
    };
    static const QColor summonColors[6] = {
        QColor("#dba4d2"), QColor("#ef8f73"), QColor("#e6c46f"),
        QColor("#83c7bd"), QColor("#a9a0e8"), QColor("#e7e2d4")
    };
    const int safeStage = qBound(0, stage - 1, 4);
    const int kind = qBound(0, entity.value("kind").toInt(), 2);

    if (category == "enemy")
        return enemyColors[safeStage][kind];
    if (category == "enemyEye")
        return safeStage == 3 ? QColor(kind == 1 ? "#57e7e0" : "#ff80c8")
                              : QColor("#ffdc79");
    if (category == "summon") {
        if (entity.value("kind").toString() == "skeleton")
            return QColor("#dce6d5");
        return summonColors[qBound(0, entity.value("color").toInt(), 5)];
    }
    if (category == "summonEye")
        return entity.value("kind").toString() == "skeleton"
            ? QColor("#54394c") : QColor("#fff0d4");
    if (category == "summonDetail")
        return entity.value("kind").toString() == "skeleton"
            ? QColor("#dce6d5") : QColor("#e9d8c8");
    if (category == "gem")
        return QColor("#53d3b6");
    if (category == "projectile") {
        switch (entity.value("element").toInt()) {
        case 1: return QColor("#ff824f");
        case 2: return QColor("#74dcff");
        case 3: return QColor("#ffe370");
        case 4: return QColor("#c596ff");
        default: return QColor("#ffe7a0");
        }
    }
    if (category == "drop") {
        const QString type = entity.value("type").toString();
        if (type == "speed") return QColor("#70e8bb");
        if (type == "fireRate") return QColor("#81ceff");
        return QColor("#f15e72");
    }
    if (category == "particle")
        return QColor(entity.value("color").toString());
    if (category == "enemyShadow" || category == "bossShadow")
        return QColor("#17141a");
    if (category == "boss") {
        static const QColor colors[5] = {QColor("#da6578"), QColor("#b18455"),
            QColor("#ac67dc"), QColor("#f06faf"), QColor("#d77b68")};
        return colors[qBound(0, entity.value("kind").toInt(), 4)];
    }
    if (category == "bossEye") {
        static const QColor colors[5] = {QColor("#ffcb79"), QColor("#f5be62"),
            QColor("#bbf2ff"), QColor("#fff09a"), QColor("#ff6d68")};
        return colors[qBound(0, entity.value("kind").toInt(), 4)];
    }
    if (category == "echo")
        return QColor("#c596ff");
    return QColor("#d9e0eb");
}
}

ArenaInstancing::ArenaInstancing(QQuick3DObject *parent)
    : QQuick3DInstancing(parent)
{
}

void ArenaInstancing::setEntities(const QVariantList &entities)
{
    m_entities = entities;
    markDirty();
    emit entitiesChanged();
}

void ArenaInstancing::setCategory(const QString &category)
{
    if (m_category == category)
        return;
    m_category = category;
    setHasTransparency(category == "particle" || category == "enemyShadow"
                       || category == "bossShadow");
    markDirty();
}

void ArenaInstancing::setStage(int stage)
{
    if (m_stage == stage)
        return;
    m_stage = stage;
    markDirty();
}

void ArenaInstancing::setKindFilter(int kindFilter)
{
    if (m_kindFilter == kindFilter)
        return;
    m_kindFilter = kindFilter;
    markDirty();
}

void ArenaInstancing::setObjectScale(const QVector3D &scale)
{
    if (m_objectScale == scale)
        return;
    m_objectScale = scale;
    markDirty();
}

void ArenaInstancing::setOffset(const QVector3D &offset)
{
    if (m_offset == offset)
        return;
    m_offset = offset;
    markDirty();
}

void ArenaInstancing::setHeight(qreal height)
{
    if (qFuzzyCompare(m_height, height))
        return;
    m_height = height;
    markDirty();
}

void ArenaInstancing::setKindNameFilter(const QString &filter)
{
    if (m_kindNameFilter == filter)
        return;
    m_kindNameFilter = filter;
    markDirty();
}

QByteArray ArenaInstancing::getInstanceBuffer(int *instanceCount)
{
    QByteArray buffer;
    buffer.reserve(m_entities.size() * int(sizeof(InstanceTableEntry)));
    *instanceCount = 0;

    for (const QVariant &value : m_entities) {
        const QVariantMap entity = value.toMap();
        if (m_kindFilter >= 0 && entity.value("kind").toInt() != m_kindFilter)
            continue;
        if (!m_kindNameFilter.isEmpty()
            && entity.value("kind").toString() != m_kindNameFilter)
            continue;
        const qreal x = entity.value("x").toDouble();
        const qreal y = entity.value("y").toDouble();
        QVector3D scale = m_objectScale;
        qreal instanceHeight = m_height;
        if (m_category == "particle") {
            const float size = qBound(0.025f, entity.value("size").toFloat() * 0.012f, 0.12f);
            scale = QVector3D(size, size, size);
        } else if (m_category == "boss" && entity.value("kind").toInt() == 4) {
            scale *= 2.15f;
            instanceHeight *= 2.15;
        }

        const QVector3D position(float((x - 500.0) / 10.0) + m_offset.x(),
                                 float(instanceHeight) + m_offset.y(),
                                 float((y - 350.0) / 10.0) + m_offset.z());
        QColor color = actorColor(m_category, entity, m_stage);
        if (m_category == "particle") {
            const qreal maxLife = qMax<qreal>(0.001, entity.value("maxLife").toDouble());
            color.setAlphaF(qBound<qreal>(0, entity.value("life").toDouble() / maxLife, 1));
        }
        const InstanceTableEntry entry = calculateTableEntry(
            position, scale, QVector3D(), color);
        buffer.append(reinterpret_cast<const char *>(&entry), sizeof(entry));
        ++*instanceCount;
    }
    return buffer;
}
