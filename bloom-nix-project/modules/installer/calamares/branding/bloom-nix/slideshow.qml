import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        interval: 20000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }
    
    Slide {
        Image {
            id: background1
            source: "slide1.png"
            width: 800; height: 600
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
            font.pixelSize: 22
            color: "#f1efee"
            text: "Welcome to Bloom Nix"
        }
    }

    Slide {
        Image {
            id: background2
            source: "slide2.png"
            width: 800; height: 600
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
            font.pixelSize: 22
            color: "#f1efee"
            text: "Deepin Desktop Environment"
        }
    }
}
