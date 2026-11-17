#include "backend.h"

#include <QRandomGenerator>
#include <QSet>
#include <QtMath>
#include <algorithm>
#include <limits>

namespace {
constexpr qreal ArenaWidth = 1000;
constexpr qreal ArenaHeight = 700;
constexpr qreal PlayerRadius = 18;
constexpr qreal MagnetDuration = 3.0;
constexpr int MaxEnemies = 60;
constexpr int MaxProjectiles = 80;
constexpr int MaxGems = 120;
constexpr int MaxDrops = 12;
constexpr int MaxParticles = 72;

qreal distanceSquared(qreal x1, qreal y1, qreal x2, qreal y2)
{
    const qreal dx = x2 - x1;
    const qreal dy = y2 - y1;
    return dx * dx + dy * dy;
}

qreal distance(qreal x1, qreal y1, qreal x2, qreal y2)
{
    return qSqrt(distanceSquared(x1, y1, x2, y2));
}

qreal distanceToSegment(qreal px, qreal py, qreal x1, qreal y1, qreal x2, qreal y2)
{
    const qreal dx = x2 - x1;
    const qreal dy = y2 - y1;
    const qreal lengthSquared = dx * dx + dy * dy;
    const qreal t = lengthSquared > 0
        ? qBound<qreal>(0, ((px - x1) * dx + (py - y1) * dy) / lengthSquared, 1) : 0;
    return distance(px, py, x1 + t * dx, y1 + t * dy);
}

int heroHealth(const QString &heroClass)
{
    if (heroClass == "warrior") return 140;
    if (heroClass == "mage") return 92;
    if (heroClass == "archer") return 105;
    if (heroClass == "bronhaman") return 100;
    return 100;
}

qreal heroSpeed(const QString &heroClass)
{
    if (heroClass == "warrior") return 260;
    if (heroClass == "mage" || heroClass == "lango") return 280;
    if (heroClass == "kalengue") return 295;
    if (heroClass == "bronhaman") return 300;
    return 310;
}
}

Backend::Backend(QObject *parent) : QObject(parent)
{
    m_timer.setInterval(33);
    connect(&m_timer, &QTimer::timeout, this, &Backend::updateGame);
}

QVariantList Backend::enemies() const
{
    QVariantList result;
    result.reserve(m_enemies.size());
    for (const auto &creature : m_enemies)
        result.append(QVariantMap{{"x", creature.x}, {"y", creature.y}, {"kind", creature.kind},
                                  {"burning", creature.burnTime > 0}, {"slowed", creature.slowTime > 0}});
    return result;
}

QVariantList Backend::projectiles() const
{
    QVariantList result;
    result.reserve(m_projectiles.size());
    for (const auto &projectile : m_projectiles)
        result.append(QVariantMap{{"x", projectile.x}, {"y", projectile.y},
                                  {"element", projectile.element},
                                  {"heroClass", projectile.heroClass},
                                  {"vx", projectile.vx}, {"vy", projectile.vy},
                                  {"radius", projectile.radius}});
    return result;
}

QVariantList Backend::summons() const
{
    QVariantList result;
    result.reserve(m_summons.size());
    for (const auto &summon : m_summons) {
        result.append(QVariantMap{{"x", summon.x}, {"y", summon.y},
                                  {"color", summon.color},
                                  {"health", summon.health}, {"maxHealth", summon.maxHealth},
                                  {"kind", m_heroClass == "lango" ? "skeleton" : "cat"}});
    }
    return result;
}

QVariantList Backend::gems() const
{
    QVariantList result;
    result.reserve(m_gems.size());
    for (const auto &gem : m_gems)
        result.append(QVariantMap{{"x", gem.x}, {"y", gem.y}});
    return result;
}

QVariantList Backend::drops() const
{
    QVariantList result;
    result.reserve(m_drops.size());
    for (const auto &pickup : m_drops)
        result.append(QVariantMap{{"x", pickup.x}, {"y", pickup.y}, {"type", pickup.type}});
    return result;
}

QVariantList Backend::particles() const
{
    QVariantList result;
    result.reserve(m_particles.size());
    for (const auto &particle : m_particles) {
        result.append(QVariantMap{{"x", particle.x}, {"y", particle.y},
                                  {"life", particle.life}, {"maxLife", particle.maxLife},
                                  {"size", particle.size}, {"color", particle.color},
                                  {"kind", particle.kind}});
    }
    return result;
}

QVariantList Backend::attackEffects() const
{
    QVariantList result;
    result.reserve(m_attackEffects.size());
    for (const auto &effect : m_attackEffects)
        result.append(QVariantMap{{"x", effect.x}, {"y", effect.y}, {"range", effect.range},
                                  {"angle", effect.angle}, {"life", effect.life},
                                  {"maxLife", effect.maxLife}, {"kind", effect.kind},
                                  {"element", effect.element}});
    return result;
}

QVariantList Backend::upgradeOptions() const
{
    QVariantList result;
    for (const QString &option : m_upgradeOptions)
        result.append(option);
    return result;
}

QVariantMap Backend::upgradeLevels() const
{
    return {{"fire", m_fireLevel}, {"ice", m_iceLevel},
            {"lightning", m_lightningLevel}, {"shadow", m_shadowLevel}};
}

QVariantMap Backend::classUpgradeLevels() const
{
    QVariantMap result;
    for (auto it = m_classUpgradeLevels.cbegin(); it != m_classUpgradeLevels.cend(); ++it)
        result.insert(it.key(), it.value());
    return result;
}

QStringList Backend::classUpgradeOptions() const
{
    if (m_heroClass == "warrior") {
        QStringList result;
        if (m_classUpgradeLevels.value("heavyBlade") < 5)
            result.append("heavyBlade");
        if (m_classUpgradeLevels.value("wideArc") < 4)
            result.append("wideArc");
        if (m_classUpgradeLevels.value("ironSkin") < 4)
            result.append("ironSkin");
        return result;
    }
    if (m_heroClass == "mage") {
        QStringList result;
        if (m_classUpgradeLevels.value("arcaneFocus") < 5)
            result.append("arcaneFocus");
        if (m_classUpgradeLevels.value("blastRadius") < 5)
            result.append("blastRadius");
        if (m_classUpgradeLevels.value("manaFlow") < 5)
            result.append("manaFlow");
        return result;
    }
    if (m_heroClass == "archer") {
        QStringList result;
        if (m_classUpgradeLevels.value("piercing") < 4)
            result.append("piercing");
        if (m_classUpgradeLevels.value("longbow") < 4)
            result.append("longbow");
        if (m_classUpgradeLevels.value("multishot") < 2)
            result.append("multishot");
        return result;
    }
    if (m_heroClass == "bronhaman") {
        QStringList result;
        if (m_classUpgradeLevels.value("goldenCaliber") < 5)
            result.append("goldenCaliber");
        if (m_classUpgradeLevels.value("quickDraw") < 5)
            result.append("quickDraw");
        if (m_classUpgradeLevels.value("fanTheHammer") < 2)
            result.append("fanTheHammer");
        return result;
    }
    if (m_heroClass == "lango") {
        QStringList result;
        if (m_classUpgradeLevels.value("boneClaws") < 5)
            result.append("boneClaws");
        if (m_classUpgradeLevels.value("skeletonPact") < 3)
            result.append("skeletonPact");
        if (m_classUpgradeLevels.value("skeletonLegion") < 2)
            result.append("skeletonLegion");
        if (m_classUpgradeLevels.value("graveMarch") < 5)
            result.append("graveMarch");
        return result;
    }
    QStringList result;
    if (m_classUpgradeLevels.value("sharpClaws") < 5)
        result.append("sharpClaws");
    if (m_classUpgradeLevels.value("catCoven") < 3)
        result.append("catCoven");
    if (m_classUpgradeLevels.value("catParade") < 2)
        result.append("catParade");
    if (m_classUpgradeLevels.value("felineGrace") < 5)
        result.append("felineGrace");
    return result;
}

int Backend::summonCount() const
{
    if (m_heroClass == "lango")
        return 3 + qMin(3, m_classUpgradeLevels.value("skeletonPact"))
            + qMin(2, m_classUpgradeLevels.value("skeletonLegion"));
    if (m_heroClass == "kalengue")
        return 3 + qMin(3, m_classUpgradeLevels.value("catCoven"))
            + qMin(2, m_classUpgradeLevels.value("catParade"));
    return 0;
}

int Backend::stageTimeLeft() const
{
    if (m_bossActive || m_subBossActive)
        return 0;
    return qMax(0, qCeil(m_subBossSpawned ? m_stageCountdown : m_subBossCountdown));
}

QVariantMap Backend::boss() const
{
    QVariantList echoes;
    for (const auto &echo : m_bossEchoes)
        echoes.append(QVariantMap{{"id", QVariant::fromValue<qulonglong>(echo.id)},
                                  {"x", echo.x}, {"y", echo.y}, {"health", echo.health},
                                  {"life", echo.life}});
    return {{"active", m_bossActive}, {"x", m_bossX}, {"y", m_bossY},
            {"health", m_bossHealth}, {"maxHealth", m_bossMaxHealth},
            {"kind", m_stage}, {"radius", m_stage == 4 ? 112 : 42}, {"echoes", echoes}};
}

QVariantMap Backend::subBoss() const
{
    return {{"active", m_subBossActive}, {"x", m_subBossX}, {"y", m_subBossY},
            {"health", m_subBossHealth}, {"maxHealth", m_subBossMaxHealth},
            {"kind", m_stage}};
}

QVariantList Backend::enemyBeams() const
{
    QVariantList result;
    result.reserve(m_enemyBeams.size());
    for (const auto &beam : m_enemyBeams)
        result.append(QVariantMap{{"x1", beam.x1}, {"y1", beam.y1},
                                  {"x2", beam.x2}, {"y2", beam.y2},
                                  {"delay", beam.delay}, {"life", beam.life},
                                  {"maxLife", beam.maxLife}, {"kind", beam.kind}});
    return result;
}

int Backend::speedBoostTime() const
{
    return qMax(0, qCeil(m_speedBoostTime));
}

int Backend::fireRateBoostTime() const
{
    return qMax(0, qCeil(m_fireRateBoostTime));
}

int Backend::hordeAlertTime() const
{
    return qMax(0, qCeil(m_hordeAlertTime));
}

int Backend::magnetTime() const
{
    return qMax(0, qCeil(m_magnetTime));
}

void Backend::resetGame()
{
    m_enemies.clear();
    m_projectiles.clear();
    m_summons.clear();
    m_gems.clear();
    m_drops.clear();
    m_particles.clear();
    m_attackEffects.clear();
    m_enemyBeams.clear();
    m_bossEchoes.clear();
    m_upgradeOptions.clear();
    m_classUpgradeLevels.clear();
    m_playerX = ArenaWidth / 2;
    m_playerY = ArenaHeight / 2;
    m_moveX = 0;
    m_moveY = 0;
    m_maxHealth = heroHealth(m_heroClass);
    m_health = m_maxHealth;
    m_elapsed = 0;
    m_spawnCountdown = 0.5;
    m_fireCountdown = 0;
    m_damageCooldown = 0;
    m_hitSoundCooldown = 0;
    m_pickupSoundCooldown = 0;
    m_summonSoundCooldown = 0;
    m_speedBoostTime = 0;
    m_fireRateBoostTime = 0;
    m_hordeTime = 0;
    m_hordeAlertTime = 0;
    m_magnetTime = 0;
    m_victoryCountdown = 0;
    m_stageCountdown = 40;
    m_subBossCountdown = 20;
    m_subBossSpawned = false;
    m_bossX = m_bossY = 0;
    m_bossHealth = m_bossMaxHealth = 0;
    m_bossAttackCooldown = m_bossShockCooldown = 0;
    m_bossBurnTime = m_bossBurnTick = m_bossSlowTime = 0;
    m_bossBeamCooldown = 2.0;
    m_subBossX = m_subBossY = m_subBossHealth = m_subBossMaxHealth = 0;
    m_subBossAttackCooldown = 0;
    m_subBossBeamCooldown = 1.4;
    m_bossEchoCooldown = 0;
    m_bossEchoPhase = 0;
    m_bossAttackPattern = 0;
    m_bossActive = false;
    m_subBossActive = false;
    m_projectileClearPending = false;
    m_level = 1;
    m_experience = 0;
    m_experienceNeeded = 5;
    m_kills = 0;
    m_fireLevel = 0;
    m_iceLevel = 0;
    m_lightningLevel = 0;
    m_shadowLevel = 0;
    m_nextCreatureId = 0;
    m_nextEchoId = 0;
    m_stage = 0;
    m_completedCycles = 0;
    m_activeElement = "arcane";
    for (int i = 0; i < summonCount(); ++i) {
        const qreal angle = 2 * M_PI * i / qMax(1, summonCount());
        m_summons.append({m_playerX + qCos(angle) * 58,
                          m_playerY + qSin(angle) * 58, 0, i % 6});
    }
}

void Backend::startGame()
{
    resetGame();
    m_state = "playing";
    m_clock.start();
    m_timer.start();
    emit changed();
}

void Backend::chooseClass(const QString &id)
{
    if (m_state != "menu" || (id != "warrior" && id != "mage" && id != "archer"
                              && id != "lango" && id != "kalengue" && id != "bronhaman"))
        return;
    if (m_heroClass == id)
        return;
    m_heroClass = id;
    m_maxHealth = heroHealth(id);
    m_health = m_maxHealth;
    emit changed();
}

void Backend::returnToMenu()
{
    if (m_state != "gameover" && m_state != "victory")
        return;
    m_summons.clear();
    m_state = "menu";
    emit changed();
}

void Backend::pauseGame()
{
    if (m_state == "playing") {
        m_state = "paused";
        m_timer.stop();
        emit changed();
    }
}

void Backend::resumeGame()
{
    if (m_state == "paused") {
        m_state = "playing";
        m_clock.restart();
        m_timer.start();
        emit changed();
    }
}

void Backend::togglePause()
{
    if (m_state == "playing")
        pauseGame();
    else if (m_state == "paused")
        resumeGame();
}

void Backend::setMovement(qreal x, qreal y)
{
    m_moveX = qBound<qreal>(-1, x, 1);
    m_moveY = qBound<qreal>(-1, y, 1);
}

void Backend::movePlayer(qreal x, qreal y)
{
    if (m_state != "playing")
        return;
    const qreal length = qSqrt(x * x + y * y);
    if (length > 1) {
        x /= length;
        y /= length;
    }
    const qreal speed = heroSpeed(m_heroClass) * (m_speedBoostTime > 0 ? 1.35 : 1);
    m_playerX = qBound(PlayerRadius, m_playerX + x * speed / 60, ArenaWidth - PlayerRadius);
    m_playerY = qBound(PlayerRadius, m_playerY + y * speed / 60, ArenaHeight - PlayerRadius);
}

void Backend::chooseUpgrade(const QString &id)
{
    if (m_state != "upgrade" || !m_upgradeOptions.contains(id))
        return;

    const bool elemental = id == "fire" || id == "ice" || id == "lightning" || id == "shadow";
    if (id == "fire")
        ++m_fireLevel;
    else if (id == "ice")
        ++m_iceLevel;
    else if (id == "lightning")
        ++m_lightningLevel;
    else if (id == "shadow")
        ++m_shadowLevel;
    else {
        if (!classUpgradeOptions().contains(id))
            return;
        m_classUpgradeLevels[id] = m_classUpgradeLevels.value(id) + 1;
    }

    if (elemental)
        m_activeElement = id;
    m_upgradeOptions.clear();
    const QString color = id == "fire" ? "#ff824f"
        : id == "ice" ? "#74dcff"
        : id == "lightning" ? "#ffe370"
        : id == "shadow" ? "#c596ff"
        : m_heroClass == "warrior" ? "#f2bc68"
        : m_heroClass == "mage" ? "#ad85ff"
        : m_heroClass == "bronhaman" ? "#f0ca61" : "#70dc9f";
    spawnBurst(m_playerX, m_playerY, color, 24, 1);
    emit audioCue(elemental ? "upgrade-" + id : "classUpgrade");
    m_state = "playing";
    m_clock.restart();
    m_timer.start();
    if (m_experience >= m_experienceNeeded)
        gainExperience();
    emit changed();
}

void Backend::spawnCreature()
{
    if (m_enemies.size() >= MaxEnemies)
        return;
    const int side = QRandomGenerator::global()->bounded(4);
    Creature creature;
    creature.id = ++m_nextCreatureId;
    creature.kind = QRandomGenerator::global()->bounded(3);
    const qreal cycleScale = 1 + m_completedCycles * 0.16;
    creature.speed = (48 + QRandomGenerator::global()->bounded(24)
                      + qMin<qreal>(m_elapsed * 0.3, 45)) * (1 + m_stage * 0.08) * cycleScale;
    creature.health = (creature.kind == 2 ? 3 + m_stage : 1 + m_stage * 0.35)
        * (1 + m_completedCycles * 0.35);
    switch (side) {
    case 0: creature.x = QRandomGenerator::global()->bounded(1000); creature.y = -24; break;
    case 1: creature.x = ArenaWidth + 24; creature.y = QRandomGenerator::global()->bounded(700); break;
    case 2: creature.x = QRandomGenerator::global()->bounded(1000); creature.y = ArenaHeight + 24; break;
    default: creature.x = -24; creature.y = QRandomGenerator::global()->bounded(700); break;
    }
    m_enemies.append(creature);
}

void Backend::spawnBurst(qreal x, qreal y, const QString &color, int count, int kind)
{
    while (m_particles.size() + count > MaxParticles)
        m_particles.removeFirst();
    for (int i = 0; i < count; ++i) {
        const qreal angle = QRandomGenerator::global()->generateDouble() * M_PI * 2;
        const qreal speed = 24 + QRandomGenerator::global()->bounded(170);
        const qreal life = 0.24 + QRandomGenerator::global()->generateDouble() * 0.55;
        m_particles.append({x, y, qCos(angle) * speed, qSin(angle) * speed,
                            life, life, qreal(2 + QRandomGenerator::global()->bounded(4)),
                            color, kind});
    }
}

void Backend::dropCreature(int index)
{
    const auto creature = m_enemies[index];
    if (m_gems.size() < MaxGems)
        m_gems.append({creature.x, creature.y});
    if (m_drops.size() < MaxDrops && QRandomGenerator::global()->bounded(100) < 16) {
        const int itemRoll = QRandomGenerator::global()->bounded(100);
        const QString type = itemRoll < 46 ? "speed" : itemRoll < 90 ? "fireRate" : "horde";
        const QString color = type == "speed" ? "#70e8bb"
            : type == "fireRate" ? "#81ceff" : "#f15e72";
        m_drops.append({creature.x, creature.y, type});
        spawnBurst(creature.x, creature.y, color, 12, 1);
    }
    spawnBurst(creature.x, creature.y,
               creature.kind == 0 ? "#bb83f3" : creature.kind == 1 ? "#b9f4e3" : "#ff965e", 12);
    m_enemies.removeAt(index);
    ++m_kills;
}

void Backend::collectDrops(qreal dt)
{
    if (m_state != "playing")
        return;

    for (int i = m_drops.size() - 1; i >= 0; --i) {
        auto &pickup = m_drops[i];
        const qreal d = distance(m_playerX, m_playerY, pickup.x, pickup.y);
        if ((d < 100 || m_magnetTime > 0) && d > 28) {
            const qreal speed = m_magnetTime > 0 ? 1100 : 260;
            const qreal travel = qMin(speed * dt, d - 27);
            pickup.x += (m_playerX - pickup.x) / d * travel;
            pickup.y += (m_playerY - pickup.y) / d * travel;
        }
        if (d >= 28)
            continue;

        const Pickup collected = pickup;
        m_drops.removeAt(i);
        if (collected.type == "speed") {
            m_speedBoostTime = 12;
            spawnBurst(collected.x, collected.y, "#70e8bb", 22, 1);
            emit audioCue("powerup");
        } else if (collected.type == "fireRate") {
            m_fireRateBoostTime = 12;
            spawnBurst(collected.x, collected.y, "#81ceff", 22, 1);
            emit audioCue("powerup");
        } else {
            m_hordeTime = 8;
            m_hordeAlertTime = 3;
            m_spawnCountdown = qMin<qreal>(m_spawnCountdown, 0.12);
            for (int enemy = 0; enemy < 16 && m_enemies.size() < MaxEnemies; ++enemy) {
                spawnCreature();
                m_enemies.last().speed *= 1.2;
                m_enemies.last().health += 1;
            }
            spawnBurst(collected.x, collected.y, "#f15e72", 36, 1);
            emit audioCue("horde");
        }
    }
}

void Backend::fireAtNearest()
{
    if (m_projectiles.size() >= MaxProjectiles)
        return;
    if (m_heroClass == "lango" || m_heroClass == "kalengue")
        return;

    qreal targetX = 0;
    qreal targetY = 0;
    qreal nearestDistance = std::numeric_limits<qreal>::max();
    for (const auto &enemy : m_enemies) {
        const qreal d = distance(m_playerX, m_playerY, enemy.x, enemy.y);
        if (d < nearestDistance) {
            nearestDistance = d;
            targetX = enemy.x;
            targetY = enemy.y;
        }
    }
    if (m_bossActive) {
        const qreal d = distance(m_playerX, m_playerY, m_bossX, m_bossY);
        if (d < nearestDistance) {
            nearestDistance = d;
            targetX = m_bossX;
            targetY = m_bossY;
        }
    }
    if (m_subBossActive) {
        const qreal d = distance(m_playerX, m_playerY, m_subBossX, m_subBossY);
        if (d < nearestDistance) {
            nearestDistance = d;
            targetX = m_subBossX;
            targetY = m_subBossY;
        }
    }
    for (const auto &echo : m_bossEchoes) {
        const qreal d = distance(m_playerX, m_playerY, echo.x, echo.y);
        if (d < nearestDistance) {
            nearestDistance = d;
            targetX = echo.x;
            targetY = echo.y;
        }
    }
    if (nearestDistance == std::numeric_limits<qreal>::max())
        return;
    if (m_heroClass == "warrior" && nearestDistance > 230)
        return;
    if (m_heroClass == "warrior") {
        swingWarrior();
        emit audioCue("attack-warrior");
        return;
    }

    const qreal dx = targetX - m_playerX;
    const qreal dy = targetY - m_playerY;
    const qreal length = qMax<qreal>(1, qSqrt(dx * dx + dy * dy));
    const int element = m_activeElement == "fire" ? 1 : m_activeElement == "ice" ? 2
        : m_activeElement == "lightning" ? 3 : m_activeElement == "shadow" ? 4 : 0;
    const int heroClass = m_heroClass == "mage" ? 1 : m_heroClass == "bronhaman" ? 3 : 2;
    const int longbowLevel = m_classUpgradeLevels.value("longbow");
    const qreal speed = heroClass == 2 ? 760 + longbowLevel * 80
        : heroClass == 3 ? 860 : element == 4 ? 520 : 390;
    const qreal damage = (heroClass == 1 ? 1.45 : heroClass == 3 ? 1.0 : 1.3)
        + (m_level - 1) / 6.0
        + (heroClass == 1 ? m_classUpgradeLevels.value("arcaneFocus") * 0.25
           : heroClass == 3 ? m_classUpgradeLevels.value("goldenCaliber") * 0.22
           : longbowLevel * 0.22)
        + (element == 1 ? m_fireLevel * 0.35 : 0)
        + (element == 3 ? m_lightningLevel * 0.18 : 0);
    const int basePierce = heroClass == 2 ? 1 + m_classUpgradeLevels.value("piercing") : 0;
    const qreal radius = heroClass == 1 ? 15 : heroClass == 3 ? 8 : 10;
    const int volley = heroClass == 2
        ? qMin(5, 3 + m_classUpgradeLevels.value("multishot"))
        : heroClass == 3 ? qMin(6, 2 + 2 * m_classUpgradeLevels.value("fanTheHammer")) : 1;
    for (int arrow = 0; arrow < volley; ++arrow) {
        const qreal spread = volley == 1 ? 0
            : (arrow - (volley - 1) / 2.0) * (heroClass == 3 ? 0.075 : 0.1);
        const qreal directionX = dx / length * qCos(spread) - dy / length * qSin(spread);
        const qreal directionY = dx / length * qSin(spread) + dy / length * qCos(spread);
        qreal startX = m_playerX;
        qreal startY = m_playerY;
        if (heroClass == 3) {
            const qreal side = arrow % 2 == 0 ? -1 : 1;
            startX += -dy / length * side * 11;
            startY += dx / length * side * 11;
        }
        const qreal damageScale = heroClass == 2 ? (volley == 1 ? 1 : 0.33)
            : heroClass == 3 ? (volley == 2 ? 0.85 : volley == 4 ? 0.55 : 0.40) : 1;
        m_projectiles.append({startX, startY, directionX * speed, directionY * speed,
                              damage * damageScale,
                              basePierce + (element == 4 ? qMin(5, m_shadowLevel) : 0),
                              element, heroClass, radius, {}, false, false, {}});
        if (heroClass == 2)
            m_attackEffects.append({m_playerX, m_playerY, 160.0 + longbowLevel * 30.0,
                                    qAtan2(directionY, directionX), 0.16, 0.16, 2});
        else if (heroClass == 3)
            m_attackEffects.append({startX, startY, 16, qAtan2(directionY, directionX),
                                    0.12, 0.12, 5, element});
    }
    emit audioCue(heroClass == 1 ? "attack-mage"
                                 : heroClass == 3 ? "attack-bronha" : "attack-archer");
}

void Backend::updateSummons(qreal dt)
{
    const int desiredCount = summonCount();
    while (m_summons.size() < desiredCount) {
        const int index = m_summons.size();
        const qreal angle = 2 * M_PI * index / qMax(1, desiredCount);
        m_summons.append({m_playerX + qCos(angle) * 58,
                          m_playerY + qSin(angle) * 58, 0, index % 6});
    }
    while (m_summons.size() > desiredCount)
        m_summons.removeLast();

    QSet<quint64> assignedTargets;
    for (int i = 0; i < m_summons.size(); ++i) {
        auto &summon = m_summons[i];
        if (summon.health <= 0) {
            const QString color = m_heroClass == "lango" ? "#d9e7d0" : "#f6b2cf";
            spawnBurst(summon.x, summon.y, color, 12, 1);
            const qreal respawnAngle = 2 * M_PI * i / qMax(1, desiredCount);
            summon.x = qBound<qreal>(24, m_playerX + qCos(respawnAngle) * 58,
                                     ArenaWidth - 24);
            summon.y = qBound<qreal>(24, m_playerY + qSin(respawnAngle) * 58,
                                     ArenaHeight - 24);
            summon.health = summon.maxHealth;
            summon.attackCooldown = 0.8;
            emit audioCue("hit");
        }
        summon.attackCooldown = qMax<qreal>(0, summon.attackCooldown - dt);

        int targetIndex = -1;
        qreal targetDistance = std::numeric_limits<qreal>::max();
        bool hasUnassignedTarget = false;
        if (!m_bossActive && !m_subBossActive) {
            for (int j = 0; j < m_enemies.size(); ++j) {
                if (assignedTargets.contains(m_enemies[j].id))
                    continue;
                const qreal d = distance(summon.x, summon.y, m_enemies[j].x, m_enemies[j].y);
                if (d < targetDistance) {
                    targetDistance = d;
                    targetIndex = j;
                    hasUnassignedTarget = true;
                }
            }
            if (!hasUnassignedTarget) {
                for (int j = 0; j < m_enemies.size(); ++j) {
                    const qreal d = distance(summon.x, summon.y, m_enemies[j].x, m_enemies[j].y);
                    if (d < targetDistance) {
                        targetDistance = d;
                        targetIndex = j;
                    }
                }
            }
        }
        if (targetIndex >= 0)
            assignedTargets.insert(m_enemies[targetIndex].id);
        const bool targetBoss = m_bossActive;
        const bool targetSubBoss = !targetBoss && m_subBossActive;

        const qreal angle = 2 * M_PI * i / qMax(1, desiredCount) + m_elapsed * 0.16;
        const qreal approachRadius = targetBoss ? 148 : targetSubBoss ? 52 : 40;
        qreal targetX = m_playerX + qCos(angle) * 68;
        qreal targetY = m_playerY + qSin(angle) * 68;
        if (targetIndex >= 0) {
            targetX = m_enemies[targetIndex].x + qCos(angle) * approachRadius;
            targetY = m_enemies[targetIndex].y + qSin(angle) * approachRadius;
        } else if (targetBoss) {
            targetX = m_bossX + qCos(angle) * approachRadius;
            targetY = m_bossY + qSin(angle) * approachRadius;
        } else if (targetSubBoss) {
            targetX = m_subBossX + qCos(angle) * approachRadius;
            targetY = m_subBossY + qSin(angle) * approachRadius;
        }
        targetX = qBound<qreal>(24, targetX, ArenaWidth - 24);
        targetY = qBound<qreal>(24, targetY, ArenaHeight - 24);

        const qreal dx = targetX - summon.x;
        const qreal dy = targetY - summon.y;
        const qreal d = qMax<qreal>(1, qSqrt(dx * dx + dy * dy));
        const bool hasTarget = targetIndex >= 0 || targetBoss || targetSubBoss;
        const qreal reach = targetBoss ? 150 : targetSubBoss ? 58 : 46;
        const qreal speed = m_heroClass == "lango" ? 230 : 250;
        if (d > 7) {
            const qreal travel = qMin(speed * dt, qMax<qreal>(0, d - 7));
            summon.x += dx / d * travel;
            summon.y += dy / d * travel;
        }

        const bool skeleton = m_heroClass == "lango";
        const int summonElement = m_activeElement == "fire" ? 1 : m_activeElement == "ice" ? 2
            : m_activeElement == "lightning" ? 3 : m_activeElement == "shadow" ? 4 : 0;
        const int elementalLevel = summonElement == 1 ? m_fireLevel
            : summonElement == 2 ? m_iceLevel
            : summonElement == 3 ? m_lightningLevel
            : summonElement == 4 ? m_shadowLevel : 0;
        const qreal damage = (skeleton ? 1.18 : 1.12) + (m_level - 1) / 18.0
            + m_classUpgradeLevels.value(skeleton ? "boneClaws" : "sharpClaws") * 0.25
            + elementalLevel * 0.12 + (summonElement == 4 ? elementalLevel * 0.12 : 0);
        const QString elementColor = summonElement == 1 ? "#ff824f"
            : summonElement == 2 ? "#74dcff"
            : summonElement == 3 ? "#ffe370"
            : summonElement == 4 ? "#c596ff"
            : skeleton ? "#d9e7d0" : "#f6b2cf";
        const int hasteLevel = m_classUpgradeLevels.value(skeleton ? "graveMarch" : "felineGrace");
        const qreal attackRateBoost = m_fireRateBoostTime > 0 ? 0.65 : 1;
        const qreal targetHitDistance = targetBoss
            ? distance(summon.x, summon.y, m_bossX, m_bossY)
            : targetSubBoss ? distance(summon.x, summon.y, m_subBossX, m_subBossY)
            : targetIndex >= 0 ? distance(summon.x, summon.y,
                                         m_enemies[targetIndex].x, m_enemies[targetIndex].y)
            : std::numeric_limits<qreal>::max();
        if (hasTarget && targetHitDistance <= reach && summon.attackCooldown <= 0) {
            summon.attackCooldown = (skeleton ? 0.8 : 0.78)
                * qPow(0.95, hasteLevel) * attackRateBoost;
            const int effectKind = skeleton ? 3 : 4;
            const qreal targetXForEffect = targetBoss ? m_bossX
                : targetSubBoss ? m_subBossX : m_enemies[targetIndex].x;
            const qreal targetYForEffect = targetBoss ? m_bossY
                : targetSubBoss ? m_subBossY : m_enemies[targetIndex].y;
            m_attackEffects.append({summon.x, summon.y, skeleton ? 28.0 : 34.0,
                                    qAtan2(targetYForEffect - summon.y,
                                           targetXForEffect - summon.x),
                                    0.22, 0.22, effectKind, summonElement});
            if (targetBoss || targetSubBoss) {
                if (targetBoss)
                    m_bossHealth -= damage;
                else
                    m_subBossHealth -= damage;
                const qreal hitX = targetBoss ? m_bossX : m_subBossX;
                const qreal hitY = targetBoss ? m_bossY : m_subBossY;
                spawnBurst(hitX, hitY, elementColor, summonElement ? 10 : 5, 1);
                if (targetSubBoss) {
                    if (m_subBossHealth <= 0)
                        defeatSubBoss();
                    continue;
                }
                if (summonElement == 1) {
                    m_bossBurnTime = qMax<qreal>(m_bossBurnTime, 2.2 + m_fireLevel * 0.35);
                    m_bossBurnTick = qMin<qreal>(m_bossBurnTick, 0.35);
                } else if (summonElement == 2) {
                    m_bossSlowTime = qMax<qreal>(m_bossSlowTime, 1.4 + m_iceLevel * 0.2);
                } else if (summonElement == 3) {
                    int chained = 0;
                    for (int j = m_enemies.size() - 1; j >= 0
                         && chained < 1 + m_lightningLevel / 2; --j) {
                        if (distance(m_bossX, m_bossY, m_enemies[j].x, m_enemies[j].y) > 145)
                            continue;
                        m_enemies[j].health -= damage * 0.45;
                        spawnBurst(m_enemies[j].x, m_enemies[j].y, elementColor, 6, 1);
                        ++chained;
                        if (m_enemies[j].health <= 0)
                            dropCreature(j);
                    }
                }
                if (m_bossHealth <= 0)
                    defeatBoss();
            } else if (targetIndex >= 0 && targetIndex < m_enemies.size()) {
                m_enemies[targetIndex].health -= damage;
                if (summonElement == 1) {
                    m_enemies[targetIndex].burnTime = qMax<qreal>(
                        m_enemies[targetIndex].burnTime, 2.2 + m_fireLevel * 0.35);
                    m_enemies[targetIndex].burnTick = qMin<qreal>(
                        m_enemies[targetIndex].burnTick, 0.35);
                } else if (summonElement == 2) {
                    m_enemies[targetIndex].slowTime = qMax<qreal>(
                        m_enemies[targetIndex].slowTime, 1.4 + m_iceLevel * 0.2);
                }
                const qreal chainX = m_enemies[targetIndex].x;
                const qreal chainY = m_enemies[targetIndex].y;
                spawnBurst(chainX, chainY, elementColor, summonElement ? 8 : 4, 1);
                QList<int> defeated;
                if (summonElement == 3) {
                    int chained = 0;
                    for (int j = m_enemies.size() - 1; j >= 0
                         && chained < 1 + m_lightningLevel / 2; --j) {
                        if (j == targetIndex
                            || distance(chainX, chainY, m_enemies[j].x, m_enemies[j].y) > 115)
                            continue;
                        m_enemies[j].health -= damage * 0.45;
                        spawnBurst(m_enemies[j].x, m_enemies[j].y, elementColor, 6, 1);
                        ++chained;
                        if (m_enemies[j].health <= 0)
                            defeated.append(j);
                    }
                }
                if (m_enemies[targetIndex].health <= 0)
                    defeated.append(targetIndex);
                std::sort(defeated.begin(), defeated.end(), std::greater<int>());
                for (int defeatedIndex : defeated)
                    dropCreature(defeatedIndex);
            }
            if (m_summonSoundCooldown <= 0) {
                emit audioCue(skeleton ? "attack-lango" : "attack-kalengue");
                m_summonSoundCooldown = 0.32;
            }
        }

        qreal separationX = 0;
        qreal separationY = 0;
        for (int other = 0; other < m_summons.size(); ++other) {
            if (other == i)
                continue;
            qreal awayX = summon.x - m_summons[other].x;
            qreal awayY = summon.y - m_summons[other].y;
            qreal separation = qSqrt(awayX * awayX + awayY * awayY);
            if (separation >= 52)
                continue;
            if (separation < 0.1) {
                awayX = i < other ? -1 : 1;
                awayY = i % 2 == 0 ? -1 : 1;
                separation = qSqrt(2.0);
            }
            const qreal push = (52 - separation) / separation;
            separationX += awayX * push;
            separationY += awayY * push;
        }
        const qreal separationStrength = qMin<qreal>(1, dt * 8);
        summon.x = qBound<qreal>(24, summon.x + separationX * separationStrength,
                                 ArenaWidth - 24);
        summon.y = qBound<qreal>(24, summon.y + separationY * separationStrength,
                                 ArenaHeight - 24);
    }
}

void Backend::damageSummons(qreal x, qreal y, qreal radius, qreal damage)
{
    for (auto &summon : m_summons) {
        if (distance(x, y, summon.x, summon.y) <= radius)
            summon.health -= damage;
    }
}

void Backend::swingWarrior()
{
    const qreal range = 125 + m_classUpgradeLevels.value("wideArc") * 18;
    const qreal damage = 2.15 + (m_level - 1) / 5.0
        + m_classUpgradeLevels.value("heavyBlade") * 0.42;
    const int element = m_activeElement == "fire" ? 1 : m_activeElement == "ice" ? 2
        : m_activeElement == "lightning" ? 3 : m_activeElement == "shadow" ? 4 : 0;
    const qreal totalDamage = damage + (element == 1 ? m_fireLevel * 0.35 : 0);
    m_attackEffects.append({m_playerX, m_playerY, range, 0, 0.32, 0.32, 0});
    bool hit = false;

    for (int i = m_enemies.size() - 1; i >= 0; --i) {
        auto &enemy = m_enemies[i];
        if (distance(m_playerX, m_playerY, enemy.x, enemy.y) > range + 14)
            continue;
        enemy.health -= totalDamage;
        if (element == 1) {
            enemy.burnTime = 2.2 + m_fireLevel * 0.35;
            enemy.burnTick = qMin<qreal>(enemy.burnTick, 0.35);
        } else if (element == 2) {
            enemy.slowTime = 1.4 + m_iceLevel * 0.2;
        }
        spawnBurst(enemy.x, enemy.y, element == 1 ? "#ff824f"
                   : element == 2 ? "#74dcff" : "#f2bc68", 8, 1);
        hit = true;
        if (enemy.health <= 0)
            dropCreature(i);
    }

    const qreal bossRadius = m_stage == 4 ? 112 : 42;
    if (m_subBossActive && distance(m_playerX, m_playerY, m_subBossX, m_subBossY) <= range + 32) {
        m_subBossHealth -= totalDamage;
        spawnBurst(m_subBossX, m_subBossY, "#9ef8ff", 8, 1);
        hit = true;
        if (m_subBossHealth <= 0)
            defeatSubBoss();
    }
    for (int i = m_bossEchoes.size() - 1; i >= 0; --i) {
        if (distance(m_playerX, m_playerY, m_bossEchoes[i].x, m_bossEchoes[i].y) > range + 28)
            continue;
        m_bossEchoes[i].health -= totalDamage;
        spawnBurst(m_bossEchoes[i].x, m_bossEchoes[i].y, "#b5d8db", 6, 1);
        hit = true;
        if (m_bossEchoes[i].health <= 0)
            m_bossEchoes.removeAt(i);
    }
    if (m_bossActive && distance(m_playerX, m_playerY, m_bossX, m_bossY) <= range + bossRadius) {
        m_bossHealth -= totalDamage;
        if (element == 1) {
            m_bossBurnTime = 2.2 + m_fireLevel * 0.35;
            m_bossBurnTick = qMin<qreal>(m_bossBurnTick, 0.35);
        } else if (element == 2) {
            m_bossSlowTime = 1.4 + m_iceLevel * 0.2;
        }
        spawnBurst(m_bossX, m_bossY, "#f2bc68", 12, 1);
        hit = true;
        if (m_bossHealth <= 0)
            defeatBoss();
    }

    if (hit && m_hitSoundCooldown <= 0) {
        emit audioCue(element == 3 ? "lightning" : "hit");
        m_hitSoundCooldown = 0.12;
    }
}

void Backend::collectExperience(qreal dt)
{
    if (m_state != "playing")
        return;
    for (int i = m_gems.size() - 1; i >= 0; --i) {
        auto &gem = m_gems[i];
        const qreal d = distance(m_playerX, m_playerY, gem.x, gem.y);
        if ((d < 85 || m_magnetTime > 0) && d > 24) {
            const qreal speed = m_magnetTime > 0 ? 1100 : 220;
            const qreal travel = qMin(speed * dt, d - 24);
            gem.x += (m_playerX - gem.x) / d * travel;
            gem.y += (m_playerY - gem.y) / d * travel;
        }
        if (d < 25) {
            m_gems.removeAt(i);
            ++m_experience;
            spawnBurst(gem.x, gem.y, "#72f1cf", 7);
            if (m_pickupSoundCooldown <= 0) {
                emit audioCue("pickup");
                m_pickupSoundCooldown = 0.14;
            }
            if (m_experience >= m_experienceNeeded) {
                if (m_victoryCountdown > 0)
                    return;
                gainExperience();
                return;
            }
        }
    }
}

void Backend::gainExperience()
{
    m_experience -= m_experienceNeeded;
    ++m_level;
    m_experienceNeeded = qCeil(m_experienceNeeded * 1.3);
    if (m_level % 3 == 0)
        m_health = qMin<qreal>(m_maxHealth, m_health + 18);
    m_state = "upgrade";
    m_moveX = m_moveY = 0;
    m_timer.stop();
    m_upgradeOptions.clear();
    offerUpgrade();
    emit audioCue("levelup");
}

void Backend::offerUpgrade()
{
    QStringList choices{"fire", "ice", "lightning", "shadow"};
    const QStringList classChoices = classUpgradeOptions();
    if (!classChoices.isEmpty()) {
        const int index = QRandomGenerator::global()->bounded(classChoices.size());
        m_upgradeOptions.append(classChoices[index]);
    }
    while (m_upgradeOptions.size() < 3 && !choices.isEmpty()) {
        const int index = QRandomGenerator::global()->bounded(choices.size());
        m_upgradeOptions.append(choices.takeAt(index));
    }
}

void Backend::damagePlayer(qreal damage)
{
    if (m_damageCooldown > 0 || m_state != "playing")
        return;
    if (m_heroClass == "warrior")
        damage *= qMax<qreal>(0.4, 1 - m_classUpgradeLevels.value("ironSkin") * 0.15);
    m_health = qMax<qreal>(0, m_health - damage);
    m_damageCooldown = 0.7;
    emit audioCue("hurt");
    spawnBurst(m_playerX, m_playerY, "#ed637d", 9);
    if (m_health <= 0) {
        m_state = "gameover";
        m_timer.stop();
        m_moveX = m_moveY = 0;
        emit audioCue("gameover");
    }
}

void Backend::spawnBoss()
{
    if (m_bossActive || m_subBossActive)
        return;
    m_bossActive = true;
    m_bossX = m_stage == 4 ? ArenaWidth / 2
        : m_playerX < ArenaWidth / 2 ? ArenaWidth - 90 : 90;
    m_bossY = m_stage == 4 ? 220
        : m_playerY < ArenaHeight / 2 ? ArenaHeight - 100 : 100;
    m_bossMaxHealth = m_stage == 4 ? 1650 + m_completedCycles * 220
        : (30 + m_stage * 18) * (1 + m_completedCycles * 0.55);
    m_bossHealth = m_bossMaxHealth;
    m_bossAttackCooldown = 1.2;
    m_bossShockCooldown = 2.2;
    m_bossBeamCooldown = 1.4;
    m_bossEchoPhase = 0;
    m_bossEchoCooldown = 0;
    m_bossAttackPattern = 0;
    m_bossEchoes.clear();
    m_bossBurnTime = m_bossBurnTick = m_bossSlowTime = 0;
    spawnBurst(m_bossX, m_bossY, "#ed708e", 30, 1);
    emit audioCue("boss");
}

void Backend::spawnSubBoss()
{
    if (m_subBossActive || m_bossActive)
        return;
    m_subBossActive = true;
    m_subBossSpawned = true;
    const qreal radius = 32;
    m_subBossX = m_playerX < ArenaWidth / 2 ? ArenaWidth - radius : radius;
    m_subBossY = m_playerY < ArenaHeight / 2 ? ArenaHeight - radius : radius;
    m_subBossMaxHealth = (95 + m_stage * 28) * (1 + m_completedCycles * 0.35);
    m_subBossHealth = m_subBossMaxHealth;
    m_subBossAttackCooldown = 0.8;
    m_subBossBeamCooldown = 1.1;
    m_bossAttackPattern = 0;
    spawnBurst(m_subBossX, m_subBossY, "#7de8e1", 22, 1);
    emit audioCue("boss");
}

void Backend::defeatSubBoss()
{
    if (!m_subBossActive)
        return;
    m_subBossActive = false;
    m_subBossSpawned = true;
    ++m_kills;
    m_magnetTime = qMax<qreal>(m_magnetTime, 2.0);
    for (int i = 0; i < 5; ++i)
        m_gems.append({m_subBossX + (i - 2) * 13, m_subBossY + (i % 2 ? 12 : -12)});
    spawnBurst(m_subBossX, m_subBossY, "#7de8e1", 28, 1);
    emit audioCue("bossDefeated");
}

void Backend::fireBossBeamAt(qreal x1, qreal y1, qreal x2, qreal y2,
                             qreal damage, qreal delay, qreal life)
{
    if (m_enemyBeams.size() >= 12)
        m_enemyBeams.removeFirst();
    m_enemyBeams.append({x1, y1, x2, y2, delay, life, delay + life, damage, m_stage});
    const QString color = m_stage == 0 ? "#ff805b" : m_stage == 1 ? "#efc86b"
        : m_stage == 2 ? "#bb86ff" : m_stage == 3 ? "#ef62b8" : "#b8f5ff";
    spawnBurst(x1, y1, color, 3, 1);
}

void Backend::fireBossPattern(qreal x, qreal y, qreal damage, bool majorBoss)
{
    const int pattern = m_bossAttackPattern++ % 2;
    const int count = majorBoss ? 3 : 2;
    const qreal dx = m_playerX - x;
    const qreal dy = m_playerY - y;
    const qreal length = qMax<qreal>(1, qSqrt(dx * dx + dy * dy));
    const qreal sideX = -dy / length;
    const qreal sideY = dx / length;

    if (m_stage == 0) {
        // The Alley Master sweeps a fan of hooked beams across the player's lane.
        const int beams = majorBoss && pattern == 0 ? 3 : 2;
        for (int i = 0; i < beams; ++i) {
            const qreal lane = (i - (beams - 1) / 2.0) * (pattern == 0 ? 76 : 46);
            fireBossBeamAt(x, y,
                           qBound<qreal>(12, m_playerX + sideX * lane, ArenaWidth - 12),
                           qBound<qreal>(12, m_playerY + sideY * lane, ArenaHeight - 12),
                           damage, 0.45, 0.22);
        }
        return;
    }

    if (m_stage == 1) {
        // The Scarecrow leads the player's movement with staggered seed shots.
        const qreal lead = pattern == 0 ? 135 : 70;
        const qreal aimX = qBound<qreal>(18, m_playerX + m_moveX * lead, ArenaWidth - 18);
        const qreal aimY = qBound<qreal>(18, m_playerY + m_moveY * lead, ArenaHeight - 18);
        for (int i = 0; i < count; ++i) {
            const qreal lane = (i - (count - 1) / 2.0) * (pattern == 0 ? 58 : 88);
            fireBossBeamAt(x, y,
                           qBound<qreal>(12, aimX + sideX * lane, ArenaWidth - 12),
                           qBound<qreal>(12, aimY + sideY * lane, ArenaHeight - 12),
                           damage, 0.32 + i * 0.18, 0.2);
        }
        return;
    }

    if (m_stage == 2) {
        // The Quarry Stone bursts into four cardinal or diagonal crystal rays.
        const qreal baseAngle = pattern == 0 ? 0 : M_PI / 4;
        const int rays = majorBoss ? 4 : 2;
        for (int i = 0; i < rays; ++i) {
            const qreal angle = baseAngle + 2 * M_PI * i / rays;
            const qreal vx = qCos(angle);
            const qreal vy = qSin(angle);
            const qreal toX = vx > 0 ? (ArenaWidth - x) / vx
                : vx < 0 ? -x / vx : std::numeric_limits<qreal>::max();
            const qreal toY = vy > 0 ? (ArenaHeight - y) / vy
                : vy < 0 ? -y / vy : std::numeric_limits<qreal>::max();
            const qreal reach = qMin(toX, toY);
            fireBossBeamAt(x, y, x + vx * reach, y + vy * reach,
                           damage, 0.62, 0.24);
        }
        return;
    }

    if (m_stage == 3) {
        // The DJ sweeps the dance floor with horizontal or vertical light lanes.
        const int lanes = majorBoss ? 3 : 2;
        for (int i = 0; i < lanes; ++i) {
            const qreal offset = (i - (lanes - 1) / 2.0) * 88;
            if (pattern == 0) {
                const qreal laneY = qBound<qreal>(12, m_playerY + offset, ArenaHeight - 12);
                fireBossBeamAt(0, laneY, ArenaWidth, laneY, damage, 0.58, 0.2);
            } else {
                const qreal laneX = qBound<qreal>(12, m_playerX + offset, ArenaWidth - 12);
                fireBossBeamAt(laneX, 0, laneX, ArenaHeight, damage, 0.58, 0.2);
            }
        }
        return;
    }

    // The Carcass closes the rift with crossfire from the edges.
    const qreal aimX = qBound<qreal>(30, m_playerX + m_moveX * 95, ArenaWidth - 30);
    const qreal aimY = qBound<qreal>(30, m_playerY + m_moveY * 95, ArenaHeight - 30);
    const qreal sources[4][2] = {{0, 0}, {ArenaWidth, 0},
                                 {ArenaWidth, ArenaHeight}, {0, ArenaHeight}};
    const int rays = majorBoss ? 4 : 2;
    for (int i = 0; i < rays; ++i) {
        const int source = pattern == 0 ? i : (i * 2 + 1) % 4;
        const qreal lane = (i - (rays - 1) / 2.0) * 48;
        fireBossBeamAt(sources[source][0], sources[source][1],
                       qBound<qreal>(12, aimX + sideX * lane, ArenaWidth - 12),
                       qBound<qreal>(12, aimY + sideY * lane, ArenaHeight - 12),
                       damage, 0.64, 0.22);
    }
}

void Backend::defeatBoss()
{
    if (!m_bossActive)
        return;
    m_bossActive = false;
    ++m_kills;
    const qreal rewardX = m_bossX;
    const qreal rewardY = m_bossY;
    m_magnetTime = MagnetDuration;
    emit audioCue("bossDefeated");
    if (m_stage == 4) {
        m_subBossActive = false;
        m_bossEchoes.clear();
        spawnBurst(rewardX, rewardY, "#ffe077", 36, 1);
        m_victoryCountdown = MagnetDuration;
        m_moveX = m_moveY = 0;
        return;
    }
    advanceStage();
    spawnBurst(rewardX, rewardY, "#ffe077", 36, 1);
    if (m_stage < 4) {
        for (int i = 0; i < 4; ++i)
            m_gems.append({rewardX + (i % 2 ? 18 : -18), rewardY + (i < 2 ? -14 : 14)});
    }
}

void Backend::advanceStage()
{
    if (m_stage == 3) {
        ++m_completedCycles;
        m_stage = m_completedCycles >= 3 ? 4 : 0;
    } else {
        ++m_stage;
    }
    m_enemies.clear();
    m_projectileClearPending = true;
    m_attackEffects.clear();
    m_particles.clear();
    m_stageCountdown = 40;
    m_subBossCountdown = 20;
    m_subBossSpawned = false;
    m_subBossActive = false;
    m_bossActive = false;
    m_bossEchoes.clear();
    m_enemyBeams.clear();
    m_spawnCountdown = 0.5;
    m_fireCountdown = 0;
    m_health = qMin<qreal>(m_maxHealth, m_health + 24);
    emit audioCue("stage");
}

void Backend::updateGame()
{
    const qreal dt = qBound<qreal>(0.001, m_clock.restart() / 1000.0, 0.05);
    m_elapsed += dt;
    const qreal playerSpeed = heroSpeed(m_heroClass) * (m_speedBoostTime > 0 ? 1.35 : 1);
    m_playerX = qBound(PlayerRadius, m_playerX + m_moveX * playerSpeed * dt, ArenaWidth - PlayerRadius);
    m_playerY = qBound(PlayerRadius, m_playerY + m_moveY * playerSpeed * dt, ArenaHeight - PlayerRadius);
    m_spawnCountdown -= dt;
    m_fireCountdown -= dt;
    m_damageCooldown -= dt;
    m_hitSoundCooldown -= dt;
    m_pickupSoundCooldown -= dt;
    m_summonSoundCooldown -= dt;
    m_speedBoostTime = qMax<qreal>(0, m_speedBoostTime - dt);
    m_fireRateBoostTime = qMax<qreal>(0, m_fireRateBoostTime - dt);
    m_hordeTime = qMax<qreal>(0, m_hordeTime - dt);
    m_hordeAlertTime = qMax<qreal>(0, m_hordeAlertTime - dt);
    m_magnetTime = qMax<qreal>(0, m_magnetTime - dt);

    if (!m_bossActive) {
        m_stageCountdown -= dt;
        if (!m_subBossActive && !m_subBossSpawned && m_subBossCountdown > 0)
            m_subBossCountdown -= dt;
        if (!m_subBossActive && !m_subBossSpawned
            && m_subBossCountdown <= 0 && m_stageCountdown > 0)
            spawnSubBoss();
        if (!m_subBossActive && m_stageCountdown <= 0)
            spawnBoss();
    }

    if (m_bossActive) {
        m_bossAttackCooldown -= dt;
        m_bossShockCooldown -= dt;
        m_bossBeamCooldown -= dt;
        m_bossBurnTime = qMax<qreal>(0, m_bossBurnTime - dt);
        m_bossSlowTime = qMax<qreal>(0, m_bossSlowTime - dt);
        m_bossBurnTick -= dt;
        if (m_bossBurnTime > 0 && m_bossBurnTick <= 0) {
            m_bossHealth -= qMax<qreal>(0.5, m_fireLevel * 0.55);
            m_bossBurnTick = 0.7;
            spawnBurst(m_bossX, m_bossY, "#ff854e", 5);
            if (m_bossHealth <= 0)
                defeatBoss();
        }
        if (m_bossActive) {
            const qreal dx = m_playerX - m_bossX;
            const qreal dy = m_playerY - m_bossY;
            const qreal d = qMax<qreal>(1, qSqrt(dx * dx + dy * dy));
            const qreal slow = m_bossSlowTime > 0 ? 0.55 : 1;
            const qreal speed = (m_stage == 4 ? 25 : 42 + m_stage * 5) * slow;
            m_bossX += dx / d * speed * dt;
            m_bossY += dy / d * speed * dt;
            const qreal bossRadius = m_stage == 4 ? 112 : 42;
            m_bossX = qBound(bossRadius, m_bossX, ArenaWidth - bossRadius);
            m_bossY = qBound(bossRadius, m_bossY, ArenaHeight - bossRadius);
            if (d < (m_stage == 4 ? 130 : 62) && m_bossAttackCooldown <= 0) {
                const qreal strikeDamage = m_stage == 4 ? 30 : 18 + m_stage * 2;
                damagePlayer(strikeDamage);
                damageSummons(m_bossX, m_bossY, m_stage == 4 ? 210 : 180,
                              m_stage == 4 ? 25 : strikeDamage * 0.55);
                m_bossAttackCooldown = 1.05;
            } else if (d < (m_stage == 4 ? 260 : 142) && m_bossShockCooldown <= 0) {
                damagePlayer(m_stage == 4 ? 20 : 10 + m_stage);
                damageSummons(m_playerX, m_playerY, m_stage == 4 ? 165 : 120,
                              m_stage == 4 ? 14 : 6 + m_stage);
                spawnBurst(m_playerX, m_playerY, "#f18bb3", 14, 1);
                m_bossShockCooldown = 2.7;
            }
            if (d < 520 && m_bossBeamCooldown <= 0) {
                fireBossPattern(m_bossX, m_bossY,
                                m_stage == 4 ? 23 : 12 + m_stage * 2, true);
                const qreal interval = m_stage == 0 ? 2.8 : m_stage == 1 ? 3.1
                    : m_stage == 2 ? 3.8 : m_stage == 3 ? 3.2 : 2.6;
                m_bossBeamCooldown = interval;
            }

            if (m_stage == 4 && m_bossEchoPhase < 2
                && m_bossHealth <= m_bossMaxHealth * (m_bossEchoPhase == 0 ? 0.70 : 0.35)
                && m_bossEchoCooldown <= 0) {
                ++m_bossEchoPhase;
                m_bossEchoCooldown = 1.0;
                m_bossEchoes.clear();
                const int count = m_bossEchoPhase == 1 ? 3 : 5;
                for (int i = 0; i < count; ++i) {
                    const qreal angle = 2 * M_PI * i / count;
                    const qreal radius = 185;
                    const qreal x = qBound<qreal>(38, m_playerX + qCos(angle) * radius, ArenaWidth - 38);
                    const qreal y = qBound<qreal>(38, m_playerY + qSin(angle) * radius, ArenaHeight - 38);
                    m_bossEchoes.append({++m_nextEchoId, x, y,
                                         m_bossEchoPhase == 1 ? 48.0 : 62.0, 9.5, 0.65});
                }
                spawnBurst(m_bossX, m_bossY, "#b5d8db", 34, 1);
            }
        }
    }

    if (m_subBossActive) {
        const qreal dx = m_playerX - m_subBossX;
        const qreal dy = m_playerY - m_subBossY;
        const qreal d = qMax<qreal>(1, qSqrt(dx * dx + dy * dy));
        m_subBossX += dx / d * 58 * dt;
        m_subBossY += dy / d * 58 * dt;
        m_subBossX = qBound<qreal>(32, m_subBossX, ArenaWidth - 32);
        m_subBossY = qBound<qreal>(32, m_subBossY, ArenaHeight - 32);
        m_subBossAttackCooldown -= dt;
        m_subBossBeamCooldown -= dt;
        if (d < 52 && m_subBossAttackCooldown <= 0) {
            damagePlayer(12 + m_stage * 2);
            damageSummons(m_subBossX, m_subBossY, 55, 10);
            m_subBossAttackCooldown = 1.1;
        }
        if (d < 500 && m_subBossBeamCooldown <= 0) {
            fireBossPattern(m_subBossX, m_subBossY, 9 + m_stage, false);
            m_subBossBeamCooldown = 4.1;
        }
    }

    for (int i = m_bossEchoes.size() - 1; i >= 0; --i) {
        auto &echo = m_bossEchoes[i];
        echo.life -= dt;
        echo.attackCooldown -= dt;
        const qreal angle = qAtan2(echo.y - m_playerY, echo.x - m_playerX);
        const qreal tx = m_playerX + qCos(angle) * 84;
        const qreal ty = m_playerY + qSin(angle) * 84;
        const qreal dx = tx - echo.x;
        const qreal dy = ty - echo.y;
        const qreal d = qMax<qreal>(1, qSqrt(dx * dx + dy * dy));
        echo.x += dx / d * 92 * dt;
        echo.y += dy / d * 92 * dt;
        if (distance(echo.x, echo.y, m_playerX, m_playerY) < 102
            && echo.attackCooldown <= 0) {
            damagePlayer(8);
            echo.attackCooldown = 1.15;
            spawnBurst(echo.x, echo.y, "#b5d8db", 5, 1);
        }
        if (echo.life <= 0)
            m_bossEchoes.removeAt(i);
    }

    for (int i = m_enemyBeams.size() - 1; i >= 0; --i) {
        auto &beam = m_enemyBeams[i];
        if (beam.delay > 0) {
            beam.delay = qMax<qreal>(0, beam.delay - dt);
            if (beam.delay == 0) {
                if (distanceToSegment(m_playerX, m_playerY,
                                     beam.x1, beam.y1, beam.x2, beam.y2) < 21) {
                    damagePlayer(beam.damage);
                    damageSummons(beam.x2, beam.y2, 42, beam.damage * 0.45);
                    spawnBurst(m_playerX, m_playerY, "#9ef8ff", 12, 1);
                }
                const QString color = beam.kind == 0 ? "#ff805b" : beam.kind == 1 ? "#efc86b"
                    : beam.kind == 2 ? "#bb86ff" : beam.kind == 3 ? "#ef62b8" : "#b8f5ff";
                spawnBurst(beam.x2, beam.y2, color, 5, 1);
            }
        } else {
            beam.life -= dt;
        }
        if (beam.delay <= 0 && beam.life <= 0)
            m_enemyBeams.removeAt(i);
    }

    if (m_stage < 5 && !m_bossActive && m_spawnCountdown <= 0) {
        spawnCreature();
        const qreal normalInterval = qMax<qreal>(
            0.28, 1.45 - m_elapsed * 0.006 - m_completedCycles * 0.16);
        m_spawnCountdown = m_hordeTime > 0 ? qMin<qreal>(normalInterval, 0.34) : normalInterval;
    }
    if (m_fireCountdown <= 0) {
        fireAtNearest();
        const qreal classInterval = m_heroClass == "warrior" ? 0.82
            : m_heroClass == "mage" ? 0.67 * qPow(0.91, m_classUpgradeLevels.value("manaFlow"))
            : m_heroClass == "bronhaman" ? 0.78 * qPow(0.93, m_classUpgradeLevels.value("quickDraw"))
            : m_heroClass == "lango" ? 0.9
            : m_heroClass == "kalengue" ? 0.86
            : 0.58;
        const qreal levelInterval = classInterval - (m_level - 1) * 0.012;
        m_fireCountdown = qMax<qreal>(0.3, levelInterval * (m_fireRateBoostTime > 0 ? 0.7 : 1));
    }

    for (int i = m_enemies.size() - 1; i >= 0; --i) {
        auto &enemy = m_enemies[i];
        enemy.burnTime = qMax<qreal>(0, enemy.burnTime - dt);
        enemy.slowTime = qMax<qreal>(0, enemy.slowTime - dt);
        enemy.burnTick -= dt;
        if (enemy.burnTime > 0 && enemy.burnTick <= 0) {
            enemy.health -= qMax<qreal>(0.5, m_fireLevel * 0.42);
            enemy.burnTick = 0.7;
            spawnBurst(enemy.x, enemy.y, "#ff854e", 3);
            if (enemy.health <= 0) {
                dropCreature(i);
                continue;
            }
        }
        const qreal dx = m_playerX - enemy.x;
        const qreal dy = m_playerY - enemy.y;
        const qreal length = qMax<qreal>(1, qSqrt(dx * dx + dy * dy));
        const qreal slow = enemy.slowTime > 0 ? qMax<qreal>(0.25, 0.62 - m_iceLevel * 0.07) : 1;
        enemy.x += dx / length * enemy.speed * slow * dt;
        enemy.y += dy / length * enemy.speed * slow * dt;
        for (auto &summon : m_summons) {
            if (distance(enemy.x, enemy.y, summon.x, summon.y) < 22)
                summon.health -= 8 * dt;
        }
        if (length < PlayerRadius + 14)
            damagePlayer(m_heroClass == "warrior" ? 11
                         : m_heroClass == "mage" ? 18
                         : m_heroClass == "lango" ? 17
                         : m_heroClass == "kalengue" ? 16 : 17);
    }

    updateSummons(dt);
    if (m_projectileClearPending) {
        m_projectiles.clear();
        m_projectileClearPending = false;
    }

    for (int i = m_projectiles.size() - 1; i >= 0; --i) {
        auto &shot = m_projectiles[i];
        bool projectileSpent = false;
        shot.x += shot.vx * dt;
        shot.y += shot.vy * dt;
        if (shot.x < -20 || shot.x > ArenaWidth + 20 || shot.y < -20 || shot.y > ArenaHeight + 20) {
            m_projectiles.removeAt(i);
            continue;
        }
        for (int j = m_enemies.size() - 1; j >= 0; --j) {
            auto &enemy = m_enemies[j];
            if (shot.hitIds.contains(enemy.id))
                continue;
            const qreal hitRadius = shot.radius + 14;
            if (distanceSquared(shot.x, shot.y, enemy.x, enemy.y) < hitRadius * hitRadius) {
                shot.hitIds.append(enemy.id);
                const int element = shot.element;
                enemy.health -= shot.damage;
                if (element == 1) {
                    enemy.burnTime = 2.2 + m_fireLevel * 0.35;
                    enemy.burnTick = qMin<qreal>(enemy.burnTick, 0.35);
                } else if (element == 2) {
                    enemy.slowTime = 1.4 + m_iceLevel * 0.2;
                }
                const QString color = element == 1 ? "#ff824f" : element == 2 ? "#74dcff"
                    : element == 3 ? "#ffe370" : element == 4 ? "#c596ff" : "#ffe7a0";
                spawnBurst(shot.x, shot.y, color, element == 3 ? 10 : 6, 1);
                if (m_hitSoundCooldown <= 0) {
                    emit audioCue(element == 3 ? "lightning" : "hit");
                    m_hitSoundCooldown = 0.12;
                }

                QList<int> defeated;
                if (enemy.health <= 0)
                    defeated.append(j);
                if (shot.heroClass == 1) {
                    const qreal blastRadius = 66 + m_classUpgradeLevels.value("blastRadius") * 18;
                    const qreal splashDamage = shot.damage
                        * (0.5 + m_classUpgradeLevels.value("blastRadius") * 0.06);
                    m_attackEffects.append({shot.x, shot.y, blastRadius, 0, 0.34, 0.34, 1});
                    for (int k = m_enemies.size() - 1; k >= 0; --k) {
                        if (k == j || m_enemies[k].health <= 0
                            || distanceSquared(shot.x, shot.y, m_enemies[k].x, m_enemies[k].y)
                                > blastRadius * blastRadius)
                            continue;
                        auto &splashTarget = m_enemies[k];
                        splashTarget.health -= splashDamage;
                        spawnBurst(splashTarget.x, splashTarget.y, color, 5, 1);
                        if (splashTarget.health <= 0)
                            defeated.append(k);
                    }
                }
                if (element == 3) {
                    int chained = 0;
                    for (int k = m_enemies.size() - 1; k >= 0 && chained < 1 + m_lightningLevel / 2; --k) {
                        if (k == j || m_enemies[k].health <= 0
                            || distanceSquared(shot.x, shot.y, m_enemies[k].x, m_enemies[k].y)
                                > 145 * 145)
                            continue;
                        auto &chainTarget = m_enemies[k];
                        chainTarget.health -= shot.damage * 0.55;
                        spawnBurst(chainTarget.x, chainTarget.y, "#ffe370", 7, 1);
                        ++chained;
                        if (chainTarget.health <= 0)
                            defeated.append(k);
                    }
                }

                std::sort(defeated.begin(), defeated.end(), std::greater<int>());
                for (int defeatedIndex : defeated)
                    dropCreature(defeatedIndex);

                if (defeated.contains(j)) {
                    m_projectiles.removeAt(i);
                    projectileSpent = true;
                } else if (shot.pierce > 0) {
                    --shot.pierce;
                    continue;
                } else {
                    m_projectiles.removeAt(i);
                    projectileSpent = true;
                }
                break;
            }
        }
        if (!projectileSpent && m_subBossActive && !shot.hitSubBoss
            && distanceSquared(shot.x, shot.y, m_subBossX, m_subBossY)
                < (shot.radius + 32) * (shot.radius + 32)) {
            shot.hitSubBoss = true;
            m_subBossHealth -= shot.damage;
            spawnBurst(m_subBossX, m_subBossY, "#9ef8ff", 9, 1);
            if (m_subBossHealth <= 0)
                defeatSubBoss();
            if (shot.pierce > 0)
                --shot.pierce;
            else {
                m_projectiles.removeAt(i);
                projectileSpent = true;
            }
        }
        if (!projectileSpent) {
            for (int echoIndex = m_bossEchoes.size() - 1; echoIndex >= 0; --echoIndex) {
                auto &echo = m_bossEchoes[echoIndex];
                if (shot.hitEchoIds.contains(echo.id)
                    || distanceSquared(shot.x, shot.y, echo.x, echo.y)
                        > (shot.radius + 24) * (shot.radius + 24))
                    continue;
                shot.hitEchoIds.append(echo.id);
                echo.health -= shot.damage;
                spawnBurst(echo.x, echo.y, "#b5d8db", 8, 1);
                if (echo.health <= 0)
                    m_bossEchoes.removeAt(echoIndex);
                if (shot.pierce > 0)
                    --shot.pierce;
                else {
                    m_projectiles.removeAt(i);
                    projectileSpent = true;
                }
                break;
            }
        }
        const qreal bossRadius = m_stage == 4 ? 112 : 40;
        if (projectileSpent || !m_bossActive || shot.hitBoss
            || distanceSquared(shot.x, shot.y, m_bossX, m_bossY)
                > (shot.radius + bossRadius) * (shot.radius + bossRadius))
            continue;

        shot.hitBoss = true;
        m_bossHealth -= shot.damage;
        if (shot.heroClass == 1) {
            const qreal blastRadius = 66 + m_classUpgradeLevels.value("blastRadius") * 18;
            const qreal splashDamage = shot.damage
                * (0.5 + m_classUpgradeLevels.value("blastRadius") * 0.06);
            m_attackEffects.append({m_bossX, m_bossY, blastRadius, 0, 0.34, 0.34, 1});
            for (int k = m_enemies.size() - 1; k >= 0; --k) {
                if (distanceSquared(m_bossX, m_bossY, m_enemies[k].x, m_enemies[k].y)
                    > blastRadius * blastRadius)
                    continue;
                m_enemies[k].health -= splashDamage;
                spawnBurst(m_enemies[k].x, m_enemies[k].y, "#ad91ff", 5, 1);
                if (m_enemies[k].health <= 0)
                    dropCreature(k);
            }
        }
        if (shot.element == 1) {
            m_bossBurnTime = 2.2 + m_fireLevel * 0.35;
            m_bossBurnTick = qMin<qreal>(m_bossBurnTick, 0.35);
        } else if (shot.element == 2) {
            m_bossSlowTime = 1.4 + m_iceLevel * 0.2;
        }
        const QString bossColor = shot.element == 1 ? "#ff824f" : shot.element == 2 ? "#74dcff"
            : shot.element == 3 ? "#ffe370" : shot.element == 4 ? "#c596ff" : "#ffe7a0";
        spawnBurst(m_bossX, m_bossY, bossColor, 12, 1);
        if (m_hitSoundCooldown <= 0) {
            emit audioCue(shot.element == 3 ? "lightning" : "hit");
            m_hitSoundCooldown = 0.12;
        }
        if (shot.element == 3) {
            int chained = 0;
            for (int k = m_enemies.size() - 1; k >= 0 && chained < 1 + m_lightningLevel / 2; --k) {
                if (m_enemies[k].health <= 0
                    || distanceSquared(m_bossX, m_bossY, m_enemies[k].x, m_enemies[k].y)
                        > 145 * 145)
                    continue;
                m_enemies[k].health -= shot.damage * 0.55;
                spawnBurst(m_enemies[k].x, m_enemies[k].y, "#ffe370", 7, 1);
                ++chained;
                if (m_enemies[k].health <= 0)
                    dropCreature(k);
            }
        }
        if (m_bossHealth <= 0)
            defeatBoss();
        if (shot.pierce > 0) {
            --shot.pierce;
        } else {
            m_projectiles.removeAt(i);
        }
    }
    if (m_projectileClearPending) {
        m_projectiles.clear();
        m_projectileClearPending = false;
    }

    for (int i = m_attackEffects.size() - 1; i >= 0; --i) {
        m_attackEffects[i].life -= dt;
        if (m_attackEffects[i].life <= 0)
            m_attackEffects.removeAt(i);
    }

    for (int i = m_particles.size() - 1; i >= 0; --i) {
        auto &particle = m_particles[i];
        particle.life -= dt;
        particle.x += particle.vx * dt;
        particle.y += particle.vy * dt;
        particle.vx *= 0.96;
        particle.vy *= 0.96;
        if (particle.life <= 0)
            m_particles.removeAt(i);
    }

    collectExperience(dt);
    collectDrops(dt);
    if (m_victoryCountdown > 0) {
        m_victoryCountdown = qMax<qreal>(0, m_victoryCountdown - dt);
        if (m_victoryCountdown <= 0) {
            m_state = "victory";
            m_timer.stop();
        }
    }
    emit changed();
}
