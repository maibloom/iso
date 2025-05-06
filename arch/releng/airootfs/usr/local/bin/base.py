import sys
from PyQt5.QtWidgets import QApplication, QWidget, QLabel, QVBoxLayout, QPushButton
from PyQt5.QtCore import Qt

class WelcomeScreen(QWidget):
    def __init__(self):
        super().__init__()
        self.initUI()

    def initUI(self):
        # Set the window title and size
        self.setWindowTitle("Welcome Screen")
        self.setGeometry(100, 100, 400, 300)  # Position (x, y) and size (width, height)

        # Create a vertical layout
        layout = QVBoxLayout()

        # Create a label with the welcome message
        welcome_label = QLabel("Welcome to the Application!")
        welcome_label.setAlignment(Qt.AlignCenter)
        layout.addWidget(welcome_label)

        # Create a button and connect its clicked signal to the close() method.
        # In a full application, you might switch to the main window here.
        continue_button = QPushButton("Continue")
        continue_button.setFixedWidth(100)
        continue_button.clicked.connect(self.close)
        layout.addWidget(continue_button, alignment=Qt.AlignCenter)

        # Set the created layout on this widget
        self.setLayout(layout)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    # Create an instance of the WelcomeScreen and show it.
    welcome_screen = WelcomeScreen()
    welcome_screen.show()
    # Start the application's event loop.
    sys.exit(app.exec_())
