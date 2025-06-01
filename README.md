# Welcome to Mai Bloom OS! 🏵

**Mai Bloom OS** is a newly launched, Arch Linux-based distribution that seamlessly integrates the innovative technologies developed by Mai Bloom Tech Studio, delivering an unparalleled and user-friendly computing experience designed to simplify everyday tasks. 

---

## ⚠️ IMPORTANT: MAI BLOOM OS IS IN EARLY STAGES! ⚠️

Please be aware that Mai Bloom OS is **highly experimental** and under active development. You may encounter bugs, unexpected behavior, or incomplete features.

**We strongly recommend:**

* **Not using this on a primary machine or for critical data.**
* **Backing up any important data** on the USB drive you will be using, as it will be erased.
* Patience and a willingness to troubleshoot if issues arise.

---

## Installation Steps 🛠️

Follow these steps carefully to install Mai Bloom OS:

1.  **Prepare your USB Drive:**
    * Download the Mai Bloom OS `.iso` file.
    * You will need a USB drive that you **do not need** for other purposes, as its contents will be erased.
    * Use a tool like [Rufus](https://rufus.ie/), [balenaEtcher](https://www.balena.io/etcher/), or `dd` (for Linux/macOS users) to "burn" or write the `.iso` file to your USB drive. This makes the USB drive bootable.

2.  **Boot from USB:**
    * Reboot your computer.
    * As your computer starts, enter your system's BIOS or Boot Menu. (Common keys include `F2`, `F10`, `F12`, `DEL`, or `ESC`. This varies by manufacturer, so check your computer's documentation if unsure.)
    * Select your USB drive from the boot options.

3.  **Log into the Live Environment:**
    * You should be greeted by the KDE Plasma 6 login screen.
    * Enter `root` as the username.
    * Leave the password field blank.
    * Click "Login" or press Enter.

4.  **Launch the Installer:**
    * Once you reach the desktop, locate and click the "Install Mai Bloom OS" icon or button.

5.  **Initial Setup & Installer Download:**
    * The installer application will first guide you to check your internet connection.
    * It will then proceed to download the latest version of the installer components. Please ensure you have a stable internet connection.

6.  **Installation Process Begins:**
    * After you click the "Install" button within the GUI, three terminal windows will appear:
        * One displaying a Firefox web page (likely for information or help).
        * One running Arch Linux's `archinstall` script.
        * One for the Mai Bloom OS builder script.
    * **IMPORTANT: DO NOT CLOSE ANY OF THESE TERMINAL WINDOWS MANUALLY.** They are all critical to the installation process.

7.  **Install Arch Linux Base:**
    * Focus on the terminal window labeled "Arch Install" or similar (it will be running `archinstall`).
    * Follow the on-screen prompts within this terminal to install the Arch Linux base system. This forms the foundation of Mai Bloom OS.

8.  **Mai Bloom OS Build:**
    * Once the Arch Linux installation (Step 7) is complete, you can safely close its specific terminal window.
    * The Mai Bloom OS builder terminal window will then automatically resume and continue building the rest of the operating system.

9.  **Installation Complete & Reboot:**
    * When the Mai Bloom OS builder finishes, a dialog box will appear, informing you that the installation is complete.
    * At this point, you can safely restart your computer.
    * **Remember to remove the USB drive** as your computer restarts to ensure you boot into your new Mai Bloom OS installation.

10. **Done! Welcome to Mai Bloom OS! 🎉**
    We hope you enjoy exploring Mai Bloom OS.

---

## Feedback & Contributions

As Mai Bloom OS is in its early stages, your feedback and contributions are invaluable! Please reach out via GitHub (e.g., by opening an Issue or Discussion on this repository) so we can talk further. We look forward to hearing from you!
