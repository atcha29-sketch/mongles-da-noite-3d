#pragma once

#include <QElapsedTimer>
#include <QHash>
#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVariantMap>
#include <QVariantList>

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString state READ state NOTIFY changed)
    Q_PROPERTY(QVariantList enemies READ enemies NOTIFY changed)
    Q_PROPERTY(QVariantList projectiles READ projectiles NOTIFY changed)
    Q_PROPERTY(QVariantList summons READ summons NOTIFY changed)
    Q_PROPERTY(QVariantList gems READ gems NOTIFY changed)
    Q_PROPERTY(QVariantList drops READ drops NOTIFY changed)
    Q_PROPERTY(QVariantList particles READ particles NOTIFY changed)
    Q_PROPERTY(QVariantList attackEffects READ attackEffects NOTIFY changed)
    Q_PROPERTY(QVariantList upgradeOptions READ upgradeOptions NOTIFY changed)
    Q_PROPERTY(QVariantMap upgradeLevels READ upgradeLevels NOTIFY changed)
    Q_PROPERTY(QVariantMap classUpgradeLevels READ classUpgradeLevels NOTIFY changed)
    Q_PROPERTY(QString activeElement READ activeElement NOTIFY changed)
    Q_PROPERTY(QString heroClass READ heroClass NOTIFY changed)
    Q_PROPERTY(qreal playerX READ playerX NOTIFY changed)
    Q_PROPERTY(qreal playerY READ playerY NOTIFY changed)
    Q_PROPERTY(int health READ health NOTIFY changed)
    Q_PROPERTY(int maxHealth READ maxHealth NOTIFY changed)
    Q_PROPERTY(int level READ level NOTIFY changed)
    Q_PROPERTY(int experience READ experience NOTIFY changed)
    Q_PROPERTY(int experienceNeeded READ experienceNeeded NOTIFY changed)
    Q_PROPERTY(int kills READ kills NOTIFY changed)
    Q_PROPERTY(int seconds READ seconds NOTIFY changed)
    Q_PROPERTY(int stage READ stage NOTIFY changed)
    Q_PROPERTY(int cycle READ cycle NOTIFY changed)
    Q_PROPERTY(int stageTimeLeft READ stageTimeLeft NOTIFY changed)
    Q_PROPERTY(bool subBossSpawned READ subBossSpawned NOTIFY changed)
    Q_PROPERTY(QVariantMap boss READ boss NOTIFY changed)
    Q_PROPERTY(QVariantMap subBoss READ subBoss NOTIFY changed)
    Q_PROPERTY(QVariantList enemyBeams READ enemyBeams NOTIFY changed)
    Q_PROPERTY(int speedBoostTime READ speedBoostTime NOTIFY changed)
    Q_PROPERTY(int fireRateBoostTime READ fireRateBoostTime NOTIFY changed)
    Q_PROPERTY(int hordeAlertTime READ hordeAlertTime NOTIFY changed)
    Q_PROPERTY(int magnetTime READ magnetTime NOTIFY changed)

public:
    explicit Backend(QObject *parent = nullptr);

    QString state() const { return m_state; }
    QVariantList enemies() const;
    QVariantList projectiles() const;
    QVariantList summons() const;
    QVariantList gems() const;
    QVariantList drops() const;
    QVariantList particles() const;
    QVariantList attackEffects() const;
    QVariantList upgradeOptions() const;
    QVariantMap upgradeLevels() const;
    QVariantMap classUpgradeLevels() const;
    QString activeElement() const { return m_activeElement; }
    QString heroClass() const { return m_heroClass; }
    qreal playerX() const { return m_playerX; }
    qreal playerY() const { return m_playerY; }
    int health() const { return m_health; }
    int maxHealth() const { return m_maxHealth; }
    int level() const { return m_level; }
    int experience() const { return m_experience; }
    int experienceNeeded() const { return m_experienceNeeded; }
    int kills() const { return m_kills; }
    int seconds() const { return static_cast<int>(m_elapsed); }
    int stage() const { return m_stage + 1; }
    int cycle() const { return m_completedCycles + 1; }
    int stageTimeLeft() const;
    bool subBossSpawned() const { return m_subBossSpawned; }
    QVariantMap boss() const;
    QVariantMap subBoss() const;
    QVariantList enemyBeams() const;
    int speedBoostTime() const;
    int fireRateBoostTime() const;
    int hordeAlertTime() const;
    int magnetTime() const;

    Q_INVOKABLE void startGame();
    Q_INVOKABLE void pauseGame();
    Q_INVOKABLE void resumeGame();
    Q_INVOKABLE void togglePause();
    Q_INVOKABLE void setMovement(qreal x, qreal y);
    Q_INVOKABLE void movePlayer(qreal x, qreal y);
    Q_INVOKABLE void chooseUpgrade(const QString &id);
    Q_INVOKABLE void chooseClass(const QString &id);
    Q_INVOKABLE void returnToMenu();

signals:
    void changed();
    void audioCue(const QString &name);

private slots:
    void updateGame();

private:
    friend class MonglesTests;

    struct Creature {
        quint64 id = 0;
        qreal x = 0;
        qreal y = 0;
        qreal health = 1;
        qreal speed = 0;
        qreal burnTime = 0;
        qreal burnTick = 0;
        qreal slowTime = 0;
        int kind = 0;
    };
    struct Projectile {
        qreal x = 0;
        qreal y = 0;
        qreal vx = 0;
        qreal vy = 0;
        qreal damage = 1;
        int pierce = 0;
        int element = 0;
        int heroClass = 0;
        qreal radius = 11;
        QList<quint64> hitIds;
        bool hitBoss = false;
        bool hitSubBoss = false;
        QList<quint64> hitEchoIds;
    };
    struct EnemyBeam {
        qreal x1 = 0, y1 = 0, x2 = 0, y2 = 0;
        qreal delay = 0, life = 0, maxLife = 0, damage = 0;
        int kind = 0;
    };
    struct BossEcho {
        quint64 id = 0;
        qreal x = 0, y = 0, health = 0, life = 0, attackCooldown = 0;
    };
    struct Summon {
        qreal x = 0;
        qreal y = 0;
        qreal attackCooldown = 0;
        int color = 0;
        qreal health = 60;
        qreal maxHealth = 60;
    };
    struct Gem { qreal x = 0; qreal y = 0; };
    struct Pickup { qreal x = 0; qreal y = 0; QString type; };
    struct Particle {
        qreal x = 0;
        qreal y = 0;
        qreal vx = 0;
        qreal vy = 0;
        qreal life = 0;
        qreal maxLife = 0;
        qreal size = 0;
        QString color;
        int kind = 0;
    };
    struct AttackEffect {
        qreal x = 0;
        qreal y = 0;
        qreal range = 0;
        qreal angle = 0;
        qreal life = 0;
        qreal maxLife = 0;
        int kind = 0;
        int element = 0;
    };

    void spawnCreature();
    void updateSummons(qreal dt);
    void fireAtNearest();
    void swingWarrior();
    void collectExperience(qreal dt);
    void collectDrops(qreal dt);
    void gainExperience();
    void dropCreature(int index);
    void spawnBurst(qreal x, qreal y, const QString &color, int count, int kind = 0);
    void offerUpgrade();
    QStringList classUpgradeOptions() const;
    void damagePlayer(qreal damage);
    void damageSummons(qreal x, qreal y, qreal radius, qreal damage);
    void spawnBoss();
    void spawnSubBoss();
    void defeatSubBoss();
    void fireBossBeamAt(qreal x1, qreal y1, qreal x2, qreal y2,
                        qreal damage, qreal delay = 0.48, qreal life = 0.22);
    void fireBossPattern(qreal x, qreal y, qreal damage, bool majorBoss);
    void defeatBoss();
    void advanceStage();
    void resetGame();
    int summonCount() const;

    QTimer m_timer;
    QElapsedTimer m_clock;
    QString m_state = "menu";
    QList<Creature> m_enemies;
    QList<Projectile> m_projectiles;
    QList<Summon> m_summons;
    QList<Gem> m_gems;
    QList<Pickup> m_drops;
    QList<Particle> m_particles;
    QList<AttackEffect> m_attackEffects;
    QList<EnemyBeam> m_enemyBeams;
    QList<BossEcho> m_bossEchoes;
    QStringList m_upgradeOptions;
    QHash<QString, int> m_classUpgradeLevels;
    QString m_activeElement = "arcane";
    QString m_heroClass = "warrior";
    qreal m_playerX = 500;
    qreal m_playerY = 350;
    qreal m_moveX = 0;
    qreal m_moveY = 0;
    qreal m_health = 140;
    qreal m_elapsed = 0;
    qreal m_spawnCountdown = 0;
    qreal m_fireCountdown = 0;
    qreal m_damageCooldown = 0;
    qreal m_hitSoundCooldown = 0;
    qreal m_pickupSoundCooldown = 0;
    qreal m_summonSoundCooldown = 0;
    qreal m_speedBoostTime = 0;
    qreal m_fireRateBoostTime = 0;
    qreal m_hordeTime = 0;
    qreal m_hordeAlertTime = 0;
    qreal m_magnetTime = 0;
    qreal m_victoryCountdown = 0;
    qreal m_stageCountdown = 40;
    qreal m_subBossCountdown = 20;
    qreal m_bossX = 0;
    qreal m_bossY = 0;
    qreal m_bossHealth = 0;
    qreal m_bossMaxHealth = 0;
    qreal m_bossAttackCooldown = 0;
    qreal m_bossShockCooldown = 0;
    qreal m_bossBurnTime = 0;
    qreal m_bossBurnTick = 0;
    qreal m_bossSlowTime = 0;
    qreal m_bossBeamCooldown = 2.0;
    qreal m_subBossX = 0;
    qreal m_subBossY = 0;
    qreal m_subBossHealth = 0;
    qreal m_subBossMaxHealth = 0;
    qreal m_subBossAttackCooldown = 0;
    qreal m_subBossBeamCooldown = 1.4;
    qreal m_bossEchoCooldown = 0;
    int m_bossEchoPhase = 0;
    int m_bossAttackPattern = 0;
    bool m_bossActive = false;
    bool m_subBossActive = false;
    bool m_subBossSpawned = false;
    bool m_projectileClearPending = false;
    int m_maxHealth = 140;
    int m_level = 1;
    int m_experience = 0;
    int m_experienceNeeded = 5;
    int m_kills = 0;
    int m_fireLevel = 0;
    int m_iceLevel = 0;
    int m_lightningLevel = 0;
    int m_shadowLevel = 0;
    int m_stage = 0;
    int m_completedCycles = 0;
    quint64 m_nextCreatureId = 0;
    quint64 m_nextEchoId = 0;
};
