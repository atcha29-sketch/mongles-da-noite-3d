#pragma once

#include <QColor>
#include <QQuick3DInstancing>
#include <QVariantList>

class ArenaInstancing : public QQuick3DInstancing
{
    Q_OBJECT
    Q_PROPERTY(QVariantList entities READ entities WRITE setEntities NOTIFY entitiesChanged)
    Q_PROPERTY(QString category READ category WRITE setCategory)
    Q_PROPERTY(int stage READ stage WRITE setStage)
    Q_PROPERTY(int kindFilter READ kindFilter WRITE setKindFilter)
    Q_PROPERTY(QVector3D objectScale READ objectScale WRITE setObjectScale)
    Q_PROPERTY(QVector3D offset READ offset WRITE setOffset)
    Q_PROPERTY(qreal height READ height WRITE setHeight)
    Q_PROPERTY(QString kindNameFilter READ kindNameFilter WRITE setKindNameFilter)

public:
    explicit ArenaInstancing(QQuick3DObject *parent = nullptr);

    QVariantList entities() const { return m_entities; }
    void setEntities(const QVariantList &entities);
    QString category() const { return m_category; }
    void setCategory(const QString &category);
    int stage() const { return m_stage; }
    void setStage(int stage);
    int kindFilter() const { return m_kindFilter; }
    void setKindFilter(int kindFilter);
    QVector3D objectScale() const { return m_objectScale; }
    void setObjectScale(const QVector3D &scale);
    QVector3D offset() const { return m_offset; }
    void setOffset(const QVector3D &offset);
    qreal height() const { return m_height; }
    void setHeight(qreal height);
    QString kindNameFilter() const { return m_kindNameFilter; }
    void setKindNameFilter(const QString &filter);

signals:
    void entitiesChanged();

protected:
    QByteArray getInstanceBuffer(int *instanceCount) override;

private:
    QVariantList m_entities;
    QString m_category;
    int m_stage = 1;
    int m_kindFilter = -1;
    QVector3D m_objectScale{0.03f, 0.03f, 0.03f};
    QVector3D m_offset;
    qreal m_height = 0.5;
    QString m_kindNameFilter;
};
