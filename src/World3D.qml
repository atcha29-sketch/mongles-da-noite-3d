pragma ComponentBehavior: Bound

import QtQuick
import QtQuick3D
import Mongles 1.0

Item {
    id: root

    property int stageIndex: Math.max(0, Math.min(4, backend.stage - 1))
    property int animationFrame: 0
    property var skyColors: ["#111323", "#17231d", "#171d28", "#130f24", "#1b1018"]
    property var groundColors: ["#292a32", "#344331", "#393638", "#29253c", "#3a2a30"]
    property var trimColors: ["#b39a72", "#94ac77", "#c29a70", "#ef65aa", "#d58572"]
    property var activeBosses: {
        var list = []
        if (backend.boss.active) list.push(backend.boss)
        if (backend.subBoss.active) list.push(backend.subBoss)
        return list
    }

    function heroColor(id) {
        if (id === "warrior") return "#344557"
        if (id === "mage") return "#534779"
        if (id === "archer") return "#427451"
        if (id === "lango") return "#4d5960"
        if (id === "kalengue") return "#954f72"
        return "#775037"
    }

    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: root.animationFrame = (root.animationFrame + 1) % 360
    }

    View3D {
        id: view
        anchors.fill: parent
        camera: sceneCamera
        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Color
            clearColor: root.skyColors[root.stageIndex]
        }

        Node {
            id: sceneRoot

            PerspectiveCamera {
                id: sceneCamera
                position: Qt.vector3d(0, 70, 91)
                eulerRotation: Qt.vector3d(-38, 0, 0)
                fieldOfView: 57
                fieldOfViewOrientation: PerspectiveCamera.Horizontal
                clipNear: 1
                clipFar: 260
            }

            DirectionalLight {
                eulerRotation: Qt.vector3d(-48, -24, 0)
                brightness: 1.35
                color: "#e2dcff"
            }

            PointLight {
                position: Qt.vector3d(-20, 22, -18)
                brightness: 45
                color: root.trimColors[root.stageIndex]
                quadraticFade: 0.006
            }

            Repeater3D {
                model: 18
                delegate: Model {
                    required property int index
                    source: "#Cube"
                    position: Qt.vector3d(-46 + (index * 149) % 92,
                                          20 + (index * 37) % 12,
                                          -34)
                    scale: Qt.vector3d(index % 4 === 0 ? 0.003 : 0.0018,
                                       index % 4 === 0 ? 0.003 : 0.0018, 0.001)
                    materials: PrincipledMaterial {
                        baseColor: index % 3 === 0 ? "#a4acc1" : "#65728d"
                        lighting: PrincipledMaterial.NoLighting
                    }
                }
            }
            Node {
                position: Qt.vector3d(31, 22, -33)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.045, 0.045, 0.004)
                    materials: PrincipledMaterial {
                        baseColor: root.stageIndex === 4 ? "#d67a72"
                            : root.stageIndex === 3 ? "#d9b8cb"
                            : root.stageIndex === 2 ? "#c8aa77" : "#d4d0b1"
                        lighting: PrincipledMaterial.NoLighting
                    }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(-0.5, 0.7, 0.002)
                    scale: Qt.vector3d(0.018, 0.012, 0.001)
                    materials: PrincipledMaterial { baseColor: "#777986"; lighting: PrincipledMaterial.NoLighting }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(0.45, -0.3, 0.002)
                    scale: Qt.vector3d(0.012, 0.01, 0.001)
                    materials: PrincipledMaterial { baseColor: "#777986"; lighting: PrincipledMaterial.NoLighting }
                }
            }

            Model {
                source: "#Cube"
                position: Qt.vector3d(0, -0.5, 0)
                scale: Qt.vector3d(1, 0.005, 0.7)
                materials: PrincipledMaterial {
                    baseColor: root.groundColors[root.stageIndex]
                    roughness: 1
                }
            }

            // Broad, shallow markings create a readable arena floor at very low cost.
            Repeater3D {
                model: 7
                delegate: Model {
                    required property int index
                    source: "#Cube"
                    position: Qt.vector3d(0, -0.235, -28 + index * 9)
                    scale: Qt.vector3d(0.99, 0.0008, 0.006)
                    materials: PrincipledMaterial {
                        baseColor: index % 2 ? "#41434f" : "#50515d"
                        roughness: 1
                    }
                }
            }
            Repeater3D {
                model: 8
                delegate: Model {
                    required property int index
                    source: "#Cube"
                    position: Qt.vector3d(-43 + index * 12.3, -0.232, 1)
                    scale: Qt.vector3d(0.003, 0.0007, 0.43)
                    materials: PrincipledMaterial { baseColor: "#454653"; roughness: 1 }
                }
            }

            // A low skyline frames each stage and stays behind the play area.
            Repeater3D {
                model: 11
                delegate: Model {
                    required property int index
                    property real buildingHeight: 6 + ((index * 7 + root.stageIndex * 3) % 8)
                    source: "#Cube"
                    visible: root.stageIndex === 0 || root.stageIndex === 3
                    position: Qt.vector3d(-46 + index * 9.2, buildingHeight / 2 - 0.2, -30)
                    scale: Qt.vector3d(0.075, buildingHeight / 100, 0.11)
                    materials: PrincipledMaterial {
                        baseColor: root.stageIndex === 3 ? "#29243d" : "#292b38"
                        roughness: 0.96
                    }
                }
            }

            // Pixel-art scenery rebuilt from chunky, layered 3D pieces.
            // Cemetery stones and iron crosses frame the alley and final ruins.
            Repeater3D {
                model: 7
                delegate: Node {
                    required property int index
                    property real graveX: -42 + index * 14
                    visible: root.stageIndex === 0 || root.stageIndex === 4
                    Model {
                        source: "#Cube"
                        position: Qt.vector3d(parent.graveX, 1.0, -24 + (index % 2) * 2)
                        scale: Qt.vector3d(0.065, 0.022, 0.018)
                        materials: PrincipledMaterial { baseColor: "#34343d"; roughness: 1 }
                    }
                    Model {
                        source: "#Cube"
                        position: Qt.vector3d(parent.graveX, 2.0, -24 + (index % 2) * 2)
                        scale: Qt.vector3d(0.036, 0.018, 0.018)
                        materials: PrincipledMaterial { baseColor: "#454650"; roughness: 1 }
                    }
                    Model {
                        visible: parent.index % 2 === 0
                        source: "#Cube"
                        position: Qt.vector3d(parent.graveX, 2.65, -23.78 + (index % 2) * 2)
                        scale: Qt.vector3d(0.006, 0.014, 0.002)
                        materials: PrincipledMaterial { baseColor: "#778078"; roughness: 1 }
                    }
                    Model {
                        visible: parent.index % 2 === 0
                        source: "#Cube"
                        position: Qt.vector3d(parent.graveX, 2.55, -23.78 + (index % 2) * 2)
                        scale: Qt.vector3d(0.012, 0.004, 0.002)
                        materials: PrincipledMaterial { baseColor: "#778078"; roughness: 1 }
                    }
                }
            }

            // A broken picket fence and a small lantern-lit shed match the yard map.
            Repeater3D {
                model: 21
                delegate: Model {
                    required property int index
                    visible: root.stageIndex === 1
                    source: "#Cube"
                    position: Qt.vector3d(-47 + index * 4.7, 1.2, -25)
                    scale: Qt.vector3d(0.014, 0.024, 0.012)
                    materials: PrincipledMaterial { baseColor: "#907258"; roughness: 1 }
                }
            }
            Model {
                source: "#Cube"
                visible: root.stageIndex === 1
                position: Qt.vector3d(0, 2.05, -25)
                scale: Qt.vector3d(0.99, 0.014, 0.012)
                materials: PrincipledMaterial { baseColor: "#a18461"; roughness: 1 }
            }
            Model {
                source: "#Cube"
                visible: root.stageIndex === 1
                position: Qt.vector3d(0, 1.15, -25)
                scale: Qt.vector3d(0.99, 0.012, 0.012)
                materials: PrincipledMaterial { baseColor: "#8c7157"; roughness: 1 }
            }
            Model {
                source: "#Cube"
                visible: root.stageIndex === 1
                position: Qt.vector3d(35, 2.6, -29)
                scale: Qt.vector3d(0.18, 0.085, 0.065)
                materials: PrincipledMaterial { baseColor: "#594b42"; roughness: 1 }
            }
            Model {
                source: "#Cone"
                visible: root.stageIndex === 1
                position: Qt.vector3d(35, 8.1, -29)
                scale: Qt.vector3d(0.20, 0.07, 0.075)
                materials: PrincipledMaterial { baseColor: "#775b4c"; roughness: 1 }
            }
            Repeater3D {
                model: 6
                delegate: Node {
                    required property int index
                    property real treeX: -43 + index * 17
                    visible: root.stageIndex === 1
                    Model {
                        source: "#Cube"
                        position: Qt.vector3d(parent.treeX, 3, -31)
                        scale: Qt.vector3d(0.025, 0.07, 0.025)
                        materials: PrincipledMaterial { baseColor: "#332c27"; roughness: 1 }
                    }
                    Model {
                        source: "#Cone"
                        position: Qt.vector3d(parent.treeX, 8, -31)
                        scale: Qt.vector3d(0.14, 0.095, 0.14)
                        materials: PrincipledMaterial { baseColor: "#26382e"; roughness: 1 }
                    }
                    Model {
                        source: "#Cone"
                        position: Qt.vector3d(parent.treeX, 12, -31)
                        scale: Qt.vector3d(0.105, 0.08, 0.105)
                        materials: PrincipledMaterial { baseColor: "#304538"; roughness: 1 }
                    }
                }
            }

            // Mine braces, ore and rails give the cave its timber-and-track silhouette.
            Repeater3D {
                model: 4
                delegate: Node {
                    required property int index
                    property real braceX: -33 + index * 22
                    visible: root.stageIndex === 2
                    Model {
                        source: "#Cube"
                        position: Qt.vector3d(parent.braceX - 5, 8, -27)
                        scale: Qt.vector3d(0.018, 0.085, 0.02)
                        materials: PrincipledMaterial { baseColor: "#75573e"; roughness: 1 }
                    }
                    Model {
                        source: "#Cube"
                        position: Qt.vector3d(parent.braceX + 5, 8, -27)
                        scale: Qt.vector3d(0.018, 0.085, 0.02)
                        materials: PrincipledMaterial { baseColor: "#75573e"; roughness: 1 }
                    }
                    Model {
                        source: "#Cube"
                        position: Qt.vector3d(parent.braceX, 16.5, -27)
                        scale: Qt.vector3d(0.13, 0.018, 0.02)
                        materials: PrincipledMaterial { baseColor: "#95724c"; roughness: 1 }
                    }
                    Model {
                        source: "#Cube"
                        position: Qt.vector3d(parent.braceX, 17.4, -26.7)
                        scale: Qt.vector3d(0.026, 0.004, 0.003)
                        materials: PrincipledMaterial {
                            baseColor: "#f5ca79"
                            emissiveFactor: Qt.vector3d(0.35, 0.18, 0.04)
                            lighting: PrincipledMaterial.NoLighting
                        }
                    }
                }
            }
            Model {
                source: "#Cube"
                visible: root.stageIndex === 2
                position: Qt.vector3d(0, 0.15, 4)
                scale: Qt.vector3d(0.95, 0.006, 0.008)
                materials: PrincipledMaterial { baseColor: "#6e655c"; roughness: 1 }
            }
            Model {
                source: "#Cube"
                visible: root.stageIndex === 2
                position: Qt.vector3d(0, 0.15, 5.8)
                scale: Qt.vector3d(0.95, 0.006, 0.008)
                materials: PrincipledMaterial { baseColor: "#6e655c"; roughness: 1 }
            }

            // Bright, square windows and sign blocks repeat the central-city pixel art.
            Repeater3D {
                model: 18
                delegate: Model {
                    required property int index
                    visible: root.stageIndex === 3
                    source: "#Cube"
                    position: Qt.vector3d(-43 + (index % 9) * 10.7,
                                          5 + Math.floor(index / 9) * 5,
                                          -28)
                    scale: Qt.vector3d(0.018, 0.024, 0.004)
                    materials: PrincipledMaterial {
                        baseColor: index % 2 ? "#b35f8e" : "#547bb5"
                        emissiveFactor: index % 2 ? Qt.vector3d(0.2, 0.035, 0.09)
                                                 : Qt.vector3d(0.03, 0.1, 0.2)
                        roughness: 1
                    }
                }
            }
            Model {
                source: "#Cube"
                visible: root.stageIndex === 3
                position: Qt.vector3d(-27, 3.2, -27)
                scale: Qt.vector3d(0.14, 0.035, 0.018)
                materials: PrincipledMaterial {
                    baseColor: "#e45d9b"
                    emissiveFactor: Qt.vector3d(0.52, 0.04, 0.18)
                    lighting: PrincipledMaterial.NoLighting
                }
            }
            Model {
                source: "#Cube"
                visible: root.stageIndex === 3
                position: Qt.vector3d(27, 3.2, -27)
                scale: Qt.vector3d(0.14, 0.035, 0.018)
                materials: PrincipledMaterial {
                    baseColor: "#63d5d1"
                    emissiveFactor: Qt.vector3d(0.04, 0.46, 0.48)
                    lighting: PrincipledMaterial.NoLighting
                }
            }

            // Broken red stone arches define the final valley skyline.
            Repeater3D {
                model: 5
                delegate: Node {
                    required property int index
                    property real ribX: -37 + index * 19
                    visible: root.stageIndex === 4
                    Model {
                        source: "#Cube"
                        position: Qt.vector3d(parent.ribX - 3, 10, -28)
                        scale: Qt.vector3d(0.025, 0.11, 0.03)
                        materials: PrincipledMaterial { baseColor: "#79605b"; roughness: 1 }
                    }
                    Model {
                        source: "#Cube"
                        position: Qt.vector3d(parent.ribX + 3, 10, -28)
                        scale: Qt.vector3d(0.025, 0.11, 0.03)
                        materials: PrincipledMaterial { baseColor: "#64504e"; roughness: 1 }
                    }
                    Model {
                        source: "#Cube"
                        position: Qt.vector3d(parent.ribX, 21, -28)
                        scale: Qt.vector3d(0.11, 0.018, 0.03)
                        materials: PrincipledMaterial { baseColor: "#9a7770"; roughness: 1 }
                    }
                }
            }

            Repeater3D {
                model: 9
                delegate: Model {
                    required property int index
                    source: "#Cube"
                    visible: root.stageIndex === 1
                    position: Qt.vector3d(-44 + index * 11, 1.2, -25)
                    scale: Qt.vector3d(0.025, 0.024, 0.025)
                    materials: PrincipledMaterial { baseColor: "#927258"; roughness: 1 }
                }
            }
            Model {
                source: "#Cube"
                visible: root.stageIndex === 1
                position: Qt.vector3d(0, 2.7, -25)
                scale: Qt.vector3d(0.99, 0.002, 0.015)
                materials: PrincipledMaterial { baseColor: "#b08c67"; roughness: 1 }
            }
            Model {
                source: "#Cube"
                visible: root.stageIndex === 1
                position: Qt.vector3d(0, 0.9, -25)
                scale: Qt.vector3d(0.99, 0.002, 0.015)
                materials: PrincipledMaterial { baseColor: "#9c795b"; roughness: 1 }
            }

            Repeater3D {
                model: 9
                delegate: Model {
                    required property int index
                    source: "#Sphere"
                    visible: root.stageIndex === 2
                    position: Qt.vector3d(-42 + index * 10.5, 2 + (index % 3), -28 - (index % 2) * 2)
                    scale: Qt.vector3d(0.12, 0.08 + (index % 3) * 0.025, 0.09)
                    materials: PrincipledMaterial {
                        baseColor: index % 2 ? "#615d61" : "#736a62"
                        roughness: 1
                    }
                }
            }

            Repeater3D {
                model: 10
                delegate: Model {
                    required property int index
                    source: "#Cube"
                    visible: root.stageIndex === 4
                    position: Qt.vector3d(-44 + index * 9.7, 1.2, -24 + (index % 2) * 2)
                    scale: Qt.vector3d(0.035, 0.025, 0.025)
                    materials: PrincipledMaterial { baseColor: "#65504d"; roughness: 1 }
                }
            }

            Model {
                source: "#Cube"
                visible: root.stageIndex === 3
                position: Qt.vector3d(-27, 2.8, -29)
                scale: Qt.vector3d(0.14, 0.018, 0.018)
                materials: PrincipledMaterial {
                    baseColor: "#f253a5"
                    emissiveFactor: Qt.vector3d(0.7, 0.04, 0.24)
                    lighting: PrincipledMaterial.NoLighting
                }
            }
            Model {
                source: "#Cube"
                visible: root.stageIndex === 3
                position: Qt.vector3d(27, 2.8, -29)
                scale: Qt.vector3d(0.14, 0.018, 0.018)
                materials: PrincipledMaterial {
                    baseColor: "#42d6dc"
                    emissiveFactor: Qt.vector3d(0.04, 0.54, 0.58)
                    lighting: PrincipledMaterial.NoLighting
                }
            }

            // Pixel-block enemy silhouettes stay instanced so crowds remain cheap.
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.enemies
                    category: "enemyShadow"
                    objectScale: Qt.vector3d(0.035, 0.002, 0.035)
                    height: -0.12
                }
                materials: PrincipledMaterial {
                    baseColor: "#17141a"
                    opacity: 0.42
                    lighting: PrincipledMaterial.NoLighting
                }
            }
            Model {
                source: "#Sphere"
                instancing: ArenaInstancing {
                    entities: backend.enemies
                    category: "enemy"
                    stage: backend.stage
                    kindFilter: 0
                    objectScale: Qt.vector3d(0.026, 0.025, 0.021)
                    height: 1.35
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.82 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.enemies
                    category: "enemy"
                    stage: backend.stage
                    kindFilter: 1
                    objectScale: Qt.vector3d(0.028, 0.024, 0.023)
                    height: 1.3
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.82 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.enemies
                    category: "enemy"
                    stage: backend.stage
                    kindFilter: 2
                    objectScale: Qt.vector3d(0.031, 0.027, 0.025)
                    height: 1.35
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.82 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.enemies
                    category: "enemy"
                    stage: backend.stage
                    kindFilter: 0
                    objectScale: Qt.vector3d(0.021, 0.018, 0.02)
                    height: 3.05
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.82 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.enemies
                    category: "enemy"
                    stage: backend.stage
                    kindFilter: 1
                    objectScale: Qt.vector3d(0.018, 0.018, 0.018)
                    height: 3.0
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.82 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.enemies
                    category: "enemy"
                    stage: backend.stage
                    kindFilter: 2
                    objectScale: Qt.vector3d(0.023, 0.02, 0.02)
                    height: 3.0
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.82 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.enemies
                    category: "enemyEye"
                    stage: backend.stage
                    objectScale: Qt.vector3d(0.013, 0.004, 0.002)
                    height: 3.12
                    offset: Qt.vector3d(0, 0, 0.96)
                }
                materials: PrincipledMaterial {
                    baseColor: "white"
                    emissiveFactor: Qt.vector3d(0.62, 0.42, 0.08)
                    lighting: PrincipledMaterial.NoLighting
                }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.enemies
                    category: "enemy"
                    stage: backend.stage
                    objectScale: Qt.vector3d(0.042, 0.006, 0.01)
                    height: 1.85
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.9 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.summons
                    category: "summon"
                    stage: backend.stage
                    objectScale: Qt.vector3d(0.013, 0.014, 0.012)
                    height: 0.65
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.65 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.summons
                    category: "summon"
                    stage: backend.stage
                    kindNameFilter: "skeleton"
                    objectScale: Qt.vector3d(0.012, 0.012, 0.01)
                    height: 2.1
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.7 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.summons
                    category: "summonEye"
                    stage: backend.stage
                    kindNameFilter: "skeleton"
                    objectScale: Qt.vector3d(0.002, 0.002, 0.001)
                    height: 2.12
                    offset: Qt.vector3d(0, 0, 0.48)
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 1 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.summons
                    category: "summonDetail"
                    stage: backend.stage
                    kindNameFilter: "skeleton"
                    objectScale: Qt.vector3d(0.009, 0.002, 0.002)
                    height: 1.3
                    offset: Qt.vector3d(0, 0, 0.5)
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 1 }
            }
            Model {
                source: "#Cone"
                instancing: ArenaInstancing {
                    entities: backend.summons
                    category: "summon"
                    stage: backend.stage
                    kindNameFilter: "cat"
                    objectScale: Qt.vector3d(0.009, 0.009, 0.009)
                    height: 1.5
                    offset: Qt.vector3d(-0.3, 0, 0)
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.65 }
            }
            Model {
                source: "#Cone"
                instancing: ArenaInstancing {
                    entities: backend.summons
                    category: "summon"
                    stage: backend.stage
                    kindNameFilter: "cat"
                    objectScale: Qt.vector3d(0.009, 0.009, 0.009)
                    height: 1.5
                    offset: Qt.vector3d(0.3, 0, 0)
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.65 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.summons
                    category: "summonEye"
                    stage: backend.stage
                    kindNameFilter: "cat"
                    objectScale: Qt.vector3d(0.007, 0.002, 0.001)
                    height: 1.56
                    offset: Qt.vector3d(0, 0, 0.45)
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 1 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.gems
                    category: "gem"
                    objectScale: Qt.vector3d(0.006, 0.009, 0.006)
                    height: 0.38
                }
                materials: PrincipledMaterial { baseColor: "white"; metalness: 0.36; roughness: 0.25 }
            }
            Model {
                source: "#Cone"
                instancing: ArenaInstancing {
                    entities: backend.projectiles
                    category: "projectile"
                    objectScale: Qt.vector3d(0.004, 0.007, 0.004)
                    height: 3.3
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.3; metalness: 0.15 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.drops
                    category: "drop"
                    objectScale: Qt.vector3d(0.01, 0.01, 0.01)
                    height: 0.55
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.45; metalness: 0.2 }
            }
            Model {
                source: "#Sphere"
                instancing: ArenaInstancing {
                    entities: backend.particles
                    category: "particle"
                    objectScale: Qt.vector3d(0.05, 0.05, 0.05)
                    height: 2.4
                }
                materials: PrincipledMaterial { baseColor: "white"; lighting: PrincipledMaterial.NoLighting }
            }

            // Distinct silhouettes make the boss and the sub-boss easy to read.
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: root.activeBosses
                    category: "bossShadow"
                    objectScale: Qt.vector3d(0.11, 0.002, 0.055)
                    height: -0.12
                }
                materials: PrincipledMaterial {
                    baseColor: "#17141a"
                    opacity: 0.44
                    lighting: PrincipledMaterial.NoLighting
                }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.boss.active ? [backend.boss] : []
                    category: "boss"
                    stage: backend.stage
                    objectScale: Qt.vector3d(0.072, 0.062, 0.058)
                    height: 4.2
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.72 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: backend.subBoss.active ? [backend.subBoss] : []
                    category: "boss"
                    stage: backend.stage
                    objectScale: Qt.vector3d(0.052, 0.048, 0.045)
                    height: 3.1
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.72 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: root.activeBosses
                    category: "boss"
                    stage: backend.stage
                    objectScale: Qt.vector3d(0.046, 0.043, 0.045)
                    height: 11.2
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.78 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: root.activeBosses
                    category: "boss"
                    stage: backend.stage
                    objectScale: Qt.vector3d(0.12, 0.013, 0.025)
                    height: 4.5
                }
                materials: PrincipledMaterial { baseColor: "white"; roughness: 0.8 }
            }
            Model {
                source: "#Cube"
                instancing: ArenaInstancing {
                    entities: root.activeBosses
                    category: "bossEye"
                    stage: backend.stage
                    objectScale: Qt.vector3d(0.018, 0.007, 0.003)
                    height: 11.2
                    offset: Qt.vector3d(0, 0, 2.4)
                }
                materials: PrincipledMaterial {
                    baseColor: "white"
                    emissiveFactor: Qt.vector3d(0.7, 0.36, 0.08)
                    lighting: PrincipledMaterial.NoLighting
                }
            }
            Repeater3D {
                model: 5
                delegate: Node {
                    id: bossDetails
                    required property int index
                    visible: root.activeBosses.length > 0
                    Model {
                        source: parent.index === 1 ? "#Cube" : "#Cone"
                        instancing: ArenaInstancing {
                            entities: root.activeBosses
                            category: "boss"
                            stage: backend.stage
                            kindFilter: bossDetails.index
                            objectScale: bossDetails.index === 1
                                ? Qt.vector3d(0.014, 0.045, 0.014)
                                : Qt.vector3d(0.022, 0.032, 0.022)
                            height: bossDetails.index === 1 ? 16.5 : 15.8
                            offset: Qt.vector3d(-4.2, 0, 0.3)
                        }
                        materials: PrincipledMaterial { baseColor: "white"; roughness: 0.82 }
                    }
                    Model {
                        source: parent.index === 1 ? "#Cube" : "#Cone"
                        eulerRotation.z: parent.index === 1 ? 0 : -180
                        instancing: ArenaInstancing {
                            entities: root.activeBosses
                            category: "boss"
                            stage: backend.stage
                            kindFilter: bossDetails.index
                            objectScale: bossDetails.index === 1
                                ? Qt.vector3d(0.014, 0.045, 0.014)
                                : Qt.vector3d(0.022, 0.032, 0.022)
                            height: bossDetails.index === 1 ? 16.5 : 15.8
                            offset: Qt.vector3d(4.2, 0, 0.3)
                        }
                        materials: PrincipledMaterial { baseColor: "white"; roughness: 0.82 }
                    }
                    Model {
                        visible: parent.index === 4
                        source: "#Cube"
                        instancing: ArenaInstancing {
                            entities: root.activeBosses
                            category: "boss"
                            stage: backend.stage
                            kindFilter: bossDetails.index
                            objectScale: Qt.vector3d(0.048, 0.004, 0.003)
                            height: 7.1
                            offset: Qt.vector3d(0, 0, 2.2)
                        }
                        materials: PrincipledMaterial { baseColor: "#725b57"; roughness: 1 }
                    }
                    Model {
                        visible: parent.index === 4
                        source: "#Cube"
                        instancing: ArenaInstancing {
                            entities: root.activeBosses
                            category: "boss"
                            stage: backend.stage
                            kindFilter: bossDetails.index
                            objectScale: Qt.vector3d(0.048, 0.004, 0.003)
                            height: 9.1
                            offset: Qt.vector3d(0, 0, 2.2)
                        }
                        materials: PrincipledMaterial { baseColor: "#725b57"; roughness: 1 }
                    }
                    Model {
                        visible: parent.index === 3
                        source: "#Cube"
                        instancing: ArenaInstancing {
                            entities: root.activeBosses
                            category: "bossEye"
                            stage: backend.stage
                            kindFilter: bossDetails.index
                            objectScale: Qt.vector3d(0.012, 0.004, 0.003)
                            height: 11.2
                            offset: Qt.vector3d(0, 0, 2.55)
                        }
                        materials: PrincipledMaterial {
                            baseColor: "white"
                            emissiveFactor: Qt.vector3d(0.35, 0.12, 0.22)
                            lighting: PrincipledMaterial.NoLighting
                        }
                    }
                }
            }
            Model {
                source: "#Sphere"
                instancing: ArenaInstancing {
                    entities: backend.boss.echoes || []
                    category: "echo"
                    objectScale: Qt.vector3d(0.026, 0.04, 0.026)
                    height: 1.8
                }
                materials: PrincipledMaterial {
                    baseColor: "#b48cff"
                    opacity: 0.66
                    roughness: 0.4
                    emissiveFactor: Qt.vector3d(0.15, 0.06, 0.28)
                }
            }

            Node {
                id: hero
                position: Qt.vector3d((backend.playerX - 500) / 10, 0, (backend.playerY - 350) / 10)
                eulerRotation.y: Math.sin(root.animationFrame * 0.055) * 7
                property string heroId: backend.heroClass
                property color outfit: root.heroColor(heroId)
                property color skin: hero.heroId === "lango" ? "#d9d4c3"
                    : hero.heroId === "kalengue" ? "#bd8b79"
                    : hero.heroId === "mage" ? "#d5b9ab"
                    : hero.heroId === "archer" ? "#d8b991"
                    : hero.heroId === "bronhaman" ? "#d4a875" : "#d6b990"
                property color sleeve: hero.heroId === "lango" ? "#3c4651"
                    : hero.heroId === "kalengue" ? "#75425e"
                    : hero.heroId === "mage" ? "#403958"
                    : hero.heroId === "archer" ? "#35523c"
                    : hero.heroId === "bronhaman" ? "#b79351" : "#546777"

                Model {
                    source: "#Sphere"
                    position: Qt.vector3d(0, -0.12, 0)
                    scale: Qt.vector3d(0.016, 0.002, 0.012)
                    materials: PrincipledMaterial {
                        baseColor: "#17141a"
                        opacity: 0.5
                        lighting: PrincipledMaterial.NoLighting
                    }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(-0.42, 0.44, 0.06)
                    scale: Qt.vector3d(0.006, 0.006, 0.009)
                    materials: PrincipledMaterial { baseColor: "#332c32"; roughness: 0.9 }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(0.42, 0.44, 0.06)
                    scale: Qt.vector3d(0.006, 0.006, 0.009)
                    materials: PrincipledMaterial { baseColor: "#332c32"; roughness: 0.9 }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(-0.39, 0.95, 0)
                    scale: Qt.vector3d(0.005, 0.009, 0.006)
                    materials: PrincipledMaterial { baseColor: hero.sleeve; roughness: 0.9 }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(0.39, 0.95, 0)
                    scale: Qt.vector3d(0.005, 0.009, 0.006)
                    materials: PrincipledMaterial { baseColor: hero.sleeve; roughness: 0.9 }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(-0.43, 1.05, 0.03)
                    scale: Qt.vector3d(0.006, 0.009, 0.007)
                    materials: PrincipledMaterial { baseColor: hero.sleeve; roughness: 0.88 }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(0.43, 1.05, 0.03)
                    scale: Qt.vector3d(0.006, 0.009, 0.007)
                    materials: PrincipledMaterial { baseColor: hero.sleeve; roughness: 0.88 }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(0, 2.05, 0)
                    scale: Qt.vector3d(0.018, 0.018, 0.012)
                    materials: PrincipledMaterial { baseColor: hero.outfit; roughness: 0.86 }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "warrior"
                    position: Qt.vector3d(0, 2.08, 0.62)
                    scale: Qt.vector3d(0.009, 0.011, 0.003)
                    materials: PrincipledMaterial { baseColor: "#728392"; roughness: 0.65; metalness: 0.22 }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "warrior"
                    position: Qt.vector3d(0, 1.95, -0.65)
                    scale: Qt.vector3d(0.016, 0.018, 0.003)
                    materials: PrincipledMaterial { baseColor: "#793f48"; roughness: 0.9 }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(0, 3.38, 0)
                    scale: Qt.vector3d(hero.heroId === "kalengue" ? 0.014 : 0.013,
                                       0.014, 0.012)
                    materials: PrincipledMaterial { baseColor: hero.skin; roughness: 0.83 }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(-0.31, 3.42, 0.62)
                    scale: Qt.vector3d(0.0025, 0.003, 0.002)
                    materials: PrincipledMaterial { baseColor: hero.heroId === "lango" ? "#54394c" : "#292630"; lighting: PrincipledMaterial.NoLighting }
                }
                Model {
                    source: "#Cube"
                    position: Qt.vector3d(0.31, 3.42, 0.62)
                    scale: Qt.vector3d(0.0025, 0.003, 0.002)
                    materials: PrincipledMaterial { baseColor: hero.heroId === "lango" ? "#54394c" : "#292630"; lighting: PrincipledMaterial.NoLighting }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "warrior" || hero.heroId === "kalengue"
                    position: Qt.vector3d(0, 2.85, 0.62)
                    scale: Qt.vector3d(0.006, 0.002, 0.002)
                    materials: PrincipledMaterial { baseColor: hero.heroId === "kalengue" ? "#d887a4" : "#805a54" }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "mage" || hero.heroId === "lango"
                    position: Qt.vector3d(0, 3.91, 0)
                    scale: Qt.vector3d(0.017, 0.005, 0.015)
                    materials: PrincipledMaterial { baseColor: hero.heroId === "mage" ? "#302c4b" : "#282b36"; roughness: 0.9 }
                }
                Model {
                    source: "#Cone"
                    visible: hero.heroId === "mage"
                    position: Qt.vector3d(0, 4.28, 0)
                    scale: Qt.vector3d(0.017, 0.014, 0.017)
                    materials: PrincipledMaterial { baseColor: "#302c4b"; roughness: 0.9 }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "archer"
                    position: Qt.vector3d(0, 3.9, 0)
                    scale: Qt.vector3d(0.017, 0.004, 0.015)
                    materials: PrincipledMaterial { baseColor: "#37583e"; roughness: 0.9 }
                }
                Model {
                    source: "#Cone"
                    visible: hero.heroId === "kalengue"
                    position: Qt.vector3d(-0.43, 4.06, 0)
                    eulerRotation.z: -24
                    scale: Qt.vector3d(0.006, 0.011, 0.006)
                    materials: PrincipledMaterial { baseColor: "#f0a7c7"; roughness: 0.72 }
                }
                Model {
                    source: "#Cone"
                    visible: hero.heroId === "kalengue"
                    position: Qt.vector3d(0.43, 4.06, 0)
                    eulerRotation.z: 24
                    scale: Qt.vector3d(0.006, 0.011, 0.006)
                    materials: PrincipledMaterial { baseColor: "#f0a7c7"; roughness: 0.72 }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "bronhaman"
                    position: Qt.vector3d(0, 4.02, 0)
                    scale: Qt.vector3d(0.016, 0.004, 0.015)
                    materials: PrincipledMaterial { baseColor: "#9a7338"; roughness: 0.72; metalness: 0.18 }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "bronhaman"
                    position: Qt.vector3d(0, 4.32, 0)
                    scale: Qt.vector3d(0.008, 0.01, 0.008)
                    materials: PrincipledMaterial { baseColor: "#b28743"; roughness: 0.72; metalness: 0.18 }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "lango"
                    position: Qt.vector3d(0, 2.05, 0.65)
                    scale: Qt.vector3d(0.011, 0.002, 0.002)
                    materials: PrincipledMaterial { baseColor: "#d5e0d1"; roughness: 0.8 }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "lango"
                    position: Qt.vector3d(0, 1.72, 0.65)
                    scale: Qt.vector3d(0.011, 0.002, 0.002)
                    materials: PrincipledMaterial { baseColor: "#d5e0d1"; roughness: 0.8 }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "warrior" || hero.heroId === "kalengue"
                    position: Qt.vector3d(0.92, 1.9, 0)
                    eulerRotation.z: -18
                    scale: Qt.vector3d(0.004, 0.024, 0.004)
                    materials: PrincipledMaterial {
                        baseColor: hero.heroId === "warrior" ? "#bbc5c9" : "#d5b67b"
                        roughness: 0.58
                        metalness: 0.28
                    }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "mage" || hero.heroId === "lango"
                    position: Qt.vector3d(0.91, 1.85, 0)
                    scale: Qt.vector3d(0.003, 0.025, 0.003)
                    materials: PrincipledMaterial { baseColor: hero.heroId === "lango" ? "#a89a7f" : "#ad8861"; roughness: 0.76 }
                }
                Model {
                    source: "#Sphere"
                    visible: hero.heroId === "mage"
                    position: Qt.vector3d(0.91, 3.15, 0)
                    scale: Qt.vector3d(0.008, 0.008, 0.008)
                    materials: PrincipledMaterial {
                        baseColor: "#9176dc"
                        emissiveFactor: Qt.vector3d(0.22, 0.12, 0.58)
                        roughness: 0.35
                    }
                }
                Model {
                    source: "#Cube"
                    visible: hero.heroId === "archer"
                    position: Qt.vector3d(0.92, 1.95, 0)
                    eulerRotation.z: 18
                    scale: Qt.vector3d(0.003, 0.022, 0.003)
                    materials: PrincipledMaterial { baseColor: "#d4b77a"; roughness: 0.58 }
                }
            }

            Repeater3D {
                model: backend.enemyBeams
                delegate: Model {
                    required property var modelData
                    property real dx: modelData.x2 - modelData.x1
                    property real dy: modelData.y2 - modelData.y1
                    property real beamLength: Math.sqrt(dx * dx + dy * dy) / 10
                    source: "#Cube"
                    visible: modelData.delay <= 0 || root.animationFrame % 3 !== 0
                    position: Qt.vector3d((modelData.x1 + modelData.x2 - 1000) / 20,
                                          0.65,
                                          (modelData.y1 + modelData.y2 - 700) / 20)
                    eulerRotation.y: Math.atan2(dx, dy) * 180 / Math.PI
                    scale: Qt.vector3d(0.008, 0.008, beamLength / 100)
                    materials: PrincipledMaterial {
                        baseColor: modelData.kind === 0 ? "#ff805b"
                            : modelData.kind === 1 ? "#efc86b"
                            : modelData.kind === 2 ? "#bb86ff"
                            : modelData.kind === 3 ? "#ef62b8" : "#b8f5ff"
                        opacity: modelData.delay > 0 ? 0.34 : 0.9
                        lighting: PrincipledMaterial.NoLighting
                    }
                }
            }
        }
    }

    Rectangle {
        visible: backend.boss.active
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 54
        width: Math.min(parent.width * 0.38, 360)
        height: 12
        radius: 6
        color: "#33242b"
        border.color: "#f4b0a7"
        border.width: 1
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, backend.boss.health)
                / Math.max(1, backend.boss.maxHealth)
            radius: 6
            color: "#e3546d"
        }
    }
}
