// 원형 게이지 (CPU, 메모리, 디스크, 온도)
import QtQuick
import QtQuick.Shapes

Item {
    id: gauge

    property real value: 0 // 0..1
    property color color: Theme.mauve
    property string text
    property string label
    property string detail

    implicitWidth: size
    implicitHeight: ring.height + 34

    readonly property real size: 58
    readonly property real stroke: 5
    property real animated: Math.max(0, Math.min(1, value))
    Behavior on animated { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    Item {
        id: ring
        anchors.horizontalCenter: parent.horizontalCenter
        width: gauge.size
        height: gauge.size

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: Qt.rgba(1, 1, 1, 0.08)
                strokeWidth: gauge.stroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: gauge.size / 2
                    centerY: gauge.size / 2
                    radiusX: (gauge.size - gauge.stroke) / 2
                    radiusY: radiusX
                    startAngle: 135
                    sweepAngle: 270
                }
            }

            ShapePath {
                strokeColor: gauge.color
                strokeWidth: gauge.stroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: gauge.size / 2
                    centerY: gauge.size / 2
                    radiusX: (gauge.size - gauge.stroke) / 2
                    radiusY: radiusX
                    startAngle: 135
                    sweepAngle: Math.max(0.5, 270 * gauge.animated)
                }
            }
        }

        Txt {
            anchors.centerIn: parent
            text: gauge.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
    }

    Column {
        anchors.top: ring.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 0

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: gauge.label
            font.pixelSize: 11
            color: Theme.subtext1
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: gauge.detail
            font.pixelSize: 10
            color: Theme.overlay1
        }
    }
}
