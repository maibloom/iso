# XFCE Theme and Layout Configuration for Bloom Nix
{ config, lib, pkgs, ... }:

let
  defaultUser = "nixos";
in {
  # Apply XFCE customizations through Home Manager for the default user
  home-manager.users.${defaultUser} = { pkgs, ... }: {
    # Create XFCE configuration files
    home.file = {
      # Set up panel configuration
      ".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xfce4-panel" version="1.0">
          <property name="configver" type="int" value="2"/>
          <property name="panels" type="array">
            <value type="int" value="1"/>
            <property name="dark-mode" type="bool" value="true"/>
            <property name="panel-1" type="empty">
              <property name="position" type="string" value="p=8;x=0;y=0"/>
              <property name="length" type="uint" value="100"/>
              <property name="position-locked" type="bool" value="true"/>
              <property name="icon-size" type="uint" value="24"/>
              <property name="size" type="uint" value="34"/>
              <property name="plugin-ids" type="array">
                <value type="int" value="1"/>
                <value type="int" value="2"/>
                <value type="int" value="3"/>
                <value type="int" value="4"/>
                <value type="int" value="5"/>
                <value type="int" value="6"/>
                <value type="int" value="7"/>
                <value type="int" value="8"/>
                <value type="int" value="9"/>
                <value type="int" value="10"/>
                <value type="int" value="11"/>
                <value type="int" value="12"/>
                <value type="int" value="13"/>
              </property>
              <property name="background-style" type="uint" value="1"/>
              <property name="background-rgba" type="array">
                <value type="double" value="0.156863"/>
                <value type="double" value="0.156863"/>
                <value type="double" value="0.156863"/>
                <value type="double" value="0.95"/>
              </property>
            </property>
          </property>
          <property name="plugins" type="empty">
            <property name="plugin-1" type="string" value="whiskermenu"/>
            <property name="plugin-2" type="string" value="separator">
              <property name="style" type="uint" value="0"/>
            </property>
            <property name="plugin-3" type="string" value="launcher">
              <property name="items" type="array">
                <value type="string" value="firefox.desktop"/>
              </property>
            </property>
            <property name="plugin-4" type="string" value="launcher">
              <property name="items" type="array">
                <value type="string" value="Thunar.desktop"/>
              </property>
            </property>
            <property name="plugin-5" type="string" value="launcher">
              <property name="items" type="array">
                <value type="string" value="xfce4-terminal.desktop"/>
              </property>
            </property>
            <property name="plugin-6" type="string" value="separator">
              <property name="style" type="uint" value="1"/>
              <property name="expand" type="bool" value="true"/>
            </property>
            <property name="plugin-7" type="string" value="tasklist">
              <property name="flat-buttons" type="bool" value="true"/>
              <property name="show-handle" type="bool" value="false"/>
              <property name="middle-click" type="uint" value="1"/>
              <property name="grouping" type="uint" value="1"/>
            </property>
            <property name="plugin-8" type="string" value="separator">
              <property name="style" type="uint" value="1"/>
              <property name="expand" type="bool" value="true"/>
            </property>
            <property name="plugin-9" type="string" value="systray">
              <property name="square-icons" type="bool" value="true"/>
              <property name="icon-size" type="uint" value="24"/>
              <property name="symbolic-icons" type="bool" value="false"/>
            </property>
            <property name="plugin-10" type="string" value="pulseaudio">
              <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
            </property>
            <property name="plugin-11" type="string" value="power-manager-plugin"/>
            <property name="plugin-12" type="string" value="notification-plugin"/>
            <property name="plugin-13" type="string" value="clock">
              <property name="digital-format" type="string" value="%a %b %d, %H:%M"/>
            </property>
          </property>
        </channel>
      '';

      # Set up desktop settings
      ".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xfce4-desktop" version="1.0">
          <property name="desktop-icons" type="empty">
            <property name="file-icons" type="empty">
              <property name="show-home" type="bool" value="true"/>
              <property name="show-filesystem" type="bool" value="true"/>
              <property name="show-trash" type="bool" value="true"/>
              <property name="show-removable" type="bool" value="true"/>
            </property>
            <property name="icon-size" type="uint" value="48"/>
            <property name="tooltip-size" type="double" value="64.000000"/>
            <property name="show-tooltips" type="bool" value="true"/>
          </property>
          <property name="backdrop" type="empty">
            <property name="screen0" type="empty">
              <property name="monitor0" type="empty">
                <property name="image-path" type="string" value="/run/current-system/sw/share/backgrounds/bloom-nix-wallpaper.jpg"/>
                <property name="image-style" type="int" value="5"/>
                <property name="image-show" type="bool" value="true"/>
                <property name="color1" type="array">
                  <value type="uint" value="0"/>
                  <value type="uint" value="0"/>
                  <value type="uint" value="0"/>
                  <value type="uint" value="65535"/>
                </property>
              </property>
            </property>
          </property>
        </channel>
      '';

      # Configure window manager settings
      ".config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xfwm4" version="1.0">
          <property name="general" type="empty">
            <property name="theme" type="string" value="Materia-dark"/>
            <property name="button_layout" type="string" value="O|HMC"/>
            <property name="focus_new" type="bool" value="true"/>
            <property name="workspace_count" type="int" value="4"/>
            <property name="title_alignment" type="string" value="center"/>
            <property name="title_font" type="string" value="Noto Sans Bold 9"/>
            <property name="easy_click" type="string" value="Alt"/>
            <property name="use_compositing" type="bool" value="true"/>
            <property name="cycle_preview" type="bool" value="true"/>
            <property name="cycle_tabwin" type="bool" value="true"/>
            <property name="double_click_action" type="string" value="maximize"/>
            <property name="snap_to_windows" type="bool" value="true"/>
            <property name="snap_to_border" type="bool" value="true"/>
            <property name="snap_width" type="int" value="10"/>
            <property name="workspace_names" type="array">
              <value type="string" value="Workspace 1"/>
              <value type="string" value="Workspace 2"/>
              <value type="string" value="Workspace 3"/>
              <value type="string" value="Workspace 4"/>
            </property>
          </property>
        </channel>
      '';

      # Configure appearance
      ".config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xsettings" version="1.0">
          <property name="Net" type="empty">
            <property name="ThemeName" type="string" value="Materia-dark"/>
            <property name="IconThemeName" type="string" value="Papirus-Dark"/>
            <property name="EnableEventSounds" type="bool" value="true"/>
            <property name="EnableInputFeedbackSounds" type="bool" value="false"/>
          </property>
          <property name="Gtk" type="empty">
            <property name="CursorThemeName" type="string" value="Adwaita"/>
            <property name="CursorThemeSize" type="int" value="24"/>
            <property name="DecorationLayout" type="string" value="menu:minimize,maximize,close"/>
            <property name="FontName" type="string" value="Noto Sans 10"/>
            <property name="MonospaceFontName" type="string" value="Fira Code 10"/>
            <property name="IconSizes" type="string" value="gtk-menu=24,24:gtk-button=16,16"/>
            <property name="KeyThemeName" type="string" value="Default"/>
            <property name="ToolbarStyle" type="string" value="icons"/>
          </property>
          <property name="Xft" type="empty">
            <property name="Antialias" type="int" value="1"/>
            <property name="HintStyle" type="string" value="hintslight"/>
            <property name="RGBA" type="string" value="rgb"/>
            <property name="Lcdfilter" type="string" value="lcddefault"/>
          </property>
        </channel>
      '';
      
      # Configure whisker menu - using XFCE's built-in terminal as a fallback
      ".config/xfce4/panel/whiskermenu-1.rc".text = ''
        favorites=firefox.desktop,Thunar.desktop,xfce4-terminal.desktop
        recent=
        button-title=Applications
        button-icon=start-here
        button-single-row=false
        show-button-title=false
        show-button-icon=true
        launcher-show-name=true
        launcher-show-description=true
        launcher-show-tooltip=true
        item-icon-size=2
        hover-switch-category=false
        category-show-name=true
        category-icon-size=1
        sort-categories=true
        view-mode=1
        default-category=0
        recent-items-max=10
        favorites-in-recent=true
        position-search-alternate=false
        position-commands-alternate=false
        position-categories-alternate=false
        stay-on-focus-out=false
        confirm-session-command=true
        menu-width=450
        menu-height=500
        menu-opacity=100
        command-settings=xfce4-settings-manager
        show-command-settings=true
        command-lockscreen=xflock4
        show-command-lockscreen=true
        command-switchuser=dm-tool switch-to-greeter
        show-command-switchuser=false
        command-logoutuser=xfce4-session-logout --logout --fast
        show-command-logoutuser=false
        command-restart=xfce4-session-logout --reboot --fast
        show-command-restart=false
        command-shutdown=xfce4-session-logout --halt --fast
        show-command-shutdown=false
        command-suspend=xfce4-session-logout --suspend
        show-command-suspend=false
        command-hibernate=xfce4-session-logout --hibernate
        show-command-hibernate=false
        command-logout=xfce4-session-logout
        show-command-logout=true
        command-menueditor=menulibre
        show-command-menueditor=false
        command-profile=mugshot
        show-command-profile=false
        search-actions=5
      '';
    };
    
    # Set XFCE as the default session
    xdg.configFile."autostart/set-xfce-theme.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Set XFCE Theme
      Exec=sh -c 'xfconf-query -c xsettings -p /Net/ThemeName -s "Materia-dark" || true; xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark" || true; xfconf-query -c xfwm4 -p /general/theme -s "Materia-dark" || true; xfconf-query -c xfwm4 -p /general/button_layout -s "O|HMC" || true'
      Terminal=false
      NoDisplay=true
      X-GNOME-Autostart-enabled=true
    '';
    
    # Set home directory
    home.stateVersion = "23.11";
  };
  
  # Create a custom background for Bloom Nix - using more robust approach
  system.activationScripts.bloomBackground = ''
    mkdir -p /run/current-system/sw/share/backgrounds/
    
    # Create a default wallpaper with a solid color if nothing else is available
    cat > /run/current-system/sw/share/backgrounds/bloom-nix-wallpaper.svg << 'EOF'
    <svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
      <rect width="1920" height="1080" fill="#1a1a1a"/>
      <text x="960" y="540" font-family="sans-serif" font-size="64" text-anchor="middle" fill="#5294e2">Bloom Nix</text>
    </svg>
    EOF
    
    # Set it as the default wallpaper
    ln -sf /run/current-system/sw/share/backgrounds/bloom-nix-wallpaper.svg /run/current-system/sw/share/backgrounds/bloom-nix-wallpaper.jpg || true
  '';
  
  # Create a default icon using built-in XFCE resources to avoid dependency on SVG rendering
  environment.variables = {
    # Set a default icon from the system that's guaranteed to exist
    XFCE_PANEL_BLOOM_ICON = "start-here";
  };
}
