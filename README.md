# Welcome to Mai Bloom OS! 🏵

**Mai Bloom OS** is a newly launched, Arch Linux-based distribution that seamlessly integrates the innovative technologies developed by Mai Bloom Tech Studio, delivering an unparalleled and user-friendly computing experience designed to simplify everyday tasks. 

---

> [!CAUTION]
> **IMPORTANT: MAI BLOOM OS IS IN EARLY STAGES!**  
> Please be aware that Mai Bloom OS is currently in beta and under development—meaning it can be highly experimental. > You may encounter bugs, unexpected behavior, or incomplete features.  
> **We strongly recommend:**  
> - **Not using this on a primary machine or for critical data.**  
> - **Backing up any important data** on both your system and the USB drive you will be using, as it will be erased.  
> - Exercising patience and being prepared to troubleshoot should issues arise.

> [!CAUTION]
> The required storage for this distrobution haven't been determined accurately yet, but we recommend a storage large enough to install >6G operating system plus ~>=10G [AI module](https://github.com/maibloom/maibloom-aicore)

---
## Pre Installation

1.  **Prepare your USB Drive:**
    * [Download the current latest release and follow the instructions to prepare your USB drive.](https://github.com/maibloom/iso/releases/tag/v.1.0.0-alpha)

2.  **Boot from USB:**
    * Reboot your computer.
    * As your computer starts, enter your system's BIOS or Boot Menu. (Common keys include `F2`, `F10`, `F12`, `DEL`, or `ESC`. This varies by manufacturer, so check your computer's documentation if unsure.)
    * Select your USB drive from the boot options.

> [!NOTE]
> You can use Virtual Machines as well.

3.  **Log into the Live Environment:**
    * You should be greeted by the KDE Plasma 6 login screen.
    * Enter `root` as the username.
    * Leave the password field blank.
    * Click "Login" or press Enter.

## Installation Steps 🛠️

Follow these steps carefully to install Mai Bloom OS:

1.  **Launch the Installer:**
    * Once you reach the desktop, locate and click the "Install Mai Bloom OS" icon or button.
      ![Screenshot_20250602_225324](https://github.com/user-attachments/assets/977585fd-0719-4c23-98e1-759640dcdd40)

2.  **Initial Setup & Installer Download:**
    * The installer application will first guide you to check your internet connection. It will then proceed to download the latest version of the installer components. Please ensure you have a stable internet connection.
      ![Screenshot_20250602_225349](https://github.com/user-attachments/assets/77e68c85-cce0-4777-b80a-cbaecf21d168)

      And this is the installer's kernel window:
      ![Screenshot_20250602_225358](https://github.com/user-attachments/assets/eb7d61f7-5de0-4d1c-805d-2cc925a9970a)
> [!CAUTION]
> **IMPORTANT: DO NOT CLOSE ANY OF THESE TERMINAL WINDOWS MANUALLY.** They are all critical to the installation process.

6.  **Installation Process Begins:**
       * After you click the "Proceed" button within the GUI, three terminal windows will be visible:
          * One displaying this web page (With its own blank terminal)
            ![Screenshot_20250602_225435](https://github.com/user-attachments/assets/1fd978be-1a9a-48e4-85ac-02c874095e72)
          * One running Arch Linux's `archinstall` script.
            ![Screenshot_20250602_225449](https://github.com/user-attachments/assets/74528c6b-5fbd-4fc8-a061-64db4a3c4d6a)
          * And one is the installer terminal which has mentionend.
       
       * **IMPORTANT: DO NOT CLOSE ANY OF THESE TERMINAL WINDOWS MANUALLY.** They are all critical to the installation process.
  
> [!TIP]
> You can put these windows alongside eFor a stable and complete installation, we recommend using the "Best Effort" ext4 disk configuration with the "home" directory enabled.ach other for better accessibility.
> ![Screenshot_20250602_225501](https://github.com/user-attachments/assets/eedd6eaa-717c-48b5-914e-48e02b2bf388)

7.  **Install Arch Linux Base:**
    * Focus on the terminal window labeled "Arch Install" or similar (it will be running `archinstall`).
> [!WARNING]
> For a stable and complete installation, we recommend using the "Best Effort" ext4 disk configuration with the "home" directory enabled.
    * Follow the on-screen prompts within this terminal to install the Arch Linux base system. This forms the foundation of Mai Bloom OS.

8.  **Mai Bloom OS Build:**
    * Once the Arch Linux installation (Step 7) is complete, you first press "Exit archinstall" and then you can safely close its specific terminal window.
      ![Screenshot_20250602_231154](https://github.com/user-attachments/assets/8a9965a6-a4f9-4dca-9c9b-4bde23dca4a3)

    * The Mai Bloom OS builder terminal window will then automatically resume and continue building the rest of the operating system.
      ![Screenshot_20250602_231205](https://github.com/user-attachments/assets/86ac8f27-198d-459b-b44d-75f22155343d)


9.  **Installation Complete & Reboot:**
    * When the Mai Bloom OS builder finishes, a dialog box will appear, informing you that the installation is complete.
      ![Screenshot_20250602_235940](https://github.com/user-attachments/assets/92c059eb-2fe8-4198-acac-198a606b517a)
    * At this point, you can safely restart your computer.
    * **Remember to remove the USB drive** as your computer restarts to ensure you boot into your new Mai Bloom OS installation.

10. **Done! Welcome to Mai Bloom OS! 🎉**
    We hope you enjoy exploring Mai Bloom OS.

---

## Feedback & Contributions

As Mai Bloom OS is in its early stages, your feedback and contributions are invaluable! Please reach out via GitHub (e.g., by opening an Issue or Discussion on this repository) so we can talk further. We look forward to hearing from you!
