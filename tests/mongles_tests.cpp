#include <QtTest>

#include <cmath>

#include "backend.h"

class MonglesTests : public QObject {
    Q_OBJECT

private slots:
    void startsAndPauses()
    {
        Backend backend;
        QCOMPARE(backend.state(), QString("menu"));
        backend.startGame();
        QCOMPARE(backend.state(), QString("playing"));
        backend.pauseGame();
        QCOMPARE(backend.state(), QString("paused"));
        backend.resumeGame();
        QCOMPARE(backend.state(), QString("playing"));
    }

    void resetsRunProgress()
    {
        Backend backend;
        backend.startGame();
        backend.startGame();
        QCOMPARE(backend.level(), 1);
        QCOMPARE(backend.kills(), 0);
        QCOMPARE(backend.health(), backend.maxHealth());
        QCOMPARE(backend.experience(), 0);
        QCOMPARE(backend.stage(), 1);
        QCOMPARE(backend.cycle(), 1);
        QCOMPARE(backend.attackEffects().size(), 0);
        QCOMPARE(backend.classUpgradeLevels().size(), 0);
        QCOMPARE(backend.stageTimeLeft(), 40);
        QCOMPARE(backend.boss().value("active").toBool(), false);
        QCOMPARE(backend.drops().size(), 0);
        QCOMPARE(backend.speedBoostTime(), 0);
        QCOMPARE(backend.fireRateBoostTime(), 0);
        QCOMPARE(backend.hordeAlertTime(), 0);
        QCOMPARE(backend.magnetTime(), 0);
    }

    void movementIsIgnoredOutsideGame()
    {
        Backend backend;
        const qreal initialX = backend.playerX();
        backend.movePlayer(1, 0);
        QCOMPARE(backend.playerX(), initialX);
        backend.startGame();
        backend.movePlayer(1, 0);
        QVERIFY(backend.playerX() > initialX);
    }

    void analogMovementPreservesPartialInput()
    {
        Backend backend;
        backend.setMovement(0.5, 0);
        QCOMPARE(backend.m_moveX, 0.5);
        QCOMPARE(backend.m_moveY, 0.0);
    }

    void upgradesRequireAnOfferedChoice()
    {
        Backend backend;
        backend.chooseUpgrade("fire");
        QCOMPARE(backend.state(), QString("menu"));
        QCOMPARE(backend.upgradeLevels().value("fire").toInt(), 0);
    }

    void restartingClearsTheOfferedUpgrades()
    {
        Backend backend;
        backend.startGame();
        backend.startGame();
        QCOMPARE(backend.upgradeOptions().size(), 0);
        QCOMPARE(backend.upgradeLevels().value("fire").toInt(), 0);
        QCOMPARE(backend.activeElement(), QString("arcane"));
    }

    void selectingAClassChangesItsStartingStats()
    {
        Backend backend;
        QCOMPARE(backend.heroClass(), QString("warrior"));
        backend.chooseClass("mage");
        QCOMPARE(backend.heroClass(), QString("mage"));
        backend.startGame();
        QCOMPARE(backend.maxHealth(), 86);
        backend.chooseClass("archer");
        QCOMPARE(backend.heroClass(), QString("mage"));
        backend.pauseGame();
        backend.startGame();
        QCOMPARE(backend.maxHealth(), 86);
    }

    void classSelectionRejectsUnknownClasses()
    {
        Backend backend;
        backend.chooseClass("necromancer");
        QCOMPARE(backend.heroClass(), QString("warrior"));
    }

    void everyClassHasItsOwnStartingHealth()
    {
        Backend warrior;
        warrior.startGame();
        QCOMPARE(warrior.maxHealth(), 140);

        Backend mage;
        mage.chooseClass("mage");
        mage.startGame();
        QCOMPARE(mage.maxHealth(), 86);

        Backend archer;
        archer.chooseClass("archer");
        archer.startGame();
        QCOMPARE(archer.maxHealth(), 105);

        Backend bronhaman;
        bronhaman.chooseClass("bronhaman");
        bronhaman.startGame();
        QCOMPARE(bronhaman.maxHealth(), 110);
        QCOMPARE(bronhaman.heroClass(), QString("bronhaman"));
    }

    void summonerClassesStartWithTheirOwnAllies()
    {
        Backend lango;
        lango.chooseClass("lango");
        lango.startGame();
        QCOMPARE(lango.maxHealth(), 94);
        QCOMPARE(lango.summons().size(), 3);
        QCOMPARE(lango.summons().first().toMap().value("kind").toString(), QString("skeleton"));
        QCOMPARE(lango.summons().first().toMap().value("health").toReal(), 60.0);
        QCOMPARE(lango.summons().first().toMap().value("maxHealth").toReal(), 60.0);

        Backend kalengue;
        kalengue.chooseClass("kalengue");
        kalengue.startGame();
        QCOMPARE(kalengue.maxHealth(), 100);
        QCOMPARE(kalengue.summons().size(), 3);
        QCOMPARE(kalengue.summons().first().toMap().value("kind").toString(), QString("cat"));
        QCOMPARE(kalengue.summons().first().toMap().value("health").toReal(), 60.0);
    }

    void summonersStartInSeparatedFormations()
    {
        const auto areSeparated = [](const QVariantList &positions, qreal minimum) {
            for (int i = 0; i < positions.size(); ++i) {
                const QVariantMap first = positions[i].toMap();
                for (int j = i + 1; j < positions.size(); ++j) {
                    const QVariantMap second = positions[j].toMap();
                    const qreal dx = first.value("x").toReal() - second.value("x").toReal();
                    const qreal dy = first.value("y").toReal() - second.value("y").toReal();
                    if (std::hypot(dx, dy) <= minimum)
                        return false;
                }
            }
            return true;
        };

        for (const QString &heroClass : {QString("lango"), QString("kalengue")}) {
            Backend backend;
            backend.chooseClass(heroClass);
            backend.startGame();
            const QVariantList summons = backend.summons();
            QCOMPARE(summons.size(), 3);
            QVERIFY(areSeparated(summons, 90));
            QTest::qWait(200);
            QVERIFY(areSeparated(backend.summons(), 50));
        }
    }

    void summonerClassSelectionRejectsUnknownClasses()
    {
        Backend backend;
        backend.chooseClass("lango");
        QCOMPARE(backend.heroClass(), QString("lango"));
        backend.chooseClass("kalengue");
        QCOMPARE(backend.heroClass(), QString("kalengue"));
        backend.chooseClass("bronhaman");
        QCOMPARE(backend.heroClass(), QString("bronhaman"));
        backend.chooseClass("unknown");
        QCOMPARE(backend.heroClass(), QString("bronhaman"));
    }

    void bossDefeatKeepsLootAndPullsItIntoTheNextStage()
    {
        Backend backend;
        backend.startGame();
        backend.m_stage = 0;
        backend.m_bossActive = true;
        backend.m_bossX = 220;
        backend.m_bossY = 220;
        backend.m_experienceNeeded = 999;
        backend.m_gems.append({900, 600});
        backend.m_drops.append({900, 600, "speed"});

        backend.defeatBoss();

        QCOMPARE(backend.stage(), 2);
        QVERIFY(backend.magnetTime() > 0);
        QCOMPARE(backend.drops().size(), 1);
        QVERIFY(backend.gems().size() >= 5);

        backend.collectExperience(1.0);
        backend.collectExperience(1.0);
        backend.collectDrops(1.0);
        backend.collectDrops(1.0);
        QCOMPARE(backend.drops().size(), 0);
        QCOMPARE(backend.speedBoostTime(), 12);
    }

    void finalBossAllowsTheMagnetToFinishBeforeVictory()
    {
        Backend backend;
        backend.startGame();
        backend.m_stage = 4;
        backend.m_bossActive = true;
        backend.m_bossHealth = 1;
        backend.m_bossMaxHealth = 1;

        backend.defeatBoss();

        QCOMPARE(backend.stage(), 5);
        QCOMPARE(backend.state(), QString("playing"));
        QVERIFY(backend.magnetTime() > 0);
        QTRY_COMPARE_WITH_TIMEOUT(backend.state(), QString("victory"), 4000);
    }
};

QTEST_GUILESS_MAIN(MonglesTests)
#include "mongles_tests.moc"
