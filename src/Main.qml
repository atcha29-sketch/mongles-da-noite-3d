import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtQuick3D

ApplicationWindow {
    id: win
    width: 1200
    height: 800
    minimumWidth: 760
    minimumHeight: 560
    visible: true
    title: qsTr("Mongles da Noite")
    color: "#10121a"
    property bool helpVisible: false
    property bool introVisible: true
    property bool soundEnabled: true
    property bool upPressed: false
    property bool downPressed: false
    property bool leftPressed: false
    property bool rightPressed: false
    property int menuClassIndex: 0
    property int upgradeSelection: 0
    property int lastStage: backend.stage
    property string lastState: backend.state
    property bool stageBannerVisible: false
    property bool stageTransitionPaused: false
    property int musicStage: 0
    property bool musicBoss: false

    onSoundEnabledChanged: {
        if (soundEnabled && musicStage > 0
                && stageMusic.playbackState !== MediaPlayer.PlayingState)
            stageMusic.play()
    }

    function updateMovement() {
        var x = (rightPressed ? 1 : 0) - (leftPressed ? 1 : 0) + gamepad.leftX
        var y = (downPressed ? 1 : 0) - (upPressed ? 1 : 0) + gamepad.leftY
        var length = Math.sqrt(x * x + y * y)
        if (length > 1) {
            x /= length
            y /= length
        }
        backend.setMovement(x, y)
    }
    function selectMenuClass(delta) {
        var classes = ["warrior", "mage", "archer", "lango", "kalengue", "bronhaman"]
        var current = classes.indexOf(backend.heroClass)
        menuClassIndex = (current + delta + classes.length) % classes.length
        backend.chooseClass(classes[menuClassIndex])
    }
    function moveUpgradeSelection(delta) {
        if (backend.upgradeOptions.length === 0) return
        upgradeSelection = (upgradeSelection + delta + backend.upgradeOptions.length)
            % backend.upgradeOptions.length
    }
    function handleGamepadButton(button) {
        if (button === "x") {
            soundEnabled = !soundEnabled
            return
        }
        if (button === "y") {
            helpVisible = !helpVisible
            return
        }
        if (helpVisible) {
            if (button === "a" || button === "b" || button === "start")
                helpVisible = false
            return
        }
        if (backend.state === "menu") {
            if (introVisible) {
                if (button === "a" || button === "start") introVisible = false
            } else if (button === "left" || button === "up" || button === "leftShoulder") {
                selectMenuClass(-1)
            } else if (button === "right" || button === "down" || button === "rightShoulder") {
                selectMenuClass(1)
            } else if (button === "a" || button === "start") {
                backend.startGame()
            } else if (button === "b") {
                introVisible = true
            }
        } else if (backend.state === "playing") {
            if ((button === "b" || button === "start") && !stageTransitionPaused)
                backend.togglePause()
        } else if (backend.state === "paused") {
            if (button === "a" || button === "b" || button === "start")
                backend.resumeGame()
        } else if (backend.state === "upgrade") {
            if (button === "left" || button === "up" || button === "leftShoulder")
                moveUpgradeSelection(-1)
            else if (button === "right" || button === "down" || button === "rightShoulder")
                moveUpgradeSelection(1)
            else if (button === "a")
                quickSelect(upgradeSelection + 1)
        } else if (backend.state === "gameover" || backend.state === "victory") {
            if (button === "a" || button === "start")
                backend.startGame()
            else if (button === "b")
                backend.returnToMenu()
        }
    }
    function elementName(id) {
        if (id === "arcane") return qsTr("ARCANE")
        if (id === "fire") return qsTr("FIRE")
        if (id === "ice") return qsTr("ICE")
        if (id === "lightning") return qsTr("LIGHTNING")
        return qsTr("SHADOW")
    }
    function elementDescription(id) {
        if (id === "fire") return qsTr("Burn enemies and deal damage over time.")
        if (id === "ice") return qsTr("Freeze monsters and slow their approach.")
        if (id === "lightning") return qsTr("Chain lightning through nearby creatures.")
        return qsTr("Piercing shadow bolts pass through more monsters.")
    }
    function className(id) {
        if (id === "warrior") return qsTr("WARRIOR")
        if (id === "mage") return qsTr("MAGE")
        if (id === "archer") return qsTr("ARCHER")
        if (id === "lango") return qsTr("LANGO")
        if (id === "bronhaman") return qsTr("BRONHA MAN")
        return qsTr("KALENGUE")
    }
    function classDescription(id) {
        if (id === "warrior") return qsTr("360-degree sword swings strike every nearby enemy.")
        if (id === "mage") return qsTr("Arcane orbs explode across nearby enemies.")
        if (id === "archer") return qsTr("Long-range arrows pierce through enemy lines.")
        if (id === "lango") return qsTr("A necromancer who summons little skeletons to hunt enemies.")
        if (id === "bronhaman") return qsTr("A fearless cowboy firing twin golden pistols.")
        return qsTr("A cat summoner whose colorful feline spirits pounce on enemies.")
    }
    function classStats(id) {
        if (id === "warrior") return qsTr("140 HP  ·  MELEE  ·  360°")
        if (id === "mage") return qsTr("92 HP  ·  EXPLOSIVE")
        if (id === "archer") return qsTr("105 HP  ·  LONG RANGE  ·  PIERCE")
        if (id === "lango") return qsTr("100 HP  ·  SKELETONS  ·  NECROMANCY")
        if (id === "bronhaman") return qsTr("100 HP  ·  TWIN PISTOLS  ·  RAPID FIRE")
        return qsTr("100 HP  ·  CATS  ·  SUMMONER")
    }
    function classColor(id) {
        if (id === "warrior") return "#e1b779"
        if (id === "mage") return "#ae91ff"
        if (id === "archer") return "#89d79b"
        if (id === "bronhaman") return "#f0ca61"
        return id === "lango" ? "#d4e4cb" : "#f2a9cb"
    }
    function stageName(number) {
        if (number === 1) return qsTr("BECO DOS NOIAS")
        if (number === 2) return qsTr("QUINTAL DOS NOIADOS")
        if (number === 3) return qsTr("PEDREIRA DA MEIA NOITE")
        if (number === 4) return qsTr("SURUBÃO CENTRAL")
        return qsTr("O VALE DAS CARCAÇAS")
    }
    function nightNotice() {
        if (backend.stage !== 1 || backend.cycle < 2 || backend.cycle > 3) return ""
        if (backend.cycle === 2) return qsTr("SECOND NIGHT — THE THREAT GROWS")
        return qsTr("THIRD NIGHT — FINAL NIGHT. THE VALE AWAITS.")
    }
    function bossName(number) {
        if (number === 1) return qsTr("O MESTRE DO BECO")
        if (number === 2) return qsTr("O ESPANTALHO NOIADO")
        if (number === 3) return qsTr("A PEDRA FUMEGANTE")
        if (number === 4) return qsTr("O REI DA PISTA")
        return qsTr("A CARCAÇA DA MEIA NOITE")
    }
    function subBossName(number) {
        if (number === 1) return qsTr("O CÃO DAS CINZAS")
        if (number === 2) return qsTr("A NOIVA DO QUINTAL")
        if (number === 3) return qsTr("O CAPATAZ DA PEDREIRA")
        if (number === 4) return qsTr("DJ DA RUPTURA")
        return qsTr("O CARRASCO DO VALE")
    }
    function stageLore(number) {
        if (number === 1)
            return qsTr("A primeira fenda abriu no asfalto do Beco dos Noias. Siga os rastros de cinza até a origem da noite.")
        if (number === 2)
            return qsTr("No quintal, as cercas escondem um antigo pacto. As criaturas conhecem o caminho antes de você.")
        if (number === 3)
            return qsTr("Na Pedreira da Meia Noite, as vozes dos mineiros ecoam sob a rocha. O ritual ainda pulsa.")
        if (number === 4)
            return qsTr("O som do Surubão Central alimenta a ruptura. Derrube o Rei da Pista e faça a cidade respirar.")
        return qsTr("Depois de três noites vencidas, o chão se abre no Vale das Carcaças. A própria fenda ganhou um corpo.")
    }
    function combatStatus() {
        var effects = []
        if (backend.magnetTime > 0)
            effects.push(qsTr("MAGNET · COLLECTING LOOT"))
        if (backend.speedBoostTime > 0)
            effects.push(qsTr("SPEED +35% · %1s").arg(backend.speedBoostTime))
        if (backend.fireRateBoostTime > 0)
            effects.push(qsTr("FIRE RATE +50% · %1s").arg(backend.fireRateBoostTime))
        return effects.length ? effects.join("  ") : qsTr("%1 · POWER %2")
            .arg(elementName(backend.activeElement))
            .arg(backend.upgradeLevels[backend.activeElement] || 0)
    }
    function updateStageMusic() {
        var bossActive = backend.boss.active
        if (musicStage === backend.stage && musicBoss === bossActive) return
        var stageTracks = ["qrc:/audio/music-alley.wav", "qrc:/audio/music-backyard.wav",
                           "qrc:/audio/music-cave.wav", "qrc:/audio/music-central.wav",
                           "qrc:/audio/music-valley.wav"]
        var bossTracks = ["qrc:/audio/music-boss-alley.wav", "qrc:/audio/music-boss-backyard.wav",
                          "qrc:/audio/music-boss-cave.wav", "qrc:/audio/music-boss-central.wav",
                          "qrc:/audio/music-boss-valley.wav"]
        musicStage = backend.stage
        musicBoss = bossActive
        stageMusic.stop()
        stageMusic.source = bossActive ? bossTracks[musicStage - 1] : stageTracks[musicStage - 1]
        if (soundEnabled) stageMusic.play()
    }
    function upgradeDescription(id) {
        var level = backend.upgradeLevels[id] || 0
        var classLevel = backend.classUpgradeLevels[id] || 0
        if (id === "wideArc")
            return qsTr("Expand the 360° sword sweep by %1 units per rank.").arg(18)
        if (id === "heavyBlade")
            return qsTr("Add %1 damage to every sword hit.").arg("0.42")
        if (id === "ironSkin")
            return qsTr("Reduce incoming damage by %1% per rank.").arg(15)
        if (id === "blastRadius")
            return qsTr("Increase magic blast radius by %1 units.").arg(18)
        if (id === "arcaneFocus")
            return qsTr("Increase arcane orb damage by %1.").arg("0.25")
        if (id === "manaFlow")
            return qsTr("Cast spells %1% faster per rank.").arg(9)
        if (id === "piercing")
            return qsTr("Arrows pierce %1 more enemies per rank.").arg(1)
        if (id === "longbow")
            return qsTr("Increase arrow speed by 80 and damage by 0.22 per rank.")
        if (id === "skeletonPact")
            return qsTr("Summon one additional skeleton, up to three extra allies.")
        if (id === "skeletonLegion")
            return qsTr("Summon one extra skeleton per rank, up to two more allies.")
        if (id === "boneClaws")
            return qsTr("Skeleton strikes deal %1 more damage per rank.").arg("0.25")
        if (id === "graveMarch")
            return qsTr("Skeletons attack %1% faster per rank.").arg(5)
        if (id === "catCoven")
            return qsTr("Summon one additional colored cat, up to three extra allies.")
        if (id === "catParade")
            return qsTr("Summon one extra cat per rank, up to two more allies.")
        if (id === "sharpClaws")
            return qsTr("Cat pounces deal %1 more damage per rank.").arg("0.25")
        if (id === "felineGrace")
            return qsTr("Cats pounce %1% faster per rank.").arg(5)
        if (id === "goldenCaliber")
            return qsTr("Add %1 damage to every golden bullet.").arg("0.22")
        if (id === "quickDraw")
            return qsTr("Fire %1% faster per rank.").arg(7)
        if (id === "fanTheHammer")
            return qsTr("Fire %1 extra golden bullets in every volley.")
                .arg(Math.min(4, (classLevel + 1) * 2))
        if (id === "multishot")
            return qsTr("Fire %1 extra arrow per volley.").arg(Math.min(2, classLevel + 1))
        if (id === "fire")
            return qsTr("Burns enemies for %1 seconds; each rank adds burn damage.")
                .arg((2.2 + level * 0.35).toFixed(1))
        if (id === "ice")
            return qsTr("Slows enemies for %1 seconds and weakens their pursuit.")
                .arg((1.4 + level * 0.2).toFixed(1))
        if (id === "lightning")
            return qsTr("Jumps to %1 nearby enemies on every hit.")
                .arg(1 + Math.floor(level / 2))
        return qsTr("Each rank lets shadow shots pierce one more enemy.")
    }
    function upgradeName(id) {
        if (id === "wideArc") return qsTr("WIDE ARC")
        if (id === "heavyBlade") return qsTr("HEAVY BLADE")
        if (id === "ironSkin") return qsTr("IRON SKIN")
        if (id === "blastRadius") return qsTr("BLAST RADIUS")
        if (id === "arcaneFocus") return qsTr("ARCANE FOCUS")
        if (id === "manaFlow") return qsTr("MANA FLOW")
        if (id === "piercing") return qsTr("PIERCING ARROWS")
        if (id === "longbow") return qsTr("LONG BOW")
        if (id === "multishot") return qsTr("MULTISHOT")
        if (id === "skeletonPact") return qsTr("SKELETON PACT")
        if (id === "skeletonLegion") return qsTr("SKELETON LEGION")
        if (id === "boneClaws") return qsTr("BONE CLAWS")
        if (id === "graveMarch") return qsTr("GRAVE MARCH")
        if (id === "catCoven") return qsTr("CAT COVEN")
        if (id === "catParade") return qsTr("CAT PARADE")
        if (id === "sharpClaws") return qsTr("SHARP CLAWS")
        if (id === "felineGrace") return qsTr("FELINE GRACE")
        if (id === "goldenCaliber") return qsTr("GOLDEN CALIBER")
        if (id === "quickDraw") return qsTr("QUICK DRAW")
        if (id === "fanTheHammer") return qsTr("FAN THE HAMMER")
        return elementName(id)
    }
    function upgradeLevel(id) {
        return id === "fire" || id === "ice" || id === "lightning" || id === "shadow"
            ? (backend.upgradeLevels[id] || 0) + 1
            : (backend.classUpgradeLevels[id] || 0) + 1
    }
    function upgradeColor(id) {
        if (id === "fire") return "#ff824f"
        if (id === "ice") return "#74dcff"
        if (id === "lightning") return "#ffe370"
        if (id === "shadow") return "#c596ff"
        return classColor(backend.heroClass)
    }
    function upgradeIcon(id) {
        if (id === "wideArc") return "◉"
        if (id === "heavyBlade") return "⚔"
        if (id === "ironSkin") return "⬟"
        if (id === "blastRadius") return "✹"
        if (id === "arcaneFocus") return "✦"
        if (id === "manaFlow") return "∞"
        if (id === "piercing") return "➶"
        if (id === "longbow") return "➳"
        if (id === "multishot") return "⋯"
        if (id === "skeletonPact") return "☠"
        if (id === "skeletonLegion") return "♞"
        if (id === "boneClaws") return "⚔"
        if (id === "graveMarch") return "♜"
        if (id === "catCoven") return "🐾"
        if (id === "catParade") return "✧"
        if (id === "sharpClaws") return "✦"
        if (id === "felineGrace") return "♡"
        if (id === "goldenCaliber") return "✦"
        if (id === "quickDraw") return "⌁"
        if (id === "fanTheHammer") return "✣"
        if (id === "fire") return "♨"
        if (id === "ice") return "❄"
        if (id === "lightning") return "ϟ"
        return "◈"
    }
    function quickSelect(slot) {
        if (backend.state === "upgrade" && backend.upgradeOptions.length >= slot) {
            upgradeSelection = slot - 1
            backend.chooseUpgrade(backend.upgradeOptions[slot - 1])
            Qt.callLater(function() { stage.forceActiveFocus() })
        } else if (backend.state === "menu" && !introVisible) {
            menuClassIndex = slot - 1
            backend.chooseClass(["warrior", "mage", "archer", "lango", "kalengue", "bronhaman"][slot - 1])
        }
    }

    SoundEffect { id: shotSound; source: "qrc:/audio/shot.wav"; volume: 0.3 }
    SoundEffect { id: hitSound; source: "qrc:/audio/hit.wav"; volume: 0.34 }
    SoundEffect { id: pickupSound; source: "qrc:/audio/pickup.wav"; volume: 0.36 }
    SoundEffect { id: levelSound; source: "qrc:/audio/levelup.wav"; volume: 0.42 }
    SoundEffect { id: fireSound; source: "qrc:/audio/fire.wav"; volume: 0.4 }
    SoundEffect { id: iceSound; source: "qrc:/audio/ice.wav"; volume: 0.38 }
    SoundEffect { id: lightningSound; source: "qrc:/audio/lightning.wav"; volume: 0.34 }
    SoundEffect { id: shadowSound; source: "qrc:/audio/shadow.wav"; volume: 0.38 }
    SoundEffect { id: hurtSound; source: "qrc:/audio/hurt.wav"; volume: 0.46 }
    SoundEffect { id: gameoverSound; source: "qrc:/audio/gameover.wav"; volume: 0.44 }
    SoundEffect { id: bossSound; source: "qrc:/audio/boss.wav"; volume: 0.48 }
    SoundEffect { id: stageSound; source: "qrc:/audio/stage.wav"; volume: 0.4 }
    SoundEffect { id: victorySound; source: "qrc:/audio/victory.wav"; volume: 0.45 }
    SoundEffect { id: hordeSound; source: "qrc:/audio/horde.wav"; volume: 0.52 }
    SoundEffect { id: warriorAttackSound; source: "qrc:/audio/attack-warrior.wav"; volume: 0.42 }
    SoundEffect { id: mageAttackSound; source: "qrc:/audio/attack-mage.wav"; volume: 0.37 }
    SoundEffect { id: archerAttackSound; source: "qrc:/audio/attack-archer.wav"; volume: 0.38 }
    SoundEffect { id: langoAttackSound; source: "qrc:/audio/attack-lango.wav"; volume: 0.4 }
    SoundEffect { id: kalengueAttackSound; source: "qrc:/audio/attack-kalengue.wav"; volume: 0.4 }
    SoundEffect { id: bronhaAttackSound; source: "qrc:/audio/attack-bronha.wav"; volume: 0.4 }
    SoundEffect { id: warriorUpgradeSound; source: "qrc:/audio/upgrade-warrior.wav"; volume: 0.42 }
    SoundEffect { id: mageUpgradeSound; source: "qrc:/audio/upgrade-mage.wav"; volume: 0.42 }
    SoundEffect { id: archerUpgradeSound; source: "qrc:/audio/upgrade-archer.wav"; volume: 0.42 }
    SoundEffect { id: langoUpgradeSound; source: "qrc:/audio/upgrade-lango.wav"; volume: 0.42 }
    SoundEffect { id: kalengueUpgradeSound; source: "qrc:/audio/upgrade-kalengue.wav"; volume: 0.42 }
    SoundEffect { id: bronhaUpgradeSound; source: "qrc:/audio/upgrade-bronha.wav"; volume: 0.42 }
    MediaPlayer {
        id: stageMusic
        loops: MediaPlayer.Infinite
        audioOutput: AudioOutput { volume: win.soundEnabled ? 0.18 : 0 }
    }
    Connections {
        target: backend
        function onAudioCue(name) {
            if (!win.soundEnabled) return
            if (name === "shoot") shotSound.play()
            else if (name === "hit") hitSound.play()
            else if (name === "lightning") lightningSound.play()
            else if (name === "pickup") pickupSound.play()
            else if (name === "levelup") levelSound.play()
            else if (name === "upgrade-fire") fireSound.play()
            else if (name === "upgrade-ice") iceSound.play()
            else if (name === "upgrade-lightning") lightningSound.play()
            else if (name === "upgrade-shadow") shadowSound.play()
            else if (name === "hurt") hurtSound.play()
            else if (name === "gameover") gameoverSound.play()
            else if (name === "boss") bossSound.play()
            else if (name === "bossDefeated") victorySound.play()
            else if (name === "stage") stageSound.play()
            else if (name === "horde") hordeSound.play()
            else if (name === "powerup") pickupSound.play()
            else if (name === "attack-warrior") warriorAttackSound.play()
            else if (name === "attack-mage") mageAttackSound.play()
            else if (name === "attack-archer") archerAttackSound.play()
            else if (name === "attack-lango") langoAttackSound.play()
            else if (name === "attack-kalengue") kalengueAttackSound.play()
            else if (name === "attack-bronha") bronhaAttackSound.play()
            else if (name === "classUpgrade") {
                if (backend.heroClass === "warrior") warriorUpgradeSound.play()
                else if (backend.heroClass === "mage") mageUpgradeSound.play()
                else if (backend.heroClass === "archer") archerUpgradeSound.play()
                else if (backend.heroClass === "lango") langoUpgradeSound.play()
                else if (backend.heroClass === "bronhaman") bronhaUpgradeSound.play()
                else kalengueUpgradeSound.play()
            }
        }
    }
    Connections {
        target: backend
        function onChanged() {
            win.updateStageMusic()
            var stageChanged = backend.stage !== win.lastStage
            var newRun = backend.state === "playing"
                && (win.lastState === "menu" || win.lastState === "gameover" || win.lastState === "victory")
            if (backend.state === "playing" && (stageChanged || newRun)) {
                win.stageBannerVisible = true
                stageBannerTimer.restart()
                if (stageChanged && !newRun) {
                    win.stageTransitionPaused = true
                    backend.pauseGame()
                }
            }
            if (backend.state === "playing" && win.lastState !== "playing")
                win.updateMovement()
            if (backend.state === "upgrade" && win.lastState !== "upgrade")
                win.upgradeSelection = 0
            win.lastStage = backend.stage
            win.lastState = backend.state
        }
    }
    Connections {
        target: gamepad
        function onChanged() { win.updateMovement() }
        function onButtonPressed(button) { win.handleGamepadButton(button) }
    }

    Shortcut { sequence: "?"; context: Qt.ApplicationShortcut; onActivated: win.helpVisible = !win.helpVisible }
    Shortcut { sequence: "M"; context: Qt.ApplicationShortcut; onActivated: win.soundEnabled = !win.soundEnabled }
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        onActivated: if (!win.stageTransitionPaused) backend.togglePause()
    }
    Shortcut {
        sequence: "Space"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (backend.state === "menu" && win.introVisible) win.introVisible = false
            else if (backend.state === "menu" || backend.state === "gameover" || backend.state === "victory") backend.startGame()
            else if (backend.state === "paused" && !win.stageTransitionPaused) backend.resumeGame()
        }
    }
    Shortcut { sequence: "1"; context: Qt.ApplicationShortcut; onActivated: win.quickSelect(1) }
    Shortcut { sequence: "2"; context: Qt.ApplicationShortcut; onActivated: win.quickSelect(2) }
    Shortcut { sequence: "3"; context: Qt.ApplicationShortcut; onActivated: win.quickSelect(3) }
    Shortcut { sequence: "4"; context: Qt.ApplicationShortcut; onActivated: win.quickSelect(4) }
    Shortcut { sequence: "5"; context: Qt.ApplicationShortcut; onActivated: win.quickSelect(5) }
    Shortcut { sequence: "6"; context: Qt.ApplicationShortcut; onActivated: win.quickSelect(6) }
    Shortcut { sequence: "Q"; context: Qt.ApplicationShortcut; onActivated: win.close() }

    Item {
        id: stage
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_W || event.key === Qt.Key_Up) win.upPressed = true
            else if (event.key === Qt.Key_S || event.key === Qt.Key_Down) win.downPressed = true
            else if (event.key === Qt.Key_A || event.key === Qt.Key_Left) win.leftPressed = true
            else if (event.key === Qt.Key_D || event.key === Qt.Key_Right) win.rightPressed = true
            else return
            win.updateMovement()
            event.accepted = true
        }
        Keys.onReleased: function(event) {
            if (event.key === Qt.Key_W || event.key === Qt.Key_Up) win.upPressed = false
            else if (event.key === Qt.Key_S || event.key === Qt.Key_Down) win.downPressed = false
            else if (event.key === Qt.Key_A || event.key === Qt.Key_Left) win.leftPressed = false
            else if (event.key === Qt.Key_D || event.key === Qt.Key_Right) win.rightPressed = false
            else return
            win.updateMovement()
            event.accepted = true
        }

        Timer {
            id: stageBannerTimer
            interval: 5000
            onTriggered: {
                win.stageBannerVisible = false
                if (win.stageTransitionPaused) {
                    win.stageTransitionPaused = false
                    backend.resumeGame()
                }
            }
        }
        Canvas {
            id: sceneryCanvas
            visible: false
            property int renderedStage: -1
            anchors.fill: parent
            anchors.bottomMargin: 88
            onWidthChanged: if (visible) requestPaint()
            onHeightChanged: if (visible) requestPaint()
            onAvailableChanged: if (visible && available) requestPaint()
            Connections {
                target: backend
                function onChanged() {
                    if (sceneryCanvas.visible && backend.stage !== sceneryCanvas.renderedStage)
                        sceneryCanvas.requestPaint()
                }
            }

            onPaint: {
                if (!visible || !available) return
                var c = getContext("2d")
                if (!c) return
                c.reset()
                c.clearRect(0, 0, width, height)
                c.scale(width / 1000, height / 700)
                scenery(c, backend.stage - 1)
                renderedStage = backend.stage
                if (arena.visible) arena.requestPaint()
            }

            function scenery(c, stageId) {
                arena.scenery(c, stageId)
            }
        }

        Canvas {
            id: arena
            visible: false
            property int spriteFrame: 0
            anchors.fill: parent
            anchors.bottomMargin: 88
            onWidthChanged: if (visible) requestPaint()
            onHeightChanged: if (visible) requestPaint()
            onAvailableChanged: if (visible && available) requestPaint()
            Connections {
                target: backend
                function onChanged() { if (arena.visible) arena.requestPaint() }
            }

            function rect(c, x, y, w, h, color) {
                c.fillStyle = color
                c.fillRect(Math.round(x), Math.round(y), Math.round(w), Math.round(h))
            }
            function polygon(c, points, color) {
                c.beginPath()
                c.moveTo(points[0], points[1])
                for (var i = 2; i < points.length; i += 2)
                    c.lineTo(points[i], points[i + 1])
                c.closePath()
                c.fillStyle = color
                c.fill()
            }
            function glow(c, x, y, radius, color) {
                var gradient = c.createRadialGradient(x, y, 0, x, y, radius)
                gradient.addColorStop(0, color)
                gradient.addColorStop(1, "rgba(10, 14, 28, 0)")
                c.fillStyle = gradient
                c.fillRect(x - radius, y - radius, radius * 2, radius * 2)
            }
            function depthScale(y) {
                return 0.76 + Math.max(0, Math.min(700, y)) * 0.00052
            }
            function groundShadow(c, x, y, radiusX, radiusY, tint) {
                c.save()
                c.globalAlpha = 0.42
                c.translate(x, y)
                c.scale(radiusX, radiusY)
                c.beginPath()
                c.arc(0, 0, 1, 0, Math.PI * 2)
                c.fillStyle = "#080b12"
                c.fill()
                c.globalAlpha = 0.20
                c.beginPath()
                c.arc(0, -0.08, 0.64, 0, Math.PI * 2)
                c.fillStyle = tint
                c.fill()
                c.restore()
            }
            function grave(c, x, y, variant) {
                rect(c, x - 15, y + 15, 30, 5, "#10151d")
                rect(c, x - 10, y - 11, 20, 25, "#262b38")
                rect(c, x - 7, y - 15, 14, 5, "#353b49")
                rect(c, x - 7, y - 8, 14, 2, "#48505a")
                if (variant === 0) {
                    rect(c, x - 2, y - 7, 4, 12, "#69756c")
                    rect(c, x - 6, y - 3, 12, 4, "#69756c")
                } else {
                    rect(c, x - 4, y - 5, 8, 2, "#66706b")
                    rect(c, x - 4, y, 8, 2, "#66706b")
                }
                rect(c, x - 8, y + 10, 16, 2, "#1a202a")
            }
            function pine(c, x, y, size) {
                rect(c, x - 4, y + size - 5, 8, 15, "#211f2a")
                polygon(c, [x, y - size, x - size * 0.62, y - size * 0.1,
                            x - size * 0.32, y - size * 0.1, x - size * 0.82, y + size * 0.48,
                            x - size * 0.35, y + size * 0.42, x - size * 0.68, y + size * 0.82,
                            x + size * 0.68, y + size * 0.82, x + size * 0.35, y + size * 0.42,
                            x + size * 0.82, y + size * 0.48, x + size * 0.32, y - size * 0.1,
                            x + size * 0.62, y - size * 0.1], "#202733")
                polygon(c, [x, y - size * 0.78, x - size * 0.38, y - size * 0.05,
                            x + size * 0.28, y - size * 0.05], "#29343a")
            }
            function scenery(c, stageId) {
                var skyTop = ["#101323", "#121a20", "#121923", "#130f24", "#1b1016"]
                var skyMid = ["#252333", "#23372c", "#2a3036", "#29203b", "#45252b"]
                var groundTop = ["#24252d", "#263326", "#343337", "#25243a", "#3b2b30"]
                var groundBottom = ["#181c23", "#17251e", "#202126", "#131624", "#1d171a"]
                var mountain = ["#171d2a", "#1a2924", "#282b31", "#201a32", "#302027"]
                var sky = c.createLinearGradient(0, 0, 0, 700)
                sky.addColorStop(0, skyTop[stageId])
                sky.addColorStop(0.52, skyMid[stageId])
                sky.addColorStop(1, groundTop[stageId])
                c.fillStyle = sky
                c.fillRect(0, 0, 1000, 700)

                glow(c, 814, 132, 150, "#747ba0")
                rect(c, 778, 96, 68, 68, stageId === 4 ? "#d67a72"
                    : stageId === 3 ? "#d9b8cb" : stageId === 2 ? "#c8aa77" : "#d4d0b1")
                rect(c, 790, 86, 45, 10, stageId === 4 ? "#f2a095"
                    : stageId === 3 ? "#f5c5ce" : stageId === 2 ? "#ead29d" : "#e5dfc2")
                rect(c, 790, 164, 45, 9, stageId === 4 ? "#87464b" : "#a9a89f")
                rect(c, 795, 108, 8, 8, stageId === 4 ? "#9d5451" : "#b1b1a6")
                rect(c, 818, 133, 8, 8, stageId === 4 ? "#9d5451" : "#b1b1a6")

                var stars = [[72, 81], [162, 124], [258, 64], [347, 146], [457, 92],
                    [548, 58], [644, 142], [722, 62], [911, 92], [949, 189],
                    [118, 204], [286, 187], [398, 216], [591, 194], [691, 230]]
                for (var s = 0; s < stars.length; ++s) {
                    var star = stars[s]
                    rect(c, star[0], star[1], 3, 3, s % 3 === 0 ? "#a4acc1" : "#65728d")
                    if (s % 4 === 0) rect(c, star[0] + 1, star[1] - 3, 1, 9, "#48536a")
                }

                polygon(c, [0, 315, 115, 224, 240, 304, 355, 211, 492, 316,
                            626, 229, 758, 310, 886, 216, 1000, 294, 1000, 420, 0, 420], mountain[stageId])
                polygon(c, [0, 355, 130, 288, 274, 365, 435, 272, 568, 365,
                            760, 282, 900, 363, 1000, 305, 1000, 470, 0, 470],
                        stageId === 0 ? "#1c222c" : stageId === 1 ? "#1d3028"
                        : stageId === 2 ? "#303039" : "#211c35")

                var ground = c.createLinearGradient(0, 360, 0, 700)
                ground.addColorStop(0, groundTop[stageId])
                ground.addColorStop(0.4, stageId === 1 ? "#29352a"
                    : stageId === 2 ? "#363337" : stageId === 3 ? "#27233a" : "#29272f")
                ground.addColorStop(1, groundBottom[stageId])
                c.fillStyle = ground
                c.fillRect(0, 358, 1000, 342)

                // Converging floor seams give the arena a stronger sense of depth.
                c.save()
                c.globalAlpha = 0.24
                for (var seam = 0; seam < 11; ++seam) {
                    var nearX = 28 + seam * 94
                    var farX = 478 + (nearX - 500) * 0.18
                    c.beginPath()
                    c.moveTo(farX, 438)
                    c.lineTo(nearX, 700)
                    c.strokeStyle = seam % 2 === 0 ? "#9aa1a5" : "#5f6974"
                    c.lineWidth = seam % 2 === 0 ? 2 : 1
                    c.stroke()
                }
                for (var floorRow = 0; floorRow < 6; ++floorRow) {
                    var rowY = 458 + floorRow * floorRow * 6
                    c.beginPath()
                    c.moveTo(0, rowY)
                    c.lineTo(1000, rowY)
                    c.strokeStyle = "#aeb0a8"
                    c.lineWidth = 1 + floorRow * 0.35
                    c.stroke()
                }
                c.restore()

                if (stageId === 0) {
                    rect(c, 0, 218, 112, 256, "#292631")
                    rect(c, 0, 218, 112, 8, "#403a42")
                    rect(c, 884, 205, 116, 270, "#282631")
                    rect(c, 884, 205, 116, 8, "#403a42")
                    for (var brick = 0; brick < 8; ++brick) {
                        rect(c, 14 + (brick % 2) * 28, 245 + Math.floor(brick / 2) * 35, 18, 12, "#45404a")
                        rect(c, 914 + (brick % 2) * 32, 235 + Math.floor(brick / 2) * 38, 22, 13, "#403c49")
                    }
                    rect(c, 42, 290, 34, 54, "#1a1b29")
                    rect(c, 48, 296, 22, 44, "#7b5149")
                    rect(c, 922, 270, 31, 39, "#a77a57")
                    rect(c, 928, 276, 19, 27, "#d7ae77")
                    rect(c, 132, 430, 42, 43, "#47615b")
                    rect(c, 126, 423, 55, 10, "#6a7668")
                    rect(c, 135, 436, 36, 4, "#829280")
                    rect(c, 838, 427, 47, 49, "#564b5a")
                    rect(c, 831, 420, 60, 10, "#85715d")
                    rect(c, 860, 278, 6, 148, "#554a4b")
                    glow(c, 863, 282, 48, "#d5a469")
                    rect(c, 850, 274, 28, 7, "#e2bd77")
                } else if (stageId === 1) {
                    rect(c, 755, 245, 180, 118, "#594b42")
                    polygon(c, [735, 253, 845, 185, 957, 253], "#775b4c")
                    rect(c, 784, 278, 40, 46, "#30363a")
                    rect(c, 851, 277, 49, 37, "#9a7958")
                    rect(c, 858, 284, 35, 26, "#dfbd78")
                    rect(c, 0, 420, 1000, 9, "#7c604b")
                    for (var fence = 0; fence < 26; ++fence) {
                        var fenceX = fence * 40
                        rect(c, fenceX, 422, 5, 65, "#907258")
                        polygon(c, [fenceX - 2, 423, fenceX + 2, 410, fenceX + 7, 423], "#b19369")
                    }
                    rect(c, 0, 430, 1000, 6, "#b19369")
                    rect(c, 0, 458, 1000, 5, "#a18461")
                    rect(c, 252, 300, 385, 3, "#8c8370")
                    rect(c, 252, 300, 3, 70, "#8c8370")
                    rect(c, 634, 300, 3, 70, "#8c8370")
                    rect(c, 305, 303, 35, 48, "#9d5366")
                    rect(c, 390, 303, 40, 64, "#667a9a")
                    rect(c, 500, 303, 40, 52, "#8a9b5b")
                } else if (stageId === 2) {
                    var dust = c.createRadialGradient(510, 355, 15, 510, 355, 430)
                    dust.addColorStop(0, "rgba(195, 151, 91, 0.26)")
                    dust.addColorStop(1, "rgba(25, 25, 31, 0)")
                    c.fillStyle = dust
                    c.fillRect(40, 110, 920, 420)
                    for (var cliff = 0; cliff < 9; ++cliff) {
                        var cliffX = cliff * 122 - 34
                        var cliffHeight = 105 + (cliff * 41) % 94
                        polygon(c, [cliffX, 450, cliffX + 17, 332 - cliffHeight / 3,
                                    cliffX + 56, 294 - cliffHeight,
                                    cliffX + 91, 341 - cliffHeight / 2,
                                    cliffX + 124, 450],
                                cliff % 2 === 0 ? "#414047" : "#4c4949")
                        polygon(c, [cliffX + 42, 323 - cliffHeight,
                                    cliffX + 56, 294 - cliffHeight,
                                    cliffX + 71, 326 - cliffHeight / 2],
                                "#82715f")
                    }
                    for (var support = 0; support < 5; ++support) {
                        var supportX = 120 + support * 190
                        rect(c, supportX, 266, 10, 168, "#75573e")
                        rect(c, supportX + 108, 266, 10, 168, "#75573e")
                        rect(c, supportX - 8, 264, 142, 12, "#95724c")
                        rect(c, supportX - 1, 278, 5, 147, "#b08a5a")
                        rect(c, supportX + 115, 278, 5, 147, "#b08a5a")
                        glow(c, supportX + 55, 295, 35, "#e0a34d")
                        rect(c, supportX + 47, 292, 16, 5, "#f5ca79")
                    }
                    for (var ore = 0; ore < 6; ++ore) {
                        var oreX = ore * 174 + 24
                        polygon(c, [oreX, 495, oreX + 14, 464, oreX + 28, 495], "#8f754f")
                        polygon(c, [oreX + 20, 498, oreX + 34, 474, oreX + 48, 498], "#6e6253")
                    }
                    rect(c, 405, 420, 116, 35, "#51443a")
                    polygon(c, [396, 420, 463, 391, 530, 420], "#745b42")
                    rect(c, 421, 425, 13, 30, "#2c2a2a")
                    rect(c, 488, 425, 13, 30, "#2c2a2a")
                    c.beginPath()
                    c.arc(423, 463, 11, 0, Math.PI * 2)
                    c.arc(502, 463, 11, 0, Math.PI * 2)
                    c.fillStyle = "#b49a70"
                    c.fill()
                    c.strokeStyle = "#463b34"
                    c.lineWidth = 4
                    c.stroke()
                    for (var track = 0; track < 2; ++track) {
                        rect(c, 0, 488 + track * 16, 1000, 4, "#6e655c")
                        for (var tie = 0; tie < 14; ++tie)
                            rect(c, tie * 78 + 10, 485 + track * 16, 5, 23, "#51473f")
                    }
                } else if (stageId === 3) {
                    for (var building = 0; building < 8; ++building) {
                        var buildingX = building * 130 - 20
                        var buildingHeight = 142 + (building * 47) % 98
                        rect(c, buildingX, 454 - buildingHeight, 104, buildingHeight, "#242337")
                        rect(c, buildingX, 454 - buildingHeight, 104, 5, "#49405e")
                        for (var window = 0; window < 3; ++window) {
                            rect(c, buildingX + 14 + window * 28, 376 - buildingHeight,
                                 12, 17, window % 2 === 0 ? "#b35f8e" : "#547bb5")
                        }
                    }
                    glow(c, 240, 350, 108, "#963f8c")
                    glow(c, 756, 345, 115, "#397c9b")
                    rect(c, 95, 335, 108, 6, "#e45d9b")
                    rect(c, 95, 341, 7, 55, "#a54b86")
                    rect(c, 191, 341, 7, 55, "#a54b86")
                    rect(c, 95, 395, 105, 5, "#783b76")
                    rect(c, 803, 323, 84, 6, "#63d5d1")
                    rect(c, 803, 329, 6, 65, "#416e8f")
                    rect(c, 881, 329, 6, 65, "#416e8f")
                    c.font = "bold 12px monospace"
                    c.fillStyle = "#f3a5cc"
                    c.fillText("CENTRAL", 115, 373)
                } else {
                    for (var ruin = 0; ruin < 9; ++ruin) {
                        var ruinX = ruin * 124 - 16
                        var ruinY = 280 + (ruin * 47) % 95
                        polygon(c, [ruinX, 466, ruinX + 16, ruinY + 36,
                                    ruinX + 48, ruinY, ruinX + 82, ruinY + 49,
                                    ruinX + 112, 466], ruin % 2 ? "#463138" : "#392b31")
                        rect(c, ruinX + 45, ruinY + 22, 8, 30, "#6b4345")
                    }
                    for (var rib = 0; rib < 5; ++rib) {
                        var ribX = 120 + rib * 190
                        polygon(c, [ribX, 400, ribX + 18, 293, ribX + 35, 400],
                                rib % 2 ? "#79605b" : "#64504e")
                        polygon(c, [ribX + 45, 400, ribX + 64, 273, ribX + 84, 400],
                                rib % 2 ? "#64504e" : "#79605b")
                        rect(c, ribX + 27, 375, 53, 8, "#9a7770")
                    }
                    glow(c, 505, 342, 210, "#9b424b")
                }

                polygon(c, [0, 492, 183, 471, 313, 492, 501, 470, 680, 493,
                            839, 474, 1000, 495, 1000, 700, 0, 700],
                        stageId === 0 ? "#27262a" : stageId === 1 ? "#273329"
                        : stageId === 2 ? "#343238" : stageId === 3 ? "#242238" : "#302326")
                if (stageId === 0 || stageId === 3) {
                    for (var row = 0; row < 7; ++row) {
                        for (var tile = 0; tile < 15; ++tile) {
                            var tx = tile * 73 + (row % 2) * 26 + 18
                            var ty = 506 + row * 28
                            rect(c, tx, ty, 2 + ((tile + row) % 3), 2,
                                 stageId === 3 ? "#393149" : (tile + row) % 2 === 0 ? "#39363a" : "#333238")
                        }
                    }
                }
                if (stageId === 1) {
                    for (var weed = 0; weed < 32; ++weed) {
                        var wx = (weed * 137 + 41) % 980 + 10
                        var wy = 390 + (weed * 83) % 285
                        rect(c, wx, wy, 3, 8, "#374c37")
                        rect(c, wx - 3, wy + 2, 3, 3, "#506549")
                        if (weed % 4 === 0) rect(c, wx + 3, wy - 2, 3, 3, "#d29dbe")
                    }
                } else if (stageId === 2) {
                    for (var crack = 0; crack < 12; ++crack) {
                        var crackX = crack * 84 + 24
                        rect(c, crackX, 526 + (crack % 3) * 38, 20, 2, "#493454")
                        rect(c, crackX + 18, 526 + (crack % 3) * 38, 2, 9, "#493454")
                    }
                } else if (stageId === 3) {
                    for (var beam = 0; beam < 5; ++beam) {
                        rect(c, 106 + beam * 178, 502, 68, 3, beam % 2 ? "#5b9eb1" : "#b65294")
                        rect(c, 117 + beam * 178, 560, 40, 2, beam % 2 ? "#5b9eb1" : "#b65294")
                    }
                }

                for (var mote = 0; mote < 11; ++mote) {
                    var moteX = (mote * 149 + spriteFrame * (stageId === 2 ? 2 : 1)) % 950 + 25
                    var moteY = 350 + (mote * 71 + spriteFrame * 3) % 300
                    var moteColor = stageId === 1 ? "#91d87e"
                        : stageId === 2 ? "#b777ea"
                        : stageId === 3 ? (mote % 2 ? "#53dce2" : "#ed6ab0")
                        : stageId === 4 ? (mote % 2 ? "#dc826e" : "#d8c0a3")
                        : "#e2b56f"
                    glow(c, moteX, moteY, stageId === 2 ? 14 : 9, moteColor)
                    rect(c, moteX, moteY, 2, 2, moteColor)
                }

                if (stageId === 0) {
                    rect(c, 488, 531, 24, 132, "#bbb099")
                    rect(c, 500, 531, 3, 132, "#e0d6b8")
                    for (var stripe = 0; stripe < 5; ++stripe)
                        rect(c, 496, 544 + stripe * 24, 12, 8, "#333239")
                } else if (stageId === 4) {
                    for (var bone = 0; bone < 13; ++bone) {
                        var boneX = (bone * 83 + 29) % 940 + 30
                        var boneY = 536 + (bone * 57) % 125
                        rect(c, boneX, boneY, 31, 4, "#c8b7a0")
                        rect(c, boneX + 3, boneY - 5, 5, 8, "#e0d0b8")
                        rect(c, boneX + 25, boneY - 5, 5, 8, "#e0d0b8")
                        if (bone % 3 === 0) grave(c, boneX + 48, boneY + 3, bone % 2)
                    }
                }

                rect(c, 22, 22, 956, 2, "#44404a")
                rect(c, 22, 676, 956, 2, "#44404a")
                rect(c, 22, 22, 2, 656, "#44404a")
                rect(c, 976, 22, 2, 656, "#44404a")
                rect(c, 31, 31, 938, 1, "#282c38")
                rect(c, 31, 668, 938, 1, "#282c38")
            }
            function elementColor(element) {
                if (element === 1) return "#ff824f"
                if (element === 2) return "#74dcff"
                if (element === 3) return "#ffe370"
                if (element === 4) return "#c596ff"
                return "#ffe7a0"
            }
            function bossSprite(c, x, y, kind, depthY) {
                if (depthY === undefined) depthY = y
                var bossColor = kind === 0 ? "#da6578" : kind === 1 ? "#b18455"
                    : kind === 2 ? "#ac67dc" : kind === 3 ? "#f06faf" : "#d77b68"
                c.save()
                c.translate(Math.round(x), Math.round(y))
                var bossDepth = depthScale(depthY)
                groundShadow(c, 0, kind === 4 ? 55 : 38,
                             kind === 4 ? 75 : 44, kind === 4 ? 18 : 12, bossColor)
                c.scale(bossDepth, bossDepth)
                c.translate(0, spriteFrame % 4 < 2 ? -2 : 2)
                if (kind === 4) c.scale(2.25, 2.25)
                glow(c, 0, 0, (kind === 4 ? 106 : 78) + spriteFrame % 4 * 3, bossColor)
                rect(c, -34, 30, 68, 11, "#11121a")
                if (kind === 0) {
                    polygon(c, [-35, -1, -56, -28, -50, 5, -63, 23, -35, 18,
                                -23, 35, 23, 35, 35, 18, 63, 23, 50, 5, 56, -28, 35, -1],
                            "#573d62")
                    rect(c, -28, -24, 56, 53, "#523b59")
                    polygon(c, [-29, -23, -24, -45, -14, -35, -2, -46,
                                11, -35, 24, -45, 29, -23], "#c27771")
                    rect(c, -17, -10, 10, 9, "#ffcb79")
                    rect(c, 8, -10, 10, 9, "#ffcb79")
                    rect(c, -10, 12, 20, 6, "#201c2b")
                } else if (kind === 1) {
                    rect(c, -9, -53, 18, 26, "#564431")
                    rect(c, -38, -31, 76, 57, "#4e4936")
                    rect(c, -22, -24, 13, 14, "#f5be62")
                    rect(c, 9, -24, 13, 14, "#f5be62")
                    rect(c, -17, 7, 34, 7, "#302a2b")
                    rect(c, -47, -25, 10, 49, "#745a41")
                    rect(c, 37, -25, 10, 49, "#745a41")
                    rect(c, -27, 24, 13, 16, "#443c31")
                    rect(c, 14, 24, 13, 16, "#443c31")
                    rect(c, -4, -60, 8, 8, "#99a65b")
                } else if (kind === 2) {
                    polygon(c, [-42, -24, -31, -45, -10, -37, 0, -57,
                                19, -36, 36, -45, 43, -19, 34, 35, 18, 48,
                                -22, 43, -37, 24], "#553d69")
                    polygon(c, [-32, -25, -13, -38, -2, -17, 20, -35,
                                31, -11, 25, 30, -23, 33], "#9565ae")
                    rect(c, -22, -5, 13, 11, "#bbf2ff")
                    rect(c, 10, -5, 13, 11, "#bbf2ff")
                    polygon(c, [-8, 9, 0, 17, 8, 9], "#34243e")
                    polygon(c, [-21, 33, -29, 52, -9, 49, 0, 38,
                                12, 50, 29, 51, 22, 31], "#473251")
                } else if (kind === 4) {
                    polygon(c, [-38, -20, -27, -49, -10, -33, 0, -62,
                                13, -35, 31, -53, 40, -19, 34, 36,
                                18, 56, -19, 56, -37, 34], "#614447")
                    polygon(c, [-29, -17, -16, -35, 0, -24, 17, -38,
                                30, -15, 26, 28, 12, 45, -15, 45, -29, 26], "#c1a28d")
                    for (var rib = 0; rib < 4; ++rib) {
                        c.beginPath()
                        c.moveTo(-22, -9 + rib * 11)
                        c.quadraticCurveTo(0, 2 + rib * 11, 22, -9 + rib * 11)
                        c.strokeStyle = "#725b57"
                        c.lineWidth = 5
                        c.stroke()
                    }
                    rect(c, -19, -10, 12, 10, "#ff6d68")
                    rect(c, 7, -10, 12, 10, "#ff6d68")
                    polygon(c, [-9, 19, 0, 10, 9, 19, 0, 29], "#472f38")
                    polygon(c, [-34, -18, -57, -43, -48, 3, -64, 26, -32, 30], "#92766d")
                    polygon(c, [34, -18, 57, -43, 48, 3, 64, 26, 32, 30], "#92766d")
                    rect(c, -42, 43, 22, 9, "#564348")
                    rect(c, 20, 43, 22, 9, "#564348")
                } else {
                    rect(c, -42, -28, 84, 54, "#602b62")
                    rect(c, -34, -42, 68, 24, "#d46eaa")
                    rect(c, -28, -24, 16, 13, "#fff09a")
                    rect(c, 12, -24, 16, 13, "#fff09a")
                    rect(c, -10, 5, 20, 6, "#331f42")
                    rect(c, -55, -17, 13, 11, "#43cdd0")
                    rect(c, 42, -17, 13, 11, "#ed579d")
                    rect(c, -34, 26, 17, 16, "#3e3056")
                    rect(c, 17, 26, 17, 16, "#3e3056")
                    rect(c, -5, -53, 10, 12, "#56e2dc")
                    rect(c, -3, -50, 6, 6, "#ffefd1")
                }
                c.restore()
            }
            function bossHealthBar(c, boss, stageNumber) {
                var width = stageNumber === 5 ? 220 : 170
                var labelY = Math.max(34, boss.y - (stageNumber === 5 ? 153 : 78))
                c.save()
                c.textAlign = "center"
                c.textBaseline = "bottom"
                c.font = "bold 12px monospace"
                c.fillStyle = "#fff0db"
                c.fillText(win.bossName(stageNumber), boss.x, labelY)
                c.fillStyle = "#261c25"
                c.fillRect(boss.x - width / 2, labelY + 4, width, 10)
                c.fillStyle = "#e3546d"
                c.fillRect(boss.x - width / 2, labelY + 4,
                           width * Math.max(0, boss.health) / Math.max(1, boss.maxHealth), 10)
                c.strokeStyle = "#f4b0a7"
                c.lineWidth = 1
                c.strokeRect(boss.x - width / 2, labelY + 4, width, 10)
                c.restore()
            }
            function subBossHealthBar(c, boss, stageNumber) {
                var width = 176
                var labelY = Math.max(38, boss.y - 56)
                c.save()
                c.textAlign = "center"
                c.textBaseline = "bottom"
                c.font = "bold 10px monospace"
                c.fillStyle = "#a9fff4"
                c.fillText(win.subBossName(stageNumber), boss.x, labelY)
                c.fillStyle = "#142426"
                c.fillRect(boss.x - width / 2, labelY + 4, width, 7)
                c.fillStyle = "#56d9d1"
                c.fillRect(boss.x - width / 2, labelY + 4,
                           width * Math.max(0, boss.health) / Math.max(1, boss.maxHealth), 7)
                c.strokeStyle = "#c0fff6"
                c.lineWidth = 1
                c.strokeRect(boss.x - width / 2, labelY + 4, width, 7)
                c.restore()
            }
            function summonSprite(c, summon) {
                var colors = ["#dba4d2", "#ef8f73", "#e6c46f", "#83c7bd", "#a9a0e8", "#e7e2d4"]
                c.save()
                c.translate(Math.round(summon.x), Math.round(summon.y))
                var summonDepth = depthScale(summon.y)
                groundShadow(c, 0, 17, 17, 6, summon.kind === "skeleton" ? "#b8d7c0"
                             : colors[summon.color % colors.length])
                c.scale(summonDepth, summonDepth)
                c.translate(0, spriteFrame % 4 < 2 ? -2 : 1)
                if (summon.kind === "skeleton") {
                    glow(c, 0, 0, 21, "#b8d7c0")
                    rect(c, -7, -13, 14, 12, "#dce6d5")
                    rect(c, -5, -9, 3, 3, "#54394c")
                    rect(c, 3, -9, 3, 3, "#54394c")
                    rect(c, -5, -1, 10, 3, "#9daea1")
                    rect(c, -7, 2, 14, 10, "#697d76")
                    for (var rib = 0; rib < 3; ++rib)
                        rect(c, -5, 4 + rib * 3, 10, 1, "#d5e0d1")
                    rect(c, -11, 3 + spriteFrame % 4, 4, 9, "#dce6d5")
                    rect(c, 7, 3 - spriteFrame % 4, 4, 9, "#dce6d5")
                    rect(c, -6, 12, 4, 6, "#dce6d5")
                    rect(c, 2, 12, 4, 6, "#dce6d5")
                    rect(c, 11, -7, 2, 19, "#a89a7f")
                    polygon(c, [7, -7, 12, -16, 17, -7], "#c8d3c8")
                } else {
                    c.save()
                    c.scale(0.78, 0.78)
                    var fur = colors[summon.color % colors.length]
                    glow(c, 0, 0, 23, fur)
                    polygon(c, [-13, -7, -12, -18, -4, -12, 2, -15,
                                12, -12, 15, -3, 12, 9, 4, 14, -8, 11, -15, 4], fur)
                    polygon(c, [-12, -12, -15, -23, -5, -17], fur)
                    polygon(c, [5, -16, 14, -22, 12, -10], fur)
                    rect(c, -8, -5, 4, 4, "#292337")
                    rect(c, 5, -5, 4, 4, "#292337")
                    polygon(c, [-2, 1, 1, 1, 0, 4], "#df7891")
                    rect(c, -8, 8, 5, 7, "#e9d8c8")
                    rect(c, 4, 8, 5, 7, "#e9d8c8")
                    c.beginPath()
                    c.moveTo(-12, 5)
                    c.quadraticCurveTo(-24, -4 + spriteFrame % 4 * 2, -18, -13)
                    c.strokeStyle = fur
                    c.lineWidth = 4
                    c.stroke()
                    rect(c, -15, -3, 4, 1, "#fff0d4")
                    rect(c, 11, -3, 4, 1, "#fff0d4")
                    c.restore()
                }
                var life = Math.max(0, Math.min(1, summon.health / Math.max(1, summon.maxHealth)))
                c.fillStyle = "#201823"
                c.fillRect(-11, 22, 22, 3)
                c.fillStyle = life > 0.55 ? "#78d39a" : life > 0.25 ? "#e6bb67" : "#eb647b"
                c.fillRect(-10, 23, 20 * life, 1)
                c.restore()
            }
            function creature(c, x, y, kind, classId, stageId) {
                c.save()
                c.translate(Math.round(x), Math.round(y))
                var actorDepth = depthScale(y)
                groundShadow(c, 0, 17, kind === 3 ? 19 : 17, 7,
                             kind === 3 ? classColor(classId) : "#d3b07b")
                c.scale(actorDepth, actorDepth)
                if (kind === 3) {
                    c.translate(0, spriteFrame % 4 < 2 ? -1 : 1)
                    hero(c, classId)
                    c.restore()
                    return
                }
                if (stageId !== undefined) {
                    var bounce = spriteFrame % 4 < 2 ? -2 : 1
                    var eye = spriteFrame % 8 === 0 ? "#fff6ca" : "#ffd878"
                    c.translate(0, bounce)
                    if (stageId === 0) {
                        if (kind === 0) {
                            rect(c, -14, -12, 28, 27, "#65716a")
                            rect(c, -18, -16, 36, 7, "#899085")
                            rect(c, -10, -5, 7, 6, eye)
                            rect(c, 4, -5, 7, 6, eye)
                            rect(c, -7, 5, 14, 4, "#242932")
                            rect(c, -11, 14, 7, 8, "#3d4743")
                            rect(c, 4, 14, 7, 8, "#3d4743")
                            rect(c, -20, -3, 5, 13, "#a17c55")
                            rect(c, 15, -3, 5, 13, "#a17c55")
                            rect(c, -8, -20, 16, 4, "#c2a16b")
                        } else if (kind === 1) {
                            polygon(c, [-17, 7, -25, -5, -17, -4, -12, -16, -3, -10,
                                        7, -16, 14, -6, 23, -8, 15, 5, 12, 15, 0, 19, -12, 15],
                                    "#564a44")
                            rect(c, -8, -7, 5, 4, eye)
                            rect(c, 4, -7, 5, 4, eye)
                            rect(c, -4, 2, 9, 3, "#201d24")
                            c.beginPath()
                            c.moveTo(-14, 8)
                            c.lineTo(-25, 16 + (spriteFrame % 4))
                            c.lineTo(-31, 14)
                            c.strokeStyle = "#98745b"
                            c.lineWidth = 3
                            c.stroke()
                            rect(c, -7, 15, 5, 7, "#38353b")
                            rect(c, 4, 15, 5, 7, "#38353b")
                        } else {
                            polygon(c, [-18, -10, -10, -18, 0, -13, 11, -18,
                                        20, -7, 17, 12, 7, 19, -11, 17, -20, 7], "#4b5c42")
                            polygon(c, [-7, -15, 0, -27, 8, -15], "#728653")
                            rect(c, -11, -4, 7, 7, eye)
                            rect(c, 5, -4, 7, 7, eye)
                            rect(c, -6, 8, 13, 4, "#1c2623")
                            rect(c, -16, 3, 4, 9, "#91a764")
                            rect(c, 12, 3, 4, 9, "#91a764")
                        }
                    } else if (stageId === 1) {
                        if (kind === 0) {
                            rect(c, -5, -23, 10, 10, "#e0bd79")
                            rect(c, -12, -13, 24, 21, "#b3945c")
                            rect(c, -19, -10, 38, 4, "#675742")
                            polygon(c, [-11, -21, 0, -30, 11, -21], "#584d3a")
                            rect(c, -7, -7, 4, 5, eye)
                            rect(c, 3, -7, 4, 5, eye)
                            rect(c, -5, 2, 10, 3, "#372d29")
                            rect(c, -23, -8, 6, 20, "#987f54")
                            rect(c, 17, -8, 6, 20, "#987f54")
                            rect(c, -19, 10, 5, 10, "#c3a36a")
                            rect(c, 14, 10, 5, 10, "#c3a36a")
                            rect(c, -10, 8, 5, 8, "#645642")
                            rect(c, 5, 8, 5, 8, "#645642")
                        } else if (kind === 1) {
                            polygon(c, [-15, 14, -18, -3, -10, -13, 0, -17,
                                        12, -11, 18, 1, 13, 15], "#476b47")
                            polygon(c, [-14, 0, -26, -10 - spriteFrame % 4, -20, 7], "#73975b")
                            polygon(c, [14, 0, 26, -10 + spriteFrame % 4, 20, 7], "#73975b")
                            rect(c, -9, -5, 6, 5, eye)
                            rect(c, 4, -5, 6, 5, eye)
                            rect(c, -5, 5, 10, 3, "#26342b")
                            polygon(c, [-6, -17, 0, -27, 7, -17], "#9a7951")
                            rect(c, -9, 14, 6, 7, "#394d38")
                            rect(c, 4, 14, 6, 7, "#394d38")
                        } else {
                            rect(c, -14, -12, 28, 27, "#b75b42")
                            rect(c, -10, -16, 20, 6, "#d18854")
                            polygon(c, [-4, -14, 0, -28, 8, -17], "#677e45")
                            rect(c, -9, -5, 6, 7, eye)
                            rect(c, 4, -5, 6, 7, eye)
                            rect(c, -8, 7, 16, 4, "#422b2e")
                            rect(c, -18, -4, 5, 12, "#82513d")
                            rect(c, 13, -4, 5, 12, "#82513d")
                        }
                    } else if (stageId === 2) {
                        if (kind === 0) {
                            var wing = spriteFrame % 4 < 2 ? 18 : 10
                            polygon(c, [-5, -2, -15, -wing, -28, -wing - 4,
                                        -20, 4, -27, 14, -9, 9], "#56426e")
                            polygon(c, [5, -2, 15, -wing, 28, -wing - 4,
                                        20, 4, 27, 14, 9, 9], "#56426e")
                            rect(c, -7, -8, 14, 19, "#8c68b4")
                            rect(c, -5, -4, 3, 4, eye)
                            rect(c, 2, -4, 3, 4, eye)
                            polygon(c, [-4, 7, 0, 14, 4, 7], "#c989dc")
                        } else if (kind === 1) {
                            polygon(c, [-13, 12, -17, -6, -8, -16, 0, -23,
                                        10, -14, 16, 1, 11, 14], "#554269")
                            rect(c, -10, -5, 6, 7, "#b6f3ff")
                            rect(c, 4, -5, 6, 7, "#b6f3ff")
                            polygon(c, [-4, 6, 0, 12, 4, 6], "#a981d0")
                            rect(c, -16, 4, 4, 9, "#9a74c4")
                            rect(c, 12, 4, 4, 9, "#9a74c4")
                        } else {
                            polygon(c, [-19, -8, -11, -19, -4, -13, 2, -24,
                                        11, -14, 19, -17, 22, -4, 16, 15, 7, 20,
                                        -12, 17, -21, 4], "#5c4a70")
                            polygon(c, [-12, -7, -3, -15, 3, -5, 12, -13,
                                        15, 0, 9, 12, -11, 11], "#8f74aa")
                            rect(c, -10, -3, 6, 5, "#a9f3ff")
                            rect(c, 5, -3, 6, 5, "#a9f3ff")
                            rect(c, -4, 6, 9, 3, "#342b40")
                            rect(c, -16, 15, 8, 8, "#68547d")
                            rect(c, 8, 15, 8, 8, "#68547d")
                        }
                    } else {
                        if (kind === 0) {
                            polygon(c, [-14, -10, -8, -17, 8, -17, 15, -8,
                                        13, 12, 5, 18, -8, 18, -16, 10], "#4d3970")
                            rect(c, -9, -5, 6, 6, "#57e7e0")
                            rect(c, 4, -5, 6, 6, "#ff80c8")
                            rect(c, -5, 6, 10, 3, "#211f3a")
                            rect(c, -20, -7, 4, 15, "#3b3261")
                            rect(c, 16, -7, 4, 15, "#3b3261")
                            rect(c, -11, 17, 6, 6, "#40c6c5")
                            rect(c, 5, 17, 6, 6, "#ea5baf")
                        } else if (kind === 1) {
                            c.beginPath()
                            c.arc(0, 1, 16, Math.PI, Math.PI * 2)
                            c.lineTo(15, 12)
                            c.lineTo(7, 8 + spriteFrame % 4)
                            c.lineTo(0, 15)
                            c.lineTo(-7, 8 - spriteFrame % 4)
                            c.lineTo(-15, 12)
                            c.closePath()
                            c.fillStyle = "#544178"
                            c.fill()
                            rect(c, -10, -2, 6, 6, "#ff90cb")
                            rect(c, 4, -2, 6, 6, "#60e8df")
                            rect(c, -4, 7, 8, 3, "#29203d")
                            rect(c, -5, 17, 10, 3, "#a260b4")
                        } else {
                            rect(c, -16, -13, 32, 29, "#393d70")
                            rect(c, -12, -19, 24, 9, "#7262a5")
                            rect(c, -10, -5, 7, 7, "#fff09b")
                            rect(c, 4, -5, 7, 7, "#fff09b")
                            rect(c, -7, 6, 14, 4, "#211e3a")
                            rect(c, -23, -5, 7, 18, "#4fd2d0")
                            rect(c, 16, -5, 7, 18, "#ed5eaf")
                            rect(c, -11, 16, 7, 7, "#34365f")
                            rect(c, 4, 16, 7, 7, "#34365f")
                        }
                    }
                    c.restore()
                    return
                }
                if (kind === 0) {
                    polygon(c, [-5, -1, -25, -14, -20, 1, -26, 8, -11, 5,
                                -5, 10, 5, 10, 11, 5, 26, 8, 20, 1, 25, -14, 5, -1], "#5c426f")
                    rect(c, -5, -8, 10, 17, "#8e68aa")
                    rect(c, -3, -4, 3, 4, "#ffcb79")
                    rect(c, 2, -4, 3, 4, "#ffcb79")
                    rect(c, -4, 1, 8, 3, "#392844")
                    rect(c, -12, 8, 6, 5, "#44344f")
                    rect(c, 6, 8, 6, 5, "#44344f")
                } else if (kind === 1) {
                    rect(c, -12, -10, 24, 19, "#a8bdc2")
                    rect(c, -9, -14, 18, 7, "#d6e5d9")
                    rect(c, -10, -2, 5, 6, "#252c39")
                    rect(c, 5, -2, 5, 6, "#252c39")
                    rect(c, -8, -1, 2, 2, "#d5f8df")
                    rect(c, 7, -1, 2, 2, "#d5f8df")
                    rect(c, -7, 8, 5, 8, "#7e9b9e")
                    rect(c, 2, 8, 5, 8, "#7e9b9e")
                    rect(c, -3, 7, 6, 3, "#39424d")
                } else {
                    rect(c, -4, -15, 8, 7, "#79834b")
                    rect(c, -12, -10, 24, 21, "#a95335")
                    rect(c, -15, -5, 4, 12, "#8d452f")
                    rect(c, 11, -5, 4, 12, "#8d452f")
                    rect(c, -7, -5, 5, 6, "#ffdb86")
                    rect(c, 2, -5, 5, 6, "#ffdb86")
                    rect(c, -9, 4, 18, 4, "#392834")
                    rect(c, -6, 4, 3, 3, "#f2c37b")
                    rect(c, 0, 4, 3, 3, "#f2c37b")
                    rect(c, 6, 4, 3, 3, "#f2c37b")
                }
                c.restore()
            }

            onPaint: {
                if (!visible || !available) return
                var c = getContext("2d")
                if (!c) return
                var stageNumber = backend.stage
                var playerX = backend.playerX
                var playerY = backend.playerY
                var heroClassName = backend.heroClass
                var activeElementId = backend.activeElement
                var magnetTime = backend.magnetTime
                var gemsData = backend.gems
                var dropsData = backend.drops
                var projectilesData = backend.projectiles
                var beamsData = backend.enemyBeams
                var particlesData = backend.particles
                var enemiesData = backend.enemies
                var summonsData = backend.summons
                var attackEffectsData = backend.attackEffects
                var subBossData = backend.subBoss
                var bossData = backend.boss
                c.reset()
                c.clearRect(0, 0, width, height)
                c.scale(width / 1000, height / 700)
                if (activeElementId !== "arcane")
                    glow(c, playerX, playerY, 62, elementColor(activeElementId === "fire" ? 1
                         : activeElementId === "ice" ? 2 : activeElementId === "lightning" ? 3 : 4))

                for (var g = 0; g < gemsData.length; ++g) {
                    var gem = gemsData[g]
                    rect(c, gem.x - 8, gem.y - 2, 16, 4, "#315d5a")
                    polygon(c, [gem.x, gem.y - 9, gem.x + 7, gem.y, gem.x, gem.y + 9,
                                gem.x - 7, gem.y], "#59d5bd")
                    polygon(c, [gem.x, gem.y - 5, gem.x + 3, gem.y, gem.x, gem.y + 5], "#c0ffdd")
                }
                for (var d = 0; d < dropsData.length; ++d) {
                    var drop = dropsData[d]
                    var dropY = drop.y + (spriteFrame % 4 < 2 ? -2 : 2)
                    var dropColor = drop.type === "speed" ? "#70e8bb"
                        : drop.type === "fireRate" ? "#81ceff" : "#f15e72"
                    glow(c, drop.x, dropY, 29 + spriteFrame % 3 * 2, dropColor)
                    c.save()
                    c.translate(Math.round(drop.x), Math.round(dropY))
                    if (drop.type === "speed") {
                        polygon(c, [-13, 0, -3, -10, -3, -4, 12, -4,
                                    12, 4, -3, 4, -3, 10], "#70e8bb")
                        rect(c, -2, -2, 11, 2, "#e5fff2")
                    } else if (drop.type === "fireRate") {
                        rect(c, -11, -7, 17, 4, "#81ceff")
                        polygon(c, [6, -7, 12, -5, 6, -3], "#d9f7ff")
                        rect(c, -11, 3, 17, 4, "#81ceff")
                        polygon(c, [6, 3, 12, 5, 6, 7], "#d9f7ff")
                    } else {
                        polygon(c, [-13, -7, -9, -15, -3, -10, 3, -10,
                                    9, -15, 13, -7, 12, 8, 6, 13, -6, 13, -12, 8], "#f15e72")
                        rect(c, -8, -3, 5, 5, "#fff0cd")
                        rect(c, 4, -3, 5, 5, "#fff0cd")
                        rect(c, -5, 6, 10, 3, "#551f37")
                    }
                    c.restore()
                }
                for (var p = 0; p < projectilesData.length; ++p) {
                    var shot = projectilesData[p]
                    var shotColor = elementColor(shot.element)
                    if (shot.heroClass === 1) {
                        c.beginPath()
                        c.arc(shot.x, shot.y, 10, 0, Math.PI * 2)
                        c.fillStyle = shotColor
                        c.fill()
                        polygon(c, [shot.x - 11, shot.y, shot.x, shot.y - 14,
                                    shot.x + 11, shot.y, shot.x, shot.y + 14], "#ddc9ff")
                        c.beginPath()
                        c.arc(shot.x - 2, shot.y - 2, 3, 0, Math.PI * 2)
                        c.fillStyle = "#fff6dc"
                        c.fill()
                    } else if (shot.heroClass === 3) {
                        c.save()
                        c.translate(shot.x, shot.y)
                        c.rotate(Math.atan2(shot.vy, shot.vx))
                        c.shadowColor = shotColor
                        c.shadowBlur = 12
                        c.beginPath()
                        c.moveTo(-15, 0)
                        c.lineTo(1, 0)
                        c.strokeStyle = shotColor
                        c.lineWidth = 3
                        c.stroke()
                        c.beginPath()
                        c.arc(4, 0, 3.5, 0, Math.PI * 2)
                        c.fillStyle = "#fff1a8"
                        c.fill()
                        c.strokeStyle = "#c68e2e"
                        c.lineWidth = 1
                        c.stroke()
                        c.shadowBlur = 0
                        c.restore()
                    } else {
                        c.save()
                        c.translate(shot.x, shot.y)
                        c.rotate(Math.atan2(shot.vy, shot.vx))
                        rect(c, -21, -1, 29, 2, "#d5c9a6")
                        polygon(c, [9, 0, -1, -5, 0, 0, -1, 5], shotColor)
                        polygon(c, [-19, -1, -23, -5, -17, -2], "#f3d9a0")
                        polygon(c, [-19, 1, -23, 5, -17, 2], "#f3d9a0")
                        c.restore()
                    }
                }
                for (var beamIndex = 0; beamIndex < beamsData.length; ++beamIndex) {
                    var beam = beamsData[beamIndex]
                    var warning = beam.delay > 0
                    var alpha = warning ? 0.30 + (spriteFrame % 4) * 0.10 : 0.92
                    var beamColor = beam.kind === 0 ? "#ff805b" : beam.kind === 1 ? "#efc86b"
                        : beam.kind === 2 ? "#bb86ff" : beam.kind === 3 ? "#ef62b8" : "#b8f5ff"
                    var dx = beam.x2 - beam.x1
                    var dy = beam.y2 - beam.y1
                    var length = Math.sqrt(dx * dx + dy * dy) || 1
                    var nx = -dy / length
                    var ny = dx / length
                    c.save()
                    c.globalAlpha = alpha
                    c.beginPath()
                    c.moveTo(beam.x1, beam.y1)
                    for (var bolt = 1; bolt < 7; ++bolt) {
                        var progress = bolt / 7
                        var side = bolt % 2 ? 9 : -9
                        c.lineTo(beam.x1 + dx * progress + nx * side,
                                 beam.y1 + dy * progress + ny * side)
                    }
                    c.lineTo(beam.x2, beam.y2)
                    c.strokeStyle = beamColor
                    c.globalAlpha = alpha * 0.2
                    c.lineWidth = warning ? 15 : 20
                    c.stroke()
                    c.globalAlpha = alpha
                    c.strokeStyle = beamColor
                    c.lineWidth = warning ? 5 : 8
                    c.stroke()
                    c.strokeStyle = "#eaffff"
                    c.lineWidth = warning ? 1.5 : 2.5
                    c.stroke()
                    if (warning) {
                        c.beginPath()
                        c.arc(beam.x2, beam.y2, 16 + spriteFrame % 3 * 2, 0, Math.PI * 2)
                        c.fillStyle = beamColor
                        c.globalAlpha = 0.14 + (spriteFrame % 4) * 0.04
                        c.fill()
                        c.beginPath()
                        c.arc(beam.x2, beam.y2, 13 + spriteFrame % 3 * 2, 0, Math.PI * 2)
                        c.strokeStyle = beamColor
                        c.globalAlpha = 0.82
                        c.lineWidth = 2
                        c.stroke()
                    } else {
                        c.beginPath()
                        c.arc(beam.x2, beam.y2, 4, 0, Math.PI * 2)
                        c.fillStyle = "#fff4dc"
                        c.fill()
                    }
                    c.restore()
                }
                for (var fx = 0; fx < particlesData.length; ++fx) {
                    var particle = particlesData[fx]
                    c.globalAlpha = Math.max(0, particle.life / particle.maxLife)
                    if (particle.kind === 1) {
                        polygon(c, [particle.x, particle.y - particle.size * 2,
                                    particle.x + particle.size, particle.y,
                                    particle.x, particle.y + particle.size * 2,
                                    particle.x - particle.size, particle.y], particle.color)
                    } else {
                        rect(c, particle.x, particle.y, particle.size, particle.size, particle.color)
                    }
                    c.globalAlpha = 1
                }
                var depthActors = []
                for (var e = 0; e < enemiesData.length; ++e)
                    depthActors.push({"y": enemiesData[e].y, "type": "enemy", "data": enemiesData[e]})
                for (var summonIndex = 0; summonIndex < summonsData.length; ++summonIndex)
                    depthActors.push({"y": summonsData[summonIndex].y,
                                      "type": "summon", "data": summonsData[summonIndex]})
                for (var attack = 0; attack < attackEffectsData.length; ++attack) {
                    var effect = attackEffectsData[attack]
                    var progress = 1 - effect.life / effect.maxLife
                    var effectColor = effect.element === 1 ? "#ff824f"
                        : effect.element === 2 ? "#74dcff"
                        : effect.element === 3 ? "#ffe370"
                        : effect.element === 4 ? "#c596ff"
                        : effect.kind === 5 ? "#ffd970"
                        : effect.kind === 0 ? "#f5d477"
                        : effect.kind === 1 ? "#c39aff" : "#b7f5cb"
                    c.globalAlpha = Math.max(0, 1 - progress * 0.72)
                    if (effect.kind === 0) {
                        c.beginPath()
                        c.arc(effect.x, effect.y, effect.range * (0.62 + progress * 0.38),
                              0, Math.PI * 2)
                        c.strokeStyle = effectColor
                        c.lineWidth = 12 * (1 - progress) + 3
                        c.stroke()
                        c.beginPath()
                        c.arc(effect.x, effect.y, effect.range * 0.82,
                              spriteFrame * 0.22, spriteFrame * 0.22 + Math.PI * 1.45)
                        c.strokeStyle = "#fff1bd"
                        c.lineWidth = 4
                        c.stroke()
                    } else if (effect.kind === 1) {
                        var blast = effect.range * progress
                        var blastGlow = c.createRadialGradient(effect.x, effect.y, 1,
                                                               effect.x, effect.y, Math.max(1, blast))
                        blastGlow.addColorStop(0, "#eee0ff")
                        blastGlow.addColorStop(0.35, "#ba8aff")
                        blastGlow.addColorStop(1, "rgba(133, 77, 210, 0)")
                        c.beginPath()
                        c.arc(effect.x, effect.y, blast, 0, Math.PI * 2)
                        c.fillStyle = blastGlow
                        c.fill()
                        c.beginPath()
                        c.arc(effect.x, effect.y, blast, 0, Math.PI * 2)
                        c.strokeStyle = "#e7d8ff"
                        c.lineWidth = 3
                        c.stroke()
                    } else if (effect.kind === 2) {
                        var arrowLength = effect.range * (0.35 + progress * 0.65)
                        var endX = effect.x + Math.cos(effect.angle) * arrowLength
                        var endY = effect.y + Math.sin(effect.angle) * arrowLength
                        c.beginPath()
                        c.moveTo(effect.x, effect.y)
                        c.lineTo(endX, endY)
                        c.strokeStyle = effectColor
                        c.lineWidth = 5 * (1 - progress) + 1
                        c.stroke()
                    } else if (effect.kind === 5) {
                        c.save()
                        c.translate(effect.x, effect.y)
                        c.rotate(effect.angle)
                        c.shadowColor = effectColor
                        c.shadowBlur = 14
                        c.fillStyle = "#fff0a8"
                        c.beginPath()
                        c.arc(3, 0, 7 * (1 - progress * 0.35), 0, Math.PI * 2)
                        c.fill()
                        c.strokeStyle = effectColor
                        c.lineWidth = 3
                        c.beginPath()
                        c.moveTo(-3, 0)
                        c.lineTo(13 + progress * 13, 0)
                        c.stroke()
                        c.shadowBlur = 0
                        c.restore()
                    } else {
                        c.save()
                        c.translate(effect.x, effect.y)
                        c.rotate(effect.angle)
                        c.strokeStyle = effect.element > 0 ? effectColor
                            : effect.kind === 3 ? "#dce6d5" : "#ffd5e6"
                        c.shadowColor = c.strokeStyle
                        c.shadowBlur = effect.element > 0 ? 14 : 0
                        c.lineWidth = effect.kind === 3 ? 5 : 3
                        c.beginPath()
                        if (effect.kind === 3) {
                            c.moveTo(-20, -12)
                            c.quadraticCurveTo(0, 3, 20, -12)
                            c.moveTo(-15, -3)
                            c.quadraticCurveTo(0, 12, 15, -3)
                        } else {
                            c.moveTo(-16, -12)
                            c.lineTo(13, 7)
                            c.moveTo(-12, -16)
                            c.lineTo(17, 3)
                            c.moveTo(-18, -6)
                            c.lineTo(11, 13)
                        }
                        c.stroke()
                        c.shadowBlur = 0
                        c.restore()
                    }
                    c.globalAlpha = 1
                }
                var stageSubBoss = subBossData
                var stageBoss = bossData
                if (stageSubBoss.active)
                    depthActors.push({"y": stageSubBoss.y, "type": "subBoss", "data": stageSubBoss})
                if (stageBoss.active) {
                    for (var echoIndex = 0; echoIndex < stageBoss.echoes.length; ++echoIndex) {
                        var echo = stageBoss.echoes[echoIndex]
                        c.save()
                        c.globalAlpha = 0.62
                        c.translate(echo.x, echo.y)
                        c.scale(0.42, 0.42)
                        bossSprite(c, 0, 0, 4, echo.y)
                        c.restore()
                    }
                    depthActors.push({"y": stageBoss.y, "type": "boss", "data": stageBoss})
                }
                depthActors.push({"y": playerY, "type": "hero", "data": {"x": playerX,
                                  "y": playerY, "classId": heroClassName}})
                depthActors.sort(function(a, b) { return a.y - b.y })
                for (var actorIndex = 0; actorIndex < depthActors.length; ++actorIndex) {
                    var actor = depthActors[actorIndex]
                    if (actor.type === "enemy") {
                        var enemy = actor.data
                        if (enemy.burning || enemy.slowed) {
                            c.beginPath()
                            c.arc(enemy.x, enemy.y, 18 * depthScale(enemy.y), 0, Math.PI * 2)
                            c.strokeStyle = enemy.burning ? "#ff824f" : "#74dcff"
                            c.lineWidth = 2
                            c.globalAlpha = 0.82
                            c.stroke()
                            c.globalAlpha = 1
                        }
                        creature(c, enemy.x, enemy.y, enemy.kind, "", stageNumber - 1)
                    } else if (actor.type === "summon") {
                        summonSprite(c, actor.data)
                    } else if (actor.type === "subBoss") {
                        var subBoss = actor.data
                        c.save()
                        c.globalAlpha = 0.9
                        c.scale(0.72, 0.72)
                        bossSprite(c, subBoss.x / 0.72, subBoss.y / 0.72,
                                   stageNumber === 5 ? 2 : stageNumber - 1, subBoss.y)
                        c.restore()
                    } else if (actor.type === "boss") {
                        bossSprite(c, actor.data.x, actor.data.y, actor.data.kind)
                    } else {
                        creature(c, actor.data.x, actor.data.y, 3, actor.data.classId)
                    }
                }
                if (stageSubBoss.active) subBossHealthBar(c, stageSubBoss, stageNumber)
                if (stageBoss.active) bossHealthBar(c, stageBoss, stageNumber)
                if (magnetTime > 0) {
                    var pulse = spriteFrame % 8
                    glow(c, playerX, playerY, 76 + pulse * 3, "#e9c85d")
                    c.save()
                    c.globalAlpha = 0.52 + (pulse % 4) * 0.1
                    c.strokeStyle = "#ffe99a"
                    c.lineWidth = 3
                    c.beginPath()
                    c.arc(playerX, playerY, 40 + pulse * 5,
                          pulse * 0.35, pulse * 0.35 + Math.PI * 1.55)
                    c.stroke()
                    c.strokeStyle = "#d7a93e"
                    c.lineWidth = 2
                    c.beginPath()
                    c.arc(playerX, playerY, 57 + (7 - pulse) * 3,
                          -pulse * 0.3, -pulse * 0.3 + Math.PI * 1.2)
                    c.stroke()
                    c.restore()
                }
            }

            function hero(c, classId) {
                if (classId === "lango") {
                    rect(c, -16, 14, 32, 6, "#12151c")
                    polygon(c, [-17, -2, -15, 17, 0, 21, 17, 16, 13, -5], "#4d5960")
                    rect(c, -10, -17, 20, 17, "#d9d4c3")
                    rect(c, -8, -12, 4, 4, "#54394c")
                    rect(c, 4, -12, 4, 4, "#54394c")
                    rect(c, -6, -4, 12, 3, "#867a70")
                    polygon(c, [-13, -16, -12, -25, -5, -31, 4, -29,
                                13, -22, 12, -14], "#282b36")
                    rect(c, -15, -5, 5, 15, "#3c4651")
                    rect(c, 10, -5, 5, 15, "#3c4651")
                    rect(c, -10, 14, 7, 6, "#b8a78d")
                    rect(c, 3, 14, 7, 6, "#b8a78d")
                    rect(c, 15, -18, 3, 34, "#b8b9a2")
                    polygon(c, [12, -19, 16, -28, 21, -19, 17, -16], "#dce6d5")
                    return
                }
                if (classId === "kalengue") {
                    rect(c, -16, 14, 32, 6, "#12151c")
                    polygon(c, [-14, -3, -17, 16, 0, 21, 16, 15, 13, -4], "#954f72")
                    polygon(c, [-13, -14, -14, -28, -5, -21, 0, -26,
                                7, -21, 15, -28, 13, -11], "#bd8b79")
                    polygon(c, [-13, -14, -11, -25, -4, -20], "#f0a7c7")
                    polygon(c, [6, -20, 14, -25, 13, -14], "#f0a7c7")
                    rect(c, -8, -12, 4, 4, "#343040")
                    rect(c, 4, -12, 4, 4, "#343040")
                    polygon(c, [-3, -5, 1, -5, 0, -2], "#d887a4")
                    rect(c, -12, -3, 5, 15, "#75425e")
                    rect(c, 8, -3, 5, 15, "#75425e")
                    rect(c, -10, 14, 7, 6, "#d5b9a7")
                    rect(c, 3, 14, 7, 6, "#d5b9a7")
                    rect(c, 14, -17, 3, 31, "#d5b67b")
                    polygon(c, [11, -18, 16, -27, 21, -18, 17, -15], "#f3d9a0")
                    return
                }
                if (classId === "mage") {
                    rect(c, -15, 14, 30, 5, "#12151c")
                    polygon(c, [-13, -2, -16, 15, 0, 20, 16, 15, 13, -2], "#534779")
                    rect(c, -11, -15, 22, 16, "#d5b9ab")
                    polygon(c, [-14, -12, -14, -22, -9, -28, 1, -35,
                                9, -27, 16, -24, 13, -12, 8, -8, -8, -8], "#302c4b")
                    rect(c, -8, -8, 16, 4, "#735e96")
                    rect(c, -7, -9, 3, 3, "#5fd7ed")
                    rect(c, 4, -9, 3, 3, "#5fd7ed")
                    rect(c, -6, 2, 12, 4, "#c39a84")
                    rect(c, -12, -1, 4, 12, "#403958")
                    rect(c, 8, -1, 4, 12, "#403958")
                    rect(c, -10, 14, 7, 5, "#b69b78")
                    rect(c, 3, 14, 7, 5, "#b69b78")
                    rect(c, 14, -14, 3, 30, "#ad8861")
                    rect(c, 11, -21, 9, 8, "#9176dc")
                    rect(c, 13, -19, 5, 4, "#c4efff")
                    return
                }
                if (classId === "bronhaman") {
                    glow(c, 0, -3, 30, "#e8ba47")
                    rect(c, -16, 14, 32, 6, "#12151c")
                    polygon(c, [-14, -3, -17, 15, 0, 20, 17, 15, 13, -4], "#775037")
                    rect(c, -11, -18, 22, 16, "#d4a875")
                    rect(c, -8, -12, 4, 3, "#292630")
                    rect(c, 4, -12, 4, 3, "#292630")
                    rect(c, -6, -5, 12, 3, "#aa493f")
                    polygon(c, [-22, -19, -17, -23, -8, -21, 0, -23,
                                9, -21, 18, -23, 23, -19, 8, -17, -8, -17], "#9a7338")
                    rect(c, -7, -31, 14, 12, "#b28743")
                    rect(c, -8, -34, 16, 4, "#e6c46b")
                    rect(c, -12, -1, 5, 14, "#593e34")
                    rect(c, 7, -1, 5, 14, "#593e34")
                    rect(c, -10, 14, 7, 6, "#50382f")
                    rect(c, 3, 14, 7, 6, "#50382f")
                    rect(c, -19, -1, 5, 13, "#b79351")
                    rect(c, 14, -1, 5, 13, "#b79351")
                    rect(c, -23, 5, 8, 4, "#f1d36d")
                    rect(c, 15, 5, 8, 4, "#f1d36d")
                    rect(c, -22, 2, 6, 3, "#fff0a8")
                    rect(c, 16, 2, 6, 3, "#fff0a8")
                    rect(c, -3, 1, 6, 5, "#e8c66b")
                    return
                }
                if (classId === "archer") {
                    rect(c, -15, 14, 30, 5, "#12151c")
                    polygon(c, [-14, -4, -14, 12, 0, 20, 13, 12, 10, -5], "#427451")
                    rect(c, -11, -18, 22, 16, "#d8b991")
                    polygon(c, [-13, -14, -11, -24, 0, -30, 12, -23, 15, -12, 7, -16, 0, -13], "#37583e")
                    rect(c, -7, -12, 3, 3, "#292630")
                    rect(c, 4, -12, 3, 3, "#292630")
                    rect(c, -12, -5, 24, 4, "#c79c63")
                    rect(c, -11, 0, 5, 13, "#35523c")
                    rect(c, 6, 0, 5, 13, "#35523c")
                    rect(c, -10, 14, 7, 5, "#b69b78")
                    rect(c, 3, 14, 7, 5, "#b69b78")
                    c.beginPath()
                    c.arc(15, -2, 13, -Math.PI * 0.47, Math.PI * 0.47)
                    c.strokeStyle = "#d4b77a"
                    c.lineWidth = 3
                    c.stroke()
                    c.beginPath()
                    c.moveTo(6, -11)
                    c.lineTo(22, 7)
                    c.strokeStyle = "#d7d0bc"
                    c.lineWidth = 1
                    c.stroke()
                    return
                }
                rect(c, -15, 14, 30, 5, "#12151c")
                polygon(c, [-14, -2, -18, 17, -8, 20, 0, 15, 8, 20, 18, 16, 13, -3], "#793f48")
                rect(c, -14, -2, 28, 16, "#344557")
                rect(c, -12, -13, 24, 18, "#728392")
                rect(c, -11, -19, 22, 11, "#d6b990")
                rect(c, -13, -23, 26, 8, "#252c40")
                rect(c, -10, -25, 20, 4, "#b39a69")
                rect(c, -8, -15, 4, 3, "#252532")
                rect(c, 4, -15, 4, 3, "#252532")
                rect(c, -5, -8, 10, 2, "#805a54")
                rect(c, -11, -4, 22, 5, "#9d3444")
                rect(c, -12, 3, 5, 12, "#546777")
                rect(c, 7, 3, 5, 12, "#546777")
                rect(c, -10, 13, 7, 5, "#b69b78")
                rect(c, 3, 13, 7, 5, "#b69b78")
                rect(c, 14, -12, 4, 25, "#bbc5c9")
                polygon(c, [11, -12, 16, -21, 22, -12, 17, -9], "#dbe6dd")
                rect(c, 12, 11, 8, 3, "#9a7958")
                rect(c, -3, 1, 6, 6, "#ecd68a")
            }
        }

        World3D {
            id: world3d
            anchors.fill: parent
            anchors.bottomMargin: 88
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 88
            color: "#d20e1522"
            border.color: "#3d4757"
            border.width: 1
            visible: backend.state === "playing" || backend.state === "paused" || backend.state === "gameover" || backend.state === "upgrade"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 46
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 16
                ColumnLayout {
                    Layout.preferredWidth: 178
                    Label {
                        text: qsTr("STAGE %1  ·  NIGHT %2").arg(backend.stage).arg(backend.cycle)
                        color: "#b8b8c5"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.4
                    }
                    Label {
                        text: win.stageName(backend.stage)
                        color: "#f0d98a"
                        font.family: "monospace"
                        font.pixelSize: 13
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }
                    Label {
                        text: backend.boss.active ? qsTr("BOSS IN BATTLE")
                            : backend.subBoss.active ? qsTr("SUBCHEFE EM COMBATE")
                            : !backend.subBossSpawned ? qsTr("SUBCHEFE EM %1s").arg(backend.stageTimeLeft)
                            : qsTr("CHEFE EM %1s").arg(backend.stageTimeLeft)
                        color: backend.boss.active ? "#ff929d"
                            : backend.subBoss.active ? "#86e8de" : "#b8b8c5"
                        font.pixelSize: 10
                    }
                }
                ColumnLayout {
                    Layout.preferredWidth: 174
                    Label { text: qsTr("HEALTH"); color: "#b8b8c5"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.4 }
                    Item {
                        Layout.fillWidth: true
                        height: 9
                        Rectangle { anchors.fill: parent; color: "#3b3541" }
                        Rectangle {
                            width: parent.width * backend.health / backend.maxHealth
                            height: parent.height
                            color: "#d95d70"
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: "#72535d"
                            border.width: 1
                        }
                    }
                    Label { text: Math.ceil(backend.health) + " / " + backend.maxHealth; color: "#e7dce0"; font.pixelSize: 11 }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: qsTr("LEVEL %1").arg(backend.level); color: "#f0d98a"; font.bold: true; font.letterSpacing: 1.2 }
                    Item {
                        Layout.fillWidth: true
                        height: 9
                        Rectangle { anchors.fill: parent; color: "#303942" }
                        Rectangle {
                            width: parent.width * backend.experience / backend.experienceNeeded
                            height: parent.height
                            color: "#5ec9a8"
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: "#4b6a65"
                            border.width: 1
                        }
                    }
                    Label { text: qsTr("%1 / %2 shards").arg(backend.experience).arg(backend.experienceNeeded); color: "#bdc9c5"; font.pixelSize: 11 }
                    Label {
                        text: win.combatStatus()
                        color: backend.speedBoostTime > 0 ? "#70e8bb"
                            : backend.fireRateBoostTime > 0 ? "#81ceff"
                            : backend.activeElement === "fire" ? "#ffac76"
                            : backend.activeElement === "ice" ? "#95e6ff"
                            : backend.activeElement === "lightning" ? "#ffe99b"
                            : backend.activeElement === "shadow" ? "#d2afff" : "#b7b3c0"
                        font.pixelSize: 10
                    }
                }
                ColumnLayout {
                    Label { text: qsTr("TIME"); color: "#b8b8c5"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.4 }
                    Label {
                        text: Math.floor(backend.seconds / 60).toString().padStart(2, "0") + ":" + (backend.seconds % 60).toString().padStart(2, "0")
                        color: "#ffffff"; font.pixelSize: 24; font.bold: true
                    }
                }
                ColumnLayout {
                    Label { text: qsTr("CREATURES"); color: "#b8b8c5"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.2 }
                    Label { text: backend.kills; color: "#ffffff"; font.pixelSize: 24; font.bold: true }
                }
            }
            ToolButton {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 8
                anchors.topMargin: 2
                text: win.soundEnabled ? "♪" : "×"
                font.pixelSize: 24
                ToolTip.visible: hovered
                ToolTip.text: win.soundEnabled ? qsTr("Mute sound (M)") : qsTr("Enable sound (M)")
                onClicked: win.soundEnabled = !win.soundEnabled
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 24
            anchors.horizontalCenter: parent.horizontalCenter
            width: 310
            height: 48
            visible: backend.hordeAlertTime > 0
            color: "#ec391d34"
            border.color: "#f15e72"
            radius: theme.radius
            z: 3
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                Label {
                    Layout.fillWidth: true
                    text: qsTr("SUPER HORDE!")
                    color: "#fff1df"
                    font.pixelSize: 15
                    font.bold: true
                    font.letterSpacing: 1
                }
                Label {
                    text: "☠"
                    color: "#ff8794"
                    font.pixelSize: 23
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width - 80, 460)
            height: win.nightNotice().length > 0 ? 190 : 152
            visible: win.stageBannerVisible && (backend.state === "playing"
                || win.stageTransitionPaused && backend.state === "paused")
            color: "#df111521"
            border.color: theme.accent
            radius: theme.radius
            z: 3
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("STAGE %1  ·  NIGHT %2").arg(backend.stage).arg(backend.cycle)
                    color: "#e6c876"
                    font.pixelSize: 12
                    font.letterSpacing: 2
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: win.stageName(backend.stage)
                    color: "#fff1d2"
                    font.family: "monospace"
                    font.pixelSize: 22
                    font.bold: true
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: win.nightNotice().length > 0
                    text: win.nightNotice()
                    color: backend.cycle === 3 ? "#ff8c77" : "#f0ca61"
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 1
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: win.stageLore(backend.stage)
                    color: "#c5bdc8"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#d90c0e16"
            visible: backend.state === "menu" || backend.state === "paused" && !win.stageTransitionPaused
                || backend.state === "gameover" || backend.state === "victory"

            Rectangle {
                width: Math.min(parent.width - 36, backend.state === "menu" ? 1120 : 510)
                height: backend.state === "menu" ? (win.introVisible ? 470 : 600)
                    : backend.state === "gameover" || backend.state === "victory" ? 380 : 330
                anchors.centerIn: parent
                color: "#f31a1d2a"
                border.color: "#687284"
                border.width: 1
                radius: theme.radius
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 3
                    color: theme.accent
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: backend.state === "menu" ? (win.introVisible ? 32 : 20) : 30
                    spacing: backend.state === "menu" ? 8 : 15
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: backend.state === "menu" ? qsTr("MONGLES DA NOITE")
                            : backend.state === "paused" ? qsTr("PAUSED")
                            : backend.state === "victory" ? qsTr("THE NIGHT IS SAVED") : qsTr("THE NIGHT WON")
                        color: "#f0d98a"
                        font.family: "monospace"
                        font.pixelSize: 29
                        font.letterSpacing: 2
                        font.bold: true
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        visible: backend.state === "menu"
                        text: qsTr("BUILD %1").arg(buildVersion)
                        color: "#c4a86d"
                        font.family: "monospace"
                        font.pixelSize: 12
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: backend.state === "menu" && win.introVisible ? qsTr("THE CITY'S LAST NIGHT")
                            : backend.state === "menu" ? qsTr("A rift beneath the city")
                            : backend.state === "paused" ? qsTr("The graveyard grows quiet for a moment.")
                            : backend.state === "victory" ? qsTr("You defeated the Carcass of Midnight and sealed the rift.")
                            : qsTr("Your next run begins when you are ready.")
                        color: "#bcb8c6"
                        font.pixelSize: 13
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.maximumWidth: 850
                        Layout.alignment: Qt.AlignHCenter
                        text: backend.state === "menu"
                            ? qsTr("When a midnight fissure woke the dead, the city's four districts became a chain of trials. Survive three complete nights to uncover the Vale of Carcasses and face the thing wearing the rift as a body.")
                            : backend.state === "paused" ? qsTr("Take a breath. The night can wait.")
                            : backend.state === "victory" ? qsTr("The city is free of the midnight rift. The legend of your five-stage journey will outlive the ruins.")
                            : qsTr("You survived for %1:%2 and defeated %3 creatures.")
                                .arg(Math.floor(backend.seconds / 60).toString().padStart(2, "0"))
                                .arg((backend.seconds % 60).toString().padStart(2, "0"))
                                .arg(backend.kills)
                        color: "#d4d1dc"
                        font.pixelSize: 16
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        visible: backend.state === "menu" && win.introVisible
                        text: qsTr("Four districts. Four bosses. Survive three nights to reveal the hidden Vale of Carcasses and the rift's true form.")
                        color: "#dbbe75"
                        font.pixelSize: 15
                        font.bold: true
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 148
                        spacing: 10
                        visible: backend.state === "menu" && !win.introVisible
                        Repeater {
                            model: ["warrior", "mage", "archer", "lango", "kalengue", "bronhaman"]
                            delegate: Button {
                                required property string modelData
                                required property int index
                                property string classId: modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                focusPolicy: Qt.StrongFocus
                                onClicked: {
                                    backend.chooseClass(classId)
                                    stage.forceActiveFocus()
                                }
                                background: Rectangle {
                                    color: backend.heroClass === classId ? "#3a3b4c"
                                        : parent.hovered ? "#30313f" : "#232531"
                                    border.color: win.classColor(classId)
                                    border.width: backend.heroClass === classId ? 3 : parent.hovered ? 2 : 1
                                    radius: theme.radius
                                }
                                contentItem: ColumnLayout {
                                    spacing: 4
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "[" + (index + 1) + "]"
                                        color: "#a7a5b2"
                                        font.pixelSize: 11
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: classId === "warrior" ? "⚔"
                                            : classId === "mage" ? "✦"
                                            : classId === "archer" ? "➶"
                                            : classId === "lango" ? "☠"
                                            : classId === "bronhaman" ? "♞" : "🐾"
                                        color: win.classColor(classId)
                                        font.pixelSize: 35
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: win.className(classId)
                                        color: "#f1edf4"
                                        font.family: "monospace"
                                        font.pixelSize: 15
                                        font.bold: true
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: win.classStats(classId)
                                        color: win.classColor(classId)
                                        font.pixelSize: 10
                                        wrapMode: Text.WordWrap
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: win.classDescription(classId)
                                        color: "#c6c2ce"
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        visible: backend.state === "menu" && !win.introVisible
                        text: qsTr("Choose your hero • Level up for class skills and elemental powers.")
                        color: "#dbbe75"
                        font.pixelSize: 13
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: backend.state === "menu" && !win.introVisible ? qsTr("The first three clears raise the threat; the third opens the hidden fifth stage.")
                            : backend.state === "menu" ? qsTr("The story begins in Beco dos Noias.")
                            : backend.state === "victory" ? qsTr("All five bosses defeated. The Vale is quiet again.")
                            : backend.state === "gameover" ? qsTr("Every night teaches you something.")
                            : qsTr("WASD / arrows to move  •  Esc to pause")
                        color: "#a7a5b2"
                        font.pixelSize: 13
                    }
                    Item { Layout.fillHeight: true }
                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        text: backend.state === "menu" && win.introVisible ? qsTr("MEET THE HEROES")
                            : backend.state === "menu" ? qsTr("START THE NIGHT")
                            : backend.state === "paused" ? qsTr("RESUME") : qsTr("PLAY AGAIN")
                        highlighted: true
                        onClicked: {
                            stage.forceActiveFocus()
                            if (backend.state === "menu" && win.introVisible) win.introVisible = false
                            else if (backend.state === "paused") backend.resumeGame()
                            else backend.startGame()
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: backend.state === "menu" && win.introVisible
                            ? qsTr("Continue: Space or click • Sound: M")
                            : backend.state === "menu" ? qsTr("1–6 choose a class  •  Start: Space  •  Sound: M")
                            : qsTr("Move: WASD / arrows    •    Pause: Esc    •    Help: ?")
                        color: "#777785"
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        visible: backend.state === "menu"
                        text: !gamepad.ready
                            ? qsTr("Controller support unavailable. Keyboard and mouse still work.")
                            : gamepad.connected
                                ? qsTr("Controller connected · Left stick: move · A: confirm · B/Start: pause")
                                : qsTr("No controller detected · Gamepads work outside Steam; Steam Input is optional.")
                        color: gamepad.connected ? "#9dcf9d" : "#777785"
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        visible: backend.state === "gameover" || backend.state === "victory"
                        text: qsTr("CHOOSE ANOTHER CLASS")
                        onClicked: {
                            backend.returnToMenu()
                            stage.forceActiveFocus()
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#df080b13"
            visible: backend.state === "upgrade"
            z: 4

            Rectangle {
                width: Math.min(parent.width - 36, 920)
                height: 425
                anchors.centerIn: parent
                color: "#f2191d29"
                border.color: "#77758a"
                border.width: 1
                radius: theme.radius
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 3
                    color: theme.accent
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 12
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("LEVEL %1 — %2 — CHOOSE A POWER")
                            .arg(backend.level).arg(win.className(backend.heroClass))
                        color: "#f0d98a"
                        font.family: "monospace"
                        font.pixelSize: 22
                        font.bold: true
                        font.letterSpacing: 1.4
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Choose a skill unique to your class or an elemental power.")
                        color: "#c6c2ce"
                        font.pixelSize: 13
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12
                        Repeater {
                            model: backend.upgradeOptions
                            delegate: Button {
                                required property var modelData
                                required property int index
                                property string power: modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                focusPolicy: Qt.NoFocus
                                onClicked: {
                                    win.quickSelect(index + 1)
                                }
                                background: Rectangle {
                                    color: parent.hovered || win.upgradeSelection === index
                                        ? "#3a3b4c" : "#282b39"
                                    border.color: win.upgradeColor(power)
                                    border.width: parent.hovered || win.upgradeSelection === index ? 2 : 1
                                    radius: theme.radius
                                }
                                contentItem: ColumnLayout {
                                    spacing: 8
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: index === 0 ? "[1]" : index === 1 ? "[2]" : "[3]"
                                        color: "#a7a5b2"
                                        font.pixelSize: 12
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: win.upgradeIcon(power)
                                        color: win.upgradeColor(power)
                                        font.pixelSize: 48
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: win.upgradeName(power)
                                        color: "#f1edf4"
                                        font.family: "monospace"
                                        font.pixelSize: 17
                                        font.bold: true
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: qsTr("POWER LEVEL %1").arg(win.upgradeLevel(power))
                                        color: "#d7c78e"
                                        font.pixelSize: 11
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        wrapMode: Text.WordWrap
                                        text: win.upgradeDescription(power)
                                        color: "#c6c2ce"
                                        font.pixelSize: 13
                                    }
                                }
                            }
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Press 1, 2 or 3 • Click a card • Your run pauses until you choose")
                        color: "#898897"
                        font.pixelSize: 11
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#e6101119"
            visible: win.helpVisible
            z: 5
            MouseArea { anchors.fill: parent; onClicked: win.helpVisible = false }
            Rectangle {
                anchors.centerIn: parent
                width: 410
                height: 330
                color: "#f31a1d2a"
                border.color: "#687284"
                radius: theme.radius
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 3
                    color: theme.accent
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 26
                    Label { text: qsTr("CONTROLS"); color: "#f4d681"; font.pixelSize: 22; font.bold: true }
                    Label { text: qsTr("WASD / arrows    Move"); color: "#f1edf4" }
                    Label { text: qsTr("Space                 Start / resume"); color: "#f1edf4" }
                    Label { text: qsTr("Esc                    Pause / resume"); color: "#f1edf4" }
                    Label { text: qsTr("?                       Show this help"); color: "#f1edf4" }
                    Label { text: qsTr("M                       Toggle sound"); color: "#f1edf4" }
                    Label { text: qsTr("1 / 2 / 3 / 4 / 5 / 6          Select a class or level-up power"); color: "#f1edf4" }
                    Label { text: qsTr("Controller: Left stick move · D-pad/LB/RB select · A confirm · B/Start pause"); color: "#f1edf4"; wrapMode: Text.WordWrap }
                    Label { text: qsTr("Q                       Quit"); color: "#f1edf4" }
                    Item { Layout.fillHeight: true }
                    Button { text: qsTr("CLOSE"); onClicked: win.helpVisible = false }
                }
            }
        }
    }

    Component.onCompleted: {
        updateStageMusic()
        stage.forceActiveFocus()
    }
}
