// The inside of the lock card: weather + media on the left, the clock /
// profile / password column in the middle, system resources on the right.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../.."
import "../../services"
import "../../Settings"

Item {
    id: root

    required property var surface
    readonly property var player: MediaPlayerService.trackedPlayer
    readonly property real centerScale: surface.centerScale
    readonly property int centerWidth: surface.centerWidth
    readonly property int sideWidth: Math.max(Theme.scaled(260), Math.min(Theme.scaled(330), Math.round((width - centerWidth) / 2) - Theme.scaled(48)))
    readonly property int panelRadius: Theme.scaled(20)
    readonly property color panelColor: Qt.alpha(Colors.surface_container, 0.42)

    // ---- Left: weather (top-left), media (bottom-left) -------------------
    ColumnLayout {
        id: leftCol
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.sideWidth
        spacing: Theme.scaled(16)
        transform: Translate {
            x: root.opacity < 0.1 ? -Theme.scaled(36) : 0
            Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        }

        Rectangle {
            id: weatherCard
            Layout.fillWidth: true
            implicitHeight: weatherCol.implicitHeight + Theme.scaled(28)
            radius: root.panelRadius
            color: root.panelColor
            visible: WidgetSettings.enableWeather

            readonly property var cur: WeatherService.weatherData?.current_condition?.[0]
            readonly property string area: WeatherService.weatherData?.nearest_area?.[0]?.areaName?.[0]?.value || WeatherService.areaName || "Weather"
            readonly property string temp: (cur?.temp_C || WeatherService.tempC || "0") + "°C"
            readonly property string feelsLike: cur?.FeelsLikeC ? (cur.FeelsLikeC + "°C") : temp
            readonly property string humidity: cur?.humidity ? (cur.humidity + "%") : ""
            readonly property string wind: cur?.windspeedKmph ? (cur.windspeedKmph + " km/h") : ""
            readonly property string desc: cur?.weatherDesc?.[0]?.value || WeatherService.weatherDesc || "Clear"

            ColumnLayout {
                id: weatherCol
                anchors.fill: parent
                anchors.margins: Theme.scaled(14)
                spacing: Theme.scaled(10)

                // Top row: Location & Weather Tag
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(6)

                    Text {
                        text: "󰍎"
                        font.family: Theme.iconFont
                        color: Theme.accentColor
                        font.pixelSize: Theme.scaled(12)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: weatherCard.area
                        color: Theme.accentColor
                        font.pixelSize: Theme.scaled(11)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "WEATHER"
                        color: Theme.subtext0
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Black
                        font.letterSpacing: 1
                    }
                }

                // Middle row: Large Icon + Temp + Condition
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(14)

                    Text {
                        text: WeatherService.getIcon(WeatherService.weatherCode)
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(34)
                        color: Theme.accentColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Text {
                            text: weatherCard.temp
                            color: Theme.text
                            font.pixelSize: Theme.scaled(22)
                            font.weight: Font.Bold
                        }
                        Text {
                            text: weatherCard.desc
                            color: Theme.subtext0
                            font.pixelSize: Theme.scaled(12)
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                // Bottom row: Metrics Chips (Feels Like, Humidity, Wind)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(8)
                    visible: weatherCard.cur !== undefined

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.scaled(22)
                        radius: height / 2
                        color: Qt.alpha(Colors.surface_container_highest, 0.6)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Theme.scaled(4)
                            Text { text: "󰔏"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(11); color: Theme.accentColor }
                            Text { text: "Feels " + weatherCard.feelsLike; font.pixelSize: Theme.scaled(10); color: Theme.subtext1; font.weight: Font.Medium }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.scaled(22)
                        radius: height / 2
                        color: Qt.alpha(Colors.surface_container_highest, 0.6)
                        visible: weatherCard.humidity !== ""

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Theme.scaled(4)
                            Text { text: "󰖎"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(11); color: Colors.secondary }
                            Text { text: weatherCard.humidity; font.pixelSize: Theme.scaled(10); color: Theme.subtext1; font.weight: Font.Medium }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.scaled(22)
                        radius: height / 2
                        color: Qt.alpha(Colors.surface_container_highest, 0.6)
                        visible: weatherCard.wind !== ""

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Theme.scaled(4)
                            Text { text: "󰖐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(11); color: Theme.subtext0 }
                            Text { text: weatherCard.wind; font.pixelSize: Theme.scaled(10); color: Theme.subtext1; font.weight: Font.Medium }
                        }
                    }
                }

                // 3-Day Mini Forecast Strip
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(6)
                    visible: WeatherService.forecastDays.length > 1

                    Repeater {
                        model: WeatherService.forecastDays.slice(0, 3)
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: Theme.scaled(26)
                            radius: Theme.scaled(8)
                            color: Qt.alpha(Colors.surface_container_highest, 0.45)

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.scaled(4)
                                Text {
                                    text: index === 0 ? "Today" : Qt.formatDate(new Date(modelData.date + "T12:00:00"), "ddd")
                                    color: index === 0 ? Theme.accentColor : Theme.subtext0
                                    font.pixelSize: Theme.scaled(9.5)
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: WeatherService.getIcon(modelData.hourly?.[4]?.weatherCode || "113")
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(11)
                                    color: Theme.accentColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: modelData.maxtempC + "°"
                                    color: Theme.text
                                    font.pixelSize: Theme.scaled(9.5)
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Automated Pixelated Snake Mini-Game
        Rectangle {
            id: pixelArcade
            Layout.fillWidth: true
            implicitHeight: Theme.scaled(148)
            radius: root.panelRadius
            color: root.panelColor
            border.color: Theme.glassBorder
            border.width: 1
            clip: true

            property int cols: 20
            property int rows: 8
            property var snake: [{x: 5, y: 4}, {x: 4, y: 4}, {x: 3, y: 4}]
            property var food: ({x: 14, y: 4})
            property int dirX: 1
            property int dirY: 0
            property int score: 0
            property int highScore: 0

            function resetGame() {
                snake = [{x: 5, y: 4}, {x: 4, y: 4}, {x: 3, y: 4}];
                dirX = 1; dirY = 0; score = 0;
                spawnFood();
            }

            function spawnFood() {
                for (let tries = 0; tries < 40; tries++) {
                    let fx = Math.floor(Math.random() * cols);
                    let fy = Math.floor(Math.random() * rows);
                    let hit = false;
                    for (let i = 0; i < snake.length; i++) {
                        if (snake[i].x === fx && snake[i].y === fy) { hit = true; break; }
                    }
                    if (!hit) { food = {x: fx, y: fy}; return; }
                }
            }

            function stepAI() {
                let head = snake[0];
                let dirs = [
                    {dx: 1, dy: 0}, {dx: -1, dy: 0},
                    {dx: 0, dy: 1}, {dx: 0, dy: -1}
                ];
                let best = null;
                let bestDist = 99999;

                for (let d of dirs) {
                    if (d.dx === -dirX && d.dy === -dirY) continue;
                    let nx = head.x + d.dx;
                    let ny = head.y + d.dy;
                    if (nx < 0 || nx >= cols || ny < 0 || ny >= rows) continue;
                    let selfHit = false;
                    for (let i = 0; i < snake.length - 1; i++) {
                        if (snake[i].x === nx && snake[i].y === ny) { selfHit = true; break; }
                    }
                    if (selfHit) continue;
                    let dist = Math.abs(nx - food.x) + Math.abs(ny - food.y);
                    if (dist < bestDist) {
                        bestDist = dist;
                        best = d;
                    }
                }

                if (!best) { resetGame(); return; }
                dirX = best.dx;
                dirY = best.dy;

                let newHead = { x: head.x + dirX, y: head.y + dirY };
                let nextSnake = [newHead].concat(snake);
                if (newHead.x === food.x && newHead.y === food.y) {
                    score++;
                    if (score > highScore) highScore = score;
                    snake = nextSnake;
                    spawnFood();
                } else {
                    nextSnake.pop();
                    snake = nextSnake;
                }
                arcadeCanvas.requestPaint();
            }

            Timer {
                interval: 130
                running: LockService.locked && !root.surface.unlocking
                repeat: true
                onTriggered: pixelArcade.stepAI()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(12)
                spacing: Theme.scaled(8)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(6)
                    Text { text: "󰊗"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(13); color: Colors.primary }
                    Text { text: "PIXEL SNAKE"; color: Theme.subtext0; font.pixelSize: Theme.scaled(9.5); font.weight: Font.Black; font.letterSpacing: 1 }
                    Item { Layout.fillWidth: true }
                    Text { text: "SCORE " + pixelArcade.score + (pixelArcade.highScore > 0 ? "  •  HI " + pixelArcade.highScore : ""); color: Colors.primary; font.pixelSize: Theme.scaled(9.5); font.weight: Font.Bold }
                }

                Canvas {
                    id: arcadeCanvas
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    antialiasing: false
                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        let cellW = Math.floor(width / pixelArcade.cols);
                        let cellH = Math.floor(height / pixelArcade.rows);
                        let cell = Math.max(4, Math.min(cellW, cellH));
                        let ox = Math.floor((width - cell * pixelArcade.cols) / 2);
                        let oy = Math.floor((height - cell * pixelArcade.rows) / 2);

                        // Subtle pixel grid dots
                        ctx.fillStyle = Qt.rgba(1, 1, 1, 0.06);
                        for (let gx = 0; gx < pixelArcade.cols; gx++) {
                            for (let gy = 0; gy < pixelArcade.rows; gy++) {
                                ctx.fillRect(ox + gx * cell + Math.floor(cell / 2), oy + gy * cell + Math.floor(cell / 2), 1, 1);
                            }
                        }

                        // Food pixel
                        ctx.fillStyle = String(Colors.error);
                        ctx.fillRect(ox + pixelArcade.food.x * cell + 1, oy + pixelArcade.food.y * cell + 1, cell - 2, cell - 2);

                        // Snake pixels
                        for (let i = pixelArcade.snake.length - 1; i >= 0; i--) {
                            let seg = pixelArcade.snake[i];
                            ctx.fillStyle = (i === 0) ? String(Colors.primary) : String(Colors.secondary);
                            ctx.fillRect(ox + seg.x * cell + 1, oy + seg.y * cell + 1, cell - 2, cell - 2);
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            id: mediaCard
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.scaled(265)
            radius: root.panelRadius
            color: root.panelColor
            border.color: Theme.glassBorder
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(16)
                spacing: Theme.scaled(12)

                Item {
                    id: artBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    readonly property int artRadius: Theme.scaled(12)

                    // Rounded background
                    Rectangle {
                        anchors.fill: parent
                        radius: artBox.artRadius
                        color: Qt.alpha(Colors.surface_container_high, 0.8)
                        border.color: Theme.glassBorder
                        border.width: 1
                    }

                    // Rounded mask for artwork
                    Rectangle {
                        id: artMask
                        anchors.fill: parent
                        radius: artBox.artRadius
                        color: "black"
                        layer.enabled: true
                        visible: false
                    }

                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.player ? String(root.player.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: artMask
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        text: "󰎆"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(64)
                        color: Colors.on_surface_variant
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.player ? MediaPlayerService.formatMediaTitle(String(root.player.trackTitle || "Media"), root.player.identity) : "Nothing playing"
                    color: Theme.text
                    font.pixelSize: Theme.scaled(14)
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.player ? String(root.player.trackArtist || "") : ""
                    visible: text !== ""
                    color: Theme.subtext0
                    font.pixelSize: Theme.scaled(12)
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Theme.scaled(4)
                    spacing: Theme.scaled(14)
                    visible: root.player !== null

                    Rectangle {
                        implicitWidth: Theme.scaled(32); implicitHeight: Theme.scaled(32)
                        radius: width / 2
                        color: prevM.containsMouse ? Qt.alpha(Colors.primary, 0.2) : Qt.alpha(Colors.surface_container_highest, 0.6)
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(15)
                            color: prevM.containsMouse ? Colors.primary : Theme.text
                        }
                        MouseArea {
                            id: prevM
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                        }
                    }

                    Rectangle {
                        implicitWidth: Theme.scaled(36); implicitHeight: Theme.scaled(36)
                        radius: width / 2
                        color: Colors.primary
                        scale: playM.pressed ? 0.92 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animInstant } }
                        Text {
                            anchors.centerIn: parent
                            text: MediaPlayerService.isActuallyPlaying ? "󰏤" : "󰐊"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(16)
                            color: Colors.on_primary
                        }
                        MouseArea {
                            id: playM
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (!root.player) return;
                                if (MediaPlayerService.isActuallyPlaying) root.player.pause();
                                else root.player.play();
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: Theme.scaled(32); implicitHeight: Theme.scaled(32)
                        radius: width / 2
                        color: nextM.containsMouse ? Qt.alpha(Colors.primary, 0.2) : Qt.alpha(Colors.surface_container_highest, 0.6)
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(15)
                            color: nextM.containsMouse ? Colors.primary : Theme.text
                        }
                        MouseArea {
                            id: nextM
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (root.player && root.player.canGoNext) root.player.next()
                        }
                    }
                }
            }
        }
    }

    // ---- Center ----------------------------------------------------------
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.scaled(12)
        anchors.bottomMargin: Theme.scaled(12)
        width: root.centerWidth
        spacing: Theme.scaled(22)

        // Clock (12-hour format with AM/PM pill below minutes)
        RowLayout {
            id: clockRow
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.scaled(8) * root.centerScale
            spacing: Theme.scaled(8)

            readonly property int digitSize: Math.round((ClockSettings.use24Hour ? 148 : 132) * root.centerScale)
            readonly property int rawHours: clock.date.getHours()
            readonly property int hours12: (rawHours % 12 === 0) ? 12 : (rawHours % 12)
            readonly property string hoursStr: (hours12 < 10 ? "0" : "") + hours12
            readonly property string ampmStr: rawHours >= 12 ? "PM" : "AM"

            Text {
                Layout.alignment: Qt.AlignTop
                text: ClockSettings.use24Hour ? Qt.formatDateTime(clock.date, "HH") : clockRow.hoursStr
                color: Colors.primary
                font.pixelSize: clockRow.digitSize
                font.weight: Font.Black
                font.letterSpacing: -4
            }

            Text {
                text: ":"
                color: Qt.alpha(Colors.primary, 0.45)
                font.pixelSize: Math.round(clockRow.digitSize * 0.75)
                font.weight: Font.Light
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: Theme.scaled(6) * root.centerScale
            }

            ColumnLayout {
                spacing: 0

                Text {
                    id: minutesText
                    text: Qt.formatDateTime(clock.date, "mm")
                    color: Colors.secondary
                    font.pixelSize: clockRow.digitSize
                    font.weight: Font.Black
                    font.letterSpacing: -4
                }

                Rectangle {
                    visible: !ClockSettings.use24Hour
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: -Theme.scaled(14)
                    implicitWidth: minutesText.implicitWidth - Theme.scaled(8)
                    implicitHeight: ampm.implicitHeight + Theme.scaled(10)
                    radius: Theme.scaled(12)
                    color: Qt.alpha(Colors.surface_container_high, 0.9)

                    Text {
                        id: ampm
                        anchors.centerIn: parent
                        text: clockRow.ampmStr
                        color: Theme.text
                        font.pixelSize: Theme.scaled(18)
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "dddd • d MMM").toUpperCase()
            color: Theme.text
            font.pixelSize: Theme.scaled(15)
            font.weight: Font.DemiBold
            font.letterSpacing: 2
        }

        // Greeting + User Pill
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: greetRow.implicitWidth + Theme.scaled(18)
            height: Theme.scaled(26)
            radius: 999
            color: Qt.alpha(Colors.surface_container_high, 0.75)
            border.color: Theme.glassBorder
            border.width: 1

            Row {
                id: greetRow
                anchors.centerIn: parent
                spacing: Theme.scaled(6)
                Text {
                    text: {
                        let h = clock.date.getHours();
                        return h < 12 ? "󰖙" : (h < 18 ? "󰖕" : "󰖔");
                    }
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(12)
                    color: Colors.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: {
                        let h = clock.date.getHours();
                        let g = h < 12 ? "Good morning" : (h < 18 ? "Good afternoon" : "Good evening");
                        let user = Quickshell.env("USER") || "User";
                        return g + ", " + user;
                    }
                    color: Theme.text
                    font.pixelSize: Theme.scaled(11)
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Profile picture
        Item { Layout.fillHeight: true }
                    antialiasing: false
                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        let cellW = Math.floor(width / pixelArcade.cols);
                        let cellH = Math.floor(height / pixelArcade.rows);
                        let cell = Math.max(4, Math.min(cellW, cellH));
                        let ox = Math.floor((width - cell * pixelArcade.cols) / 2);
                        let oy = Math.floor((height - cell * pixelArcade.rows) / 2);

                        // Subtle pixel grid dots
                        ctx.fillStyle = Qt.rgba(1, 1, 1, 0.06);
                        for (let gx = 0; gx < pixelArcade.cols; gx++) {
                            for (let gy = 0; gy < pixelArcade.rows; gy++) {
                                ctx.fillRect(ox + gx * cell + Math.floor(cell / 2), oy + gy * cell + Math.floor(cell / 2), 1, 1);
                            }
                        }

                        // Food pixel
                        ctx.fillStyle = String(Colors.error);
                        ctx.fillRect(ox + pixelArcade.food.x * cell + 1, oy + pixelArcade.food.y * cell + 1, cell - 2, cell - 2);

                        // Snake pixels
                        for (let i = pixelArcade.snake.length - 1; i >= 0; i--) {
                            let seg = pixelArcade.snake[i];
                            ctx.fillStyle = (i === 0) ? String(Colors.primary) : String(Colors.secondary);
                            ctx.fillRect(ox + seg.x * cell + 1, oy + seg.y * cell + 1, cell - 2, cell - 2);
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
        Item {
            id: pfpBox
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.scaled(14) * root.centerScale
            Layout.bottomMargin: Theme.scaled(8) * root.centerScale
            readonly property int size: Math.round(root.centerWidth * 0.44)
            Layout.preferredWidth: size
            Layout.preferredHeight: size
            implicitWidth: size
            implicitHeight: size
            width: size
            height: size
            property bool hasFace: false

            Process {
                running: true
                command: ["test", "-f", PathSettings.home + "/.face"]
                onExited: (code) => pfpBox.hasFace = (code === 0)
            }

            // Outer ring border (reacts to typing & auth)
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Qt.alpha(Colors.surface_container_highest, 0.9)
                border.color: LockService.authenticating ? Colors.secondary
                            : (LockService.buffer.length > 0 ? Colors.primary : Qt.alpha(Colors.primary, 0.55))
                border.width: LockService.buffer.length > 0 ? 3.5 : 2.5
                Behavior on border.width { NumberAnimation { duration: Theme.animInstant } }
                Behavior on border.color { ColorAnimation { duration: Theme.animInstant } }
            }

            // Fallback glyph
            Text {
                anchors.centerIn: parent
                visible: pfp.status !== Image.Ready
                text: "󰀄"
                font.family: Theme.iconFont
                font.pixelSize: parent.size / 2
                color: Colors.on_surface_variant
            }

            // Circular mask
            Rectangle {
                id: pfpMask
                anchors.fill: parent
                anchors.margins: 3
                radius: width / 2
                color: "black"
                layer.enabled: true
                visible: false
            }

            // Avatar source image
            Image {
                id: pfp
                anchors.fill: pfpMask
                source: {
                    const custom = IdleSettings.profilePicture;
                    if (custom !== "") return custom.startsWith("file://") ? custom : "file://" + custom;
                    if (pfpBox.hasFace) return "file://" + PathSettings.home + "/.face";
                    return "file://" + PathSettings.shellDir + "/pp.png";
                }
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready

                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: pfpMask
                }

                onStatusChanged: {
                    if (status === Image.Error && source.toString().endsWith("/pp.png")) {
                        source = "file://" + PathSettings.shellDir + "/pp";
                    }
                }
            }
        }

        // User identification
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Theme.scaled(10) * root.centerScale
            spacing: Theme.scaled(2)

            Text {
                id: userNameDisplay
                Layout.alignment: Qt.AlignHCenter
                text: Variables.user
                color: Theme.text
                font.pixelSize: Theme.scaled(20)
                font.weight: Font.Bold
                font.capitalization: Font.Capitalize
                font.letterSpacing: 0.5
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "@" + Variables.hostname
                color: Theme.subtext0
                font.pixelSize: Theme.scaled(12)
                font.weight: Font.Medium
                opacity: 0.75
            }
        }

        // Password pill
        Rectangle {
            id: field
            property bool revealPassword: false
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.round(root.centerWidth * 0.85)
            implicitHeight: Theme.scaled(48)
            radius: height / 2
            clip: true
            color: Qt.alpha(Colors.surface_container_high, 0.95)
            border.width: 2
            border.color: {
                if (LockService.state === LockService.State.Failed || LockService.state === LockService.State.MaxTries) return Colors.error;
                if (LockService.authenticating) return Colors.primary;
                return "transparent";
            }
            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            // A failed attempt shakes the field.
            transform: Translate { id: shake }
            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 10; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: -6; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 6; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
            }
            Connections {
                target: LockService
                function onFlash() { shakeAnim.restart(); field.revealPassword = false; }
                function onUnlockRequested() { field.revealPassword = false; }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(16)
                anchors.rightMargin: Theme.scaled(8)
                spacing: Theme.scaled(8)

                Text {
                    text: LockService.authenticating ? "󰔟" : "󰌾"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(18)
                    color: Colors.on_surface_variant
                    RotationAnimation on rotation { running: LockService.authenticating; from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
                }

                // Password input: dots or cleartext
                Item {
                    id: inputContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        visible: LockService.buffer.length === 0
                        text: "Enter password"
                        color: Colors.on_surface_variant
                        font.pixelSize: Theme.scaled(14)
                    }

                    // Dots (when not revealed)
                    Row {
                        id: dotsRow
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.min(0, inputContainer.width - width)
                        spacing: Theme.scaled(5)
                        visible: !field.revealPassword && LockService.buffer.length > 0
                        Repeater {
                            model: LockService.buffer.length
                            Rectangle {
                                width: Theme.scaled(9); height: width; radius: width / 2
                                color: Theme.text
                                scale: 0
                                Component.onCompleted: scale = 1
                                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }
                            }
                        }
                    }

                    // Cleartext (when revealed via eye button)
                    Text {
                        id: clearText
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.min(0, inputContainer.width - width)
                        width: implicitWidth
                        visible: field.revealPassword && LockService.buffer.length > 0
                        text: LockService.buffer
                        color: Theme.text
                        font.pixelSize: Theme.scaled(15)
                        font.family: "JetBrains Mono"
                        font.weight: Font.DemiBold
                        elide: Text.ElideNone
                    }
                }

                // Eye toggle button (show/hide password)
                Rectangle {
                    visible: LockService.buffer.length > 0
                    Layout.preferredWidth: Theme.scaled(32)
                    Layout.preferredHeight: Theme.scaled(32)
                    implicitWidth: Theme.scaled(32)
                    implicitHeight: Theme.scaled(32)
                    radius: width / 2
                    color: eyeMouse.containsMouse ? Qt.alpha(Colors.primary, 0.15) : "transparent"
                    scale: eyeMouse.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animInstant } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: field.revealPassword ? "󰈉" : "󰈈"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(16)
                        color: field.revealPassword ? Colors.primary : (eyeMouse.containsMouse ? Theme.text : Colors.on_surface_variant)
                    }

                    MouseArea {
                        id: eyeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: field.revealPassword = !field.revealPassword
                    }
                }

                // Submit button
                Rectangle {
                    Layout.preferredWidth: Theme.scaled(34)
                    Layout.preferredHeight: Theme.scaled(34)
                    implicitWidth: Theme.scaled(34)
                    implicitHeight: Theme.scaled(34)
                    radius: width / 2
                    color: LockService.buffer.length > 0 ? Colors.primary : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰌑"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(16)
                        color: LockService.buffer.length > 0 ? Colors.on_primary : Colors.on_surface_variant
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: LockService.buffer.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: LockService.submit()
                    }
                }
            }
        }

        // State message
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: {
                if (LockService.message !== "") return LockService.message;
                switch (LockService.state) {
                case LockService.State.Failed: return "Incorrect password";
                case LockService.State.Error: return "Authentication error";
                case LockService.State.MaxTries: return "Too many attempts";
                }
                return LockService.authenticating ? "Checking…" : (CaffeineService.active ? "Caffeine is on" : "");
            }
            color: (LockService.state === LockService.State.None) ? Colors.on_surface_variant : Colors.error
            font.pixelSize: Theme.scaled(12)
            opacity: text === "" ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }

        Item { Layout.fillHeight: true }
                    antialiasing: false
                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        let cellW = Math.floor(width / pixelArcade.cols);
                        let cellH = Math.floor(height / pixelArcade.rows);
                        let cell = Math.max(4, Math.min(cellW, cellH));
                        let ox = Math.floor((width - cell * pixelArcade.cols) / 2);
                        let oy = Math.floor((height - cell * pixelArcade.rows) / 2);

                        // Subtle pixel grid dots
                        ctx.fillStyle = Qt.rgba(1, 1, 1, 0.06);
                        for (let gx = 0; gx < pixelArcade.cols; gx++) {
                            for (let gy = 0; gy < pixelArcade.rows; gy++) {
                                ctx.fillRect(ox + gx * cell + Math.floor(cell / 2), oy + gy * cell + Math.floor(cell / 2), 1, 1);
                            }
                        }

                        // Food pixel
                        ctx.fillStyle = String(Colors.error);
                        ctx.fillRect(ox + pixelArcade.food.x * cell + 1, oy + pixelArcade.food.y * cell + 1, cell - 2, cell - 2);

                        // Snake pixels
                        for (let i = pixelArcade.snake.length - 1; i >= 0; i--) {
                            let seg = pixelArcade.snake[i];
                            ctx.fillStyle = (i === 0) ? String(Colors.primary) : String(Colors.secondary);
                            ctx.fillRect(ox + seg.x * cell + 1, oy + seg.y * cell + 1, cell - 2, cell - 2);
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Connections {
            target: LockService
            function onEscapePressed() {
                sessionContainer.sessionExpanded = false;
            }
        }

        // Quick Status Strip (Wi-Fi, Volume, Battery, DND, Caffeine)
        Flow {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.centerWidth
            spacing: Theme.scaled(6)

            // Wi-Fi Pill
            Rectangle {
                visible: HardwareService.hasWifi
                width: wifiPillRow.implicitWidth + Theme.scaled(14)
                height: Theme.scaled(24)
                radius: 999
                color: Qt.alpha(Colors.surface_container_high, 0.75)
                border.color: Theme.glassBorder
                border.width: 1
                Row {
                    id: wifiPillRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(5)
                    Text {
                        text: WifiService.currentSsid !== "" ? "󰤨" : "󰤭"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(11)
                        color: WifiService.currentSsid !== "" ? Colors.primary : Theme.subtext2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: WifiService.currentSsid !== "" ? WifiService.currentSsid : "Offline"
                        color: Theme.text
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Volume Pill (clickable mute toggle)
            Rectangle {
                width: volPillRow.implicitWidth + Theme.scaled(14)
                height: Theme.scaled(24)
                radius: 999
                color: volPillM.containsMouse ? Qt.alpha(Colors.primary, 0.16) : Qt.alpha(Colors.surface_container_high, 0.75)
                border.color: Theme.glassBorder
                border.width: 1
                Row {
                    id: volPillRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(5)
                    Text {
                        text: VolumeService.muted ? Theme.volMute : (VolumeService.outputVolume > 50 ? Theme.volHigh : Theme.volMid)
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(11)
                        color: VolumeService.muted ? Colors.error : Colors.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: VolumeService.muted ? "Muted" : (VolumeService.outputVolume + "%")
                        color: Theme.text
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: volPillM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: VolumeService.toggleMute()
                }
            }

            Rectangle {
                visible: HardwareService.hasBattery && BatteryService.percentage >= 0
                width: batPillRow.implicitWidth + Theme.scaled(14)
                height: Theme.scaled(24)
                radius: 999
                color: Qt.alpha(Colors.surface_container_high, 0.75)
                border.color: Theme.glassBorder
                border.width: 1
                Row {
                    id: batPillRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(5)
                    Text {
                        text: Theme.batteryIcon(BatteryService.percentage, BatteryService.status === "charging")
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(12)
                        color: Theme.batteryColorFor(BatteryService.percentage, BatteryService.status === "charging")
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: BatteryService.percentage + "%"
                        color: Theme.text
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: dndLockRow.implicitWidth + Theme.scaled(14)
                height: Theme.scaled(24)
                radius: 999
                color: PowerToolsService.dnd ? Qt.alpha(Colors.primary, 0.2) : Qt.alpha(Colors.surface_container_high, 0.75)
                border.color: PowerToolsService.dnd ? Qt.alpha(Colors.primary, 0.4) : Theme.glassBorder
                border.width: 1
                Row {
                    id: dndLockRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)
                    Text { text: PowerToolsService.dnd ? "󰂛" : "󰂚"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(11); color: PowerToolsService.dnd ? Colors.primary : Theme.subtext0; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "DND"; color: PowerToolsService.dnd ? Colors.primary : Theme.subtext0; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PowerToolsService.toggleDnd()
                }
            }

            Rectangle {
                visible: CaffeineService.active
                width: cafLockRow.implicitWidth + Theme.scaled(14)
                height: Theme.scaled(24)
                radius: 999
                color: Qt.alpha(Colors.secondary, 0.16)
                border.color: Qt.alpha(Colors.secondary, 0.35)
                border.width: 1
                Row {
                    id: cafLockRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)
                    Text { text: "󰅶"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(11); color: Colors.secondary; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Caffeine"; color: Colors.secondary; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }

        // Session Actions container (Pill button with upwards popup: Sleep, Restart, Power Off)
        Item {
            id: sessionContainer
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Theme.scaled(4) * root.centerScale
            implicitHeight: sessionBtn.implicitHeight
            implicitWidth: sessionBtn.implicitWidth
            z: 30

            property bool sessionExpanded: false
            property string sessionStatus: ""

            // Pop-up menu anchored ABOVE the session button ("popup not right not down")
            Rectangle {
                id: sessionPopup
                anchors.bottom: sessionBtn.top
                anchors.bottomMargin: Theme.scaled(10)
                anchors.horizontalCenter: sessionBtn.horizontalCenter
                implicitHeight: popupRow.implicitHeight + Theme.scaled(16)
                implicitWidth: popupRow.implicitWidth + Theme.scaled(20)
                radius: Theme.scaled(18)
                color: Qt.alpha(Colors.surface_container_highest, 0.98)
                border.color: Theme.glassBorder
                border.width: 1
                clip: true
                visible: opacity > 0
                opacity: sessionContainer.sessionExpanded ? 1 : 0
                scale: sessionContainer.sessionExpanded ? 1.0 : 0.88
                transformOrigin: Item.Bottom

                Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 20
                    shadowColor: Qt.rgba(0, 0, 0, 0.45)
                    shadowVerticalOffset: 4
                }

                RowLayout {
                    id: popupRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(8)

                    Repeater {
                        model: [
                            { id: "sleep",   icon: "󰤄", label: "Sleep",     cmd: "systemctl suspend",  accent: Theme.lavender, status: "Suspending…" },
                            { id: "restart", icon: "󰑐", label: "Restart",   cmd: "systemctl reboot",   accent: Theme.blue,     status: "Restarting…" },
                            { id: "power",   icon: "󰐥", label: "Power Off", cmd: "systemctl poweroff", accent: Theme.powerRed, status: "Shutting down…" }
                        ]

                        delegate: Rectangle {
                            id: actBtn
                            implicitHeight: Theme.scaled(32)
                            implicitWidth: actContent.implicitWidth + Theme.scaled(20)
                            radius: height / 2
                            color: actMouse.containsMouse ? Qt.alpha(modelData.accent, 0.25) : Qt.alpha(Colors.surface_container, 0.75)
                            border.color: actMouse.containsMouse ? modelData.accent : Theme.glassBorder
                            border.width: 1
                            scale: actMouse.pressed ? 0.93 : 1.0
                            Behavior on scale { NumberAnimation { duration: Theme.animInstant } }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                id: actContent
                                anchors.centerIn: parent
                                spacing: Theme.scaled(6)

                                Text {
                                    text: modelData.icon
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(14)
                                    color: actMouse.containsMouse ? modelData.accent : Theme.text
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: modelData.label
                                    font.pixelSize: Theme.scaled(12)
                                    font.weight: Font.DemiBold
                                    color: actMouse.containsMouse ? Theme.text : Theme.subtext0
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: actMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sessionContainer.sessionStatus = modelData.status;
                                    sessionContainer.sessionExpanded = false;
                                    sessionActionProc.command = ["sh", "-c", modelData.cmd];
                                    sessionActionProc.running = true;
                                }
                            }
                        }
                    }

                    // Close popup button
                    Rectangle {
                        implicitWidth: Theme.scaled(28)
                        implicitHeight: Theme.scaled(28)
                        radius: width / 2
                        color: closeMouse.containsMouse ? Qt.alpha(Colors.error, 0.22) : "transparent"
                        border.color: Theme.glassBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(11)
                            color: closeMouse.containsMouse ? Colors.error : Theme.subtext0
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sessionContainer.sessionExpanded = false
                        }
                    }
                }
            }

            // Fixed Session button trigger: [ 󰐥  Session  󰅀 ]
            Rectangle {
                id: sessionBtn
                implicitHeight: Theme.scaled(36)
                implicitWidth: collapsedBtnLayout.implicitWidth + Theme.scaled(24)
                radius: height / 2
                color: sessionBtnMouse.containsMouse
                       ? Qt.alpha(Colors.surface_container_highest, 0.95)
                       : Qt.alpha(Colors.surface_container_high, 0.85)
                border.color: sessionContainer.sessionExpanded ? Qt.alpha(Colors.primary, 0.6) : Theme.glassBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    id: collapsedBtnLayout
                    anchors.centerIn: parent
                    spacing: Theme.scaled(8)

                    Text {
                        text: "󰐥"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(15)
                        color: Colors.primary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: sessionContainer.sessionStatus !== "" ? sessionContainer.sessionStatus : "Session"
                        color: Theme.text
                        font.pixelSize: Theme.scaled(12)
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "󰅀"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(12)
                        color: Theme.subtext0
                        visible: sessionContainer.sessionStatus === ""
                        rotation: sessionContainer.sessionExpanded ? 180 : 0
                        Behavior on rotation { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutBack } }
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: sessionBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sessionContainer.sessionExpanded = !sessionContainer.sessionExpanded
                }
            }
        }

        Process { id: sessionActionProc }

        SystemClock { id: clock; precision: SystemClock.Minutes }
    }

    // ---- Right: resources (top-right), notifications (bottom-right) ----
    ColumnLayout {
        id: rightCol
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.sideWidth
        spacing: Theme.scaled(14)
        transform: Translate {
            x: root.opacity < 0.1 ? Theme.scaled(36) : 0
            Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        }

        Rectangle {
            id: resCard
            Layout.fillWidth: true
            implicitHeight: resCol.implicitHeight + Theme.scaled(28)
            radius: root.panelRadius
            color: root.panelColor
            border.color: Theme.glassBorder
            border.width: 1

            ColumnLayout {
                id: resCol
                anchors.fill: parent
                anchors.margins: Theme.scaled(14)
                spacing: Theme.scaled(10)

                // Header with RAM & Load summary
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(6)

                    Text {
                        text: "󰍛"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        color: Colors.primary
                    }

                    Text {
                        text: "SYSTEM"
                        color: Theme.subtext0
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Black
                        font.letterSpacing: 1
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: ResourceService.memTotalGb > 0
                        text: ResourceService.memUsedGb.toFixed(1) + " / " + ResourceService.memTotalGb.toFixed(0) + " GB"
                        color: Theme.subtext1
                        font.pixelSize: Theme.scaled(9.5)
                        font.weight: Font.Bold
                    }
                }

                // Clean Sleek Progress Rows
                Repeater {
                    model: [
                        { key: "cpu", icon: "󰍛", label: "CPU", unit: "%", col: Theme.cpuColor, max: 100 },
                        { key: "mem", icon: "󰘚", label: "Memory", unit: "%", col: Theme.memColor, max: 100 },
                        { key: "temp", icon: "󰔏", label: "Temp", unit: "°C", col: Theme.tempColor, max: 100 },
                        { key: "fs", icon: "󰋊", label: "Disk", unit: "%", col: Colors.secondary, max: 100 }
                    ]

                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Theme.scaled(4)

                        readonly property real liveValue: {
                            if (modelData.key === "cpu") return ResourceService.cpu;
                            if (modelData.key === "mem") return ResourceService.mem;
                            if (modelData.key === "temp") return ResourceService.temp;
                            if (modelData.key === "fs") return ResourceService.fs;
                            return 0;
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.scaled(6)

                            Text {
                                text: modelData.icon
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(13)
                                color: modelData.col
                            }

                            Text {
                                text: modelData.label
                                color: Theme.text
                                font.pixelSize: Theme.scaled(11)
                                font.weight: Font.DemiBold
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: Math.round(liveValue) + modelData.unit
                                color: Theme.text
                                font.pixelSize: Theme.scaled(11)
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Theme.scaled(5)
                            radius: 999
                            color: Qt.rgba(255, 255, 255, 0.1)

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, liveValue / modelData.max))
                                height: parent.height
                                radius: 999
                                color: modelData.col
                                Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
                    antialiasing: false
                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        let cellW = Math.floor(width / pixelArcade.cols);
                        let cellH = Math.floor(height / pixelArcade.rows);
                        let cell = Math.max(4, Math.min(cellW, cellH));
                        let ox = Math.floor((width - cell * pixelArcade.cols) / 2);
                        let oy = Math.floor((height - cell * pixelArcade.rows) / 2);

                        // Subtle pixel grid dots
                        ctx.fillStyle = Qt.rgba(1, 1, 1, 0.06);
                        for (let gx = 0; gx < pixelArcade.cols; gx++) {
                            for (let gy = 0; gy < pixelArcade.rows; gy++) {
                                ctx.fillRect(ox + gx * cell + Math.floor(cell / 2), oy + gy * cell + Math.floor(cell / 2), 1, 1);
                            }
                        }

                        // Food pixel
                        ctx.fillStyle = String(Colors.error);
                        ctx.fillRect(ox + pixelArcade.food.x * cell + 1, oy + pixelArcade.food.y * cell + 1, cell - 2, cell - 2);

                        // Snake pixels
                        for (let i = pixelArcade.snake.length - 1; i >= 0; i--) {
                            let seg = pixelArcade.snake[i];
                            ctx.fillStyle = (i === 0) ? String(Colors.primary) : String(Colors.secondary);
                            ctx.fillRect(ox + seg.x * cell + 1, oy + seg.y * cell + 1, cell - 2, cell - 2);
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            id: notifCard
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(Theme.scaled(310), Math.max(Theme.scaled(190), root.height * 0.36))
            radius: root.panelRadius
            color: root.panelColor
            border.color: Theme.glassBorder
            border.width: 1
            clip: true

            readonly property int notifCount: NotificationService.notifications.count

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(16)
                spacing: Theme.scaled(12)

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(8)

                    Text {
                        text: "󰂚"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(16)
                        color: Colors.primary
                    }

                    Text {
                        text: "NOTIFICATIONS"
                        color: Theme.subtext0
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Black
                        font.letterSpacing: 1
                    }

                    Item { Layout.fillWidth: true }

                    // Count Badge or All Caught Up Tag
                    Rectangle {
                        implicitWidth: countBadgeText.implicitWidth + Theme.scaled(14)
                        implicitHeight: Theme.scaled(20)
                        radius: height / 2
                        color: notifCard.notifCount > 0 ? Qt.alpha(Colors.primary, 0.18) : Qt.alpha(Colors.surface_container_highest, 0.5)
                        border.color: notifCard.notifCount > 0 ? Qt.alpha(Colors.primary, 0.4) : Theme.glassBorder
                        border.width: 1

                        Text {
                            id: countBadgeText
                            anchors.centerIn: parent
                            text: notifCard.notifCount > 0 ? (notifCard.notifCount + " new") : "0"
                            color: notifCard.notifCount > 0 ? Colors.primary : Theme.subtext0
                            font.pixelSize: Theme.scaled(10)
                            font.weight: Font.Bold
                        }
                    }

                    // Clear all button (only when notifications exist)
                    Rectangle {
                        visible: notifCard.notifCount > 0
                        implicitWidth: Theme.scaled(22)
                        implicitHeight: Theme.scaled(22)
                        radius: width / 2
                        color: clearAllM.containsMouse ? Qt.alpha(Colors.error, 0.2) : Qt.alpha(Colors.surface_container_highest, 0.5)
                        border.color: Theme.glassBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰆴"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(11)
                            color: clearAllM.containsMouse ? Colors.error : Theme.subtext0
                        }

                        MouseArea {
                            id: clearAllM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.clearAll()
                        }
                    }
                }

                // Notification Items List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(8)
                    visible: notifCard.notifCount > 0

                    Repeater {
                        model: Math.min(notifCard.notifCount, 3)

                        Rectangle {
                            id: itemRect
                            required property int index
                            readonly property var n: NotificationService.notifications.get(index)

                            Layout.fillWidth: true
                            implicitHeight: itemRow.implicitHeight + Theme.scaled(14)
                            radius: Theme.scaled(12)
                            color: itemM.containsMouse ? Qt.alpha(Colors.surface_container_highest, 0.75) : Qt.alpha(Colors.surface_container_high, 0.55)
                            border.color: itemM.containsMouse ? Qt.alpha(Colors.primary, 0.35) : Theme.glassBorder
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                id: itemRow
                                anchors.fill: parent
                                anchors.margins: Theme.scaled(8)
                                spacing: Theme.scaled(10)

                                // App Icon / Initials Badge
                                Rectangle {
                                    implicitWidth: Theme.scaled(28)
                                    implicitHeight: Theme.scaled(28)
                                    radius: Theme.scaled(8)
                                    color: Qt.alpha(Colors.primary, 0.18)
                                    border.color: Qt.alpha(Colors.primary, 0.3)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: (n && n.appName && n.appName.length > 0) ? n.appName.charAt(0).toUpperCase() : "󰂚"
                                        font.pixelSize: Theme.scaled(12)
                                        font.weight: Font.Bold
                                        color: Colors.primary
                                        font.family: (n && n.appName && n.appName.length > 0) ? "" : Theme.iconFont
                                    }
                                }

                                // Details: App name, summary, body preview
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: n ? (n.appName || "Notification") : ""
                                            color: Colors.primary
                                            font.pixelSize: Theme.scaled(11)
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Text {
                                        text: n ? (n.summary || "") : ""
                                        color: Theme.text
                                        font.pixelSize: Theme.scaled(12)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: n ? (n.body || "") : ""
                                        color: Theme.subtext0
                                        font.pixelSize: Theme.scaled(10)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        visible: n && n.body && n.body !== ""
                                    }
                                }

                                // Dismiss button
                                Rectangle {
                                    implicitWidth: Theme.scaled(20)
                                    implicitHeight: Theme.scaled(20)
                                    radius: width / 2
                                    color: disM.containsMouse ? Qt.alpha(Colors.error, 0.25) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: Theme.iconFont
                                        font.pixelSize: Theme.scaled(11)
                                        color: disM.containsMouse ? Colors.error : Theme.subtext0
                                    }

                                    MouseArea {
                                        id: disM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (itemRect.n && itemRect.n.id !== undefined) {
                                                NotificationService.dismissNotification(itemRect.n.id);
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: itemM
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }

                    Text {
                        text: "+ " + (notifCard.notifCount - 3) + " more"
                        color: Theme.subtext0
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Medium
                        Layout.alignment: Qt.AlignHCenter
                        visible: notifCard.notifCount > 3
                    }
                }

                // Empty State (All caught up)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: notifCard.notifCount === 0
                    Layout.alignment: Qt.AlignCenter
                    spacing: Theme.scaled(8)

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: Theme.scaled(44)
                        implicitHeight: Theme.scaled(44)
                        radius: width / 2
                        color: Qt.alpha(Colors.surface_container_highest, 0.45)
                        border.color: Theme.glassBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰂚"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(20)
                            color: Theme.subtext0
                            opacity: 0.7
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "All Caught Up"
                        color: Theme.text
                        font.pixelSize: Theme.scaled(13)
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No new notifications"
                        color: Theme.subtext0
                        font.pixelSize: Theme.scaled(11)
                        opacity: 0.75
                    }
                }

                Item { Layout.fillHeight: true; visible: notifCard.notifCount > 0 }
            }
        }
    }
}
