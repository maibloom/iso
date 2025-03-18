# modules/desktop/xfce.nix
{ config, lib, pkgs, ... }:

{
  # Enable X11 windowing system with XFCE
  services.xserver = {
    enable = true;
    
    # Enable XFCE
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
    
    # Set default session
    displayManager.defaultSession = "xfce";
  };
  
  # Install a comprehensive set of packages for a modern XFCE experience
  environment.systemPackages = with pkgs; [
    # XFCE core improvements
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.tumbler  # For thumbnails
    xfce.xfce4-battery-plugin
    xfce.xfce4-clipman-plugin
    xfce.xfce4-cpugraph-plugin
    xfce.xfce4-dict
    xfce.xfce4-netload-plugin
    xfce.xfce4-notes-plugin
    xfce.xfce4-sensors-plugin
    xfce.xfce4-weather-plugin
    xfce.xfce4-whiskermenu-plugin  # Modern application menu
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-screenshooter
    xfce.xfce4-systemload-plugin
    # xfce.xfce4-places-plugin
    
    # Modern XFCE themes
    arc-theme
    paper-icon-theme
    papirus-icon-theme
    
    # Additional desktop utilities for improved user experience
    plank  # Dock
    ulauncher  # Modern application launcher
    volumeicon  # Volume control in system tray
    networkmanagerapplet  # Network management
    blueman  # Bluetooth management
    
    # Modern applications
    firefox
    ungoogled-chromium
    brave
    thunderbird
    libreoffice
    evince  # PDF viewer
    gnome.eog  # Image viewer
    vlc  # Video player
    celluloid  # Modern GTK video player
    foliate  # E-book reader
    gnome.gnome-calculator
    gnome.gnome-calendar
    gnome.gnome-disk-utility
    gnome.gnome-system-monitor
    
    # File management improvements
    gvfs  # For trash and network mounts
    gnome.file-roller  # Archive manager
    gnome.gnome-font-viewer
    
    # Development tools
    vscode
    vim wget git
    libgcc rustup
    
    # System utilities
    # gufw  # Firewall configuration
    gparted  # Disk partitioning
    htop  # System monitor
    inxi  # System information
    neofetch  # System info with logo
    
    # For creating a cohesive look
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    lxappearance  # Theme configuration
  ];
  
  # Configure a modern theme for XFCE with Bloom Nix colors
  environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xsettings" version="1.0">
      <property name="Net" type="empty">
        <property name="ThemeName" value="Arc-Dark"/>
        <property name="IconThemeName" value="Papirus-Dark"/>
        <property name="EnableEventSounds" type="bool" value="true"/>
        <property name="EnableInputFeedbackSounds" type="bool" value="false"/>
      </property>
      <property name="Xft" type="empty">
        <property name="DPI" type="int" value="-1"/>
        <property name="Antialias" type="int" value="1"/>
        <property name="Hinting" type="int" value="1"/>
        <property name="HintStyle" type="string" value="hintslight"/>
        <property name="RGBA" type="string" value="rgb"/>
      </property>
      <property name="Gtk" type="empty">
        <property name="CursorThemeName" value="Adwaita"/>
        <property name="CursorThemeSize" type="int" value="24"/>
        <property name="DecorationLayout" value="menu:minimize,maximize,close"/>
        <property name="FontName" value="Noto Sans 10"/>
        <property name="MonospaceFontName" value="Noto Sans Mono 10"/>
        <property name="IconSizes" value="gtk-menu=16,16:gtk-button=16,16"/>
        <property name="KeyThemeName" value="Default"/>
        <property name="ToolbarStyle" value="icons"/>
        <property name="ToolbarIconSize" value="2"/>
        <property name="MenuImages" type="bool" value="true"/>
        <property name="ButtonImages" type="bool" value="true"/>
        <property name="MenuBarAccel" value="F10"/>
        <property name="CursorBlinkTime" type="int" value="1200"/>
        <property name="CursorBlinkTimeout" type="int" value="10"/>
        <property name="ColorPalette" value="black:#454d6e:#f1efee:#999a5e:#989cad:#ab6470:cyan:white:gray:red:green:yellow:blue:magenta:cyan:white"/>
        <property name="ColorScheme" value=""/>
        <property name="CanChangeAccels" type="bool" value="true"/>
      </property>
    </channel>
  '';
  
  # Configure modern panel layout
  environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4-panel" version="1.0">
      <property name="configver" type="int" value="2"/>
      <property name="panels" type="array">
        <value type="int" value="1"/>
        <property name="dark-mode" type="bool" value="true"/>
        <property name="panel-1" type="empty">
          <property name="position" type="string" value="p=8;x=960;y=1055"/>
          <property name="length" type="uint" value="100"/>
          <property name="position-locked" type="bool" value="true"/>
          <property name="icon-size" type="uint" value="24"/>
          <property name="size" type="uint" value="40"/>
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
          </property>
          <property name="background-style" type="uint" value="1"/>
          <property name="background-rgba" type="array">
            <value type="double" value="0.27"/>
            <value type="double" value="0.30"/>
            <value type="double" value="0.43"/>
            <value type="double" value="1.0"/>
          </property>
        </property>
      </property>
      <property name="plugins" type="empty">
        <property name="plugin-1" type="string" value="whiskermenu"/>
        <property name="plugin-2" type="string" value="separator"/>
        <property name="plugin-3" type="string" value="tasklist"/>
        <property name="plugin-4" type="string" value="separator"/>
        <property name="plugin-5" type="string" value="systray"/>
        <property name="plugin-6" type="string" value="pulseaudio"/>
        <property name="plugin-7" type="string" value="power-manager-plugin"/>
        <property name="plugin-8" type="string" value="notification-plugin"/>
        <property name="plugin-9" type="string" value="separator"/>
        <property name="plugin-10" type="string" value="clock"/>
        <property name="plugin-11" type="string" value="actions"/>
      </property>
    </channel>
  '';
  
  # Configure Whisker Menu
  environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-whiskermenu-plugin.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4-whiskermenu-plugin" version="1.0">
      <property name="button-icon" type="string" value="bloom-nix-logo"/>
      <property name="button-title" type="string" value="Bloom Nix"/>
      <property name="command-settings" type="string" value="xfce4-settings-manager"/>
      <property name="favorites" type="array">
        <value type="string" value="firefox.desktop"/>
        <value type="string" value="xfce4-terminal.desktop"/>
        <value type="string" value="thunar.desktop"/>
        <value type="string" value="libreoffice-writer.desktop"/>
        <value type="string" value="xfce4-settings-manager.desktop"/>
      </property>
      <property name="menu-width" type="int" value="450"/>
      <property name="menu-height" type="int" value="500"/>
      <property name="profile-picture" type="bool" value="true"/>
      <property name="search-actions" type="bool" value="true"/>
      <property name="position-categories-alternate" type="bool" value="false"/>
      <property name="position-commands-alternate" type="bool" value="false"/>
      <property name="position-search-alternate" type="bool" value="false"/>
      <property name="stay-on-focus-out" type="bool" value="false"/>
      <property name="confirm-session-command" type="bool" value="true"/>
      <property name="load-hierarchy" type="bool" value="true"/>
      <property name="launcher-show-name" type="bool" value="true"/>
    </channel>
  '';
  
  # Configure Thunar file manager
  environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/thunar.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="thunar" version="1.0">
      <property name="last-view" type="string" value="ThunarIconView"/>
      <property name="last-icon-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_100_PERCENT"/>
      <property name="last-window-width" type="int" value="1024"/>
      <property name="last-window-height" type="int" value="768"/>
      <property name="last-show-hidden" type="bool" value="false"/>
      <property name="misc-single-click" type="bool" value="false"/>
      <property name="misc-thumbnail-mode" type="string" value="THUNAR_THUMBNAIL_MODE_ALWAYS"/>
      <property name="shortcuts-icon-size" type="string" value="THUNAR_ICON_SIZE_24"/>
      <property name="misc-text-beside-icons" type="bool" value="false"/>
      <property name="misc-date-style" type="string" value="THUNAR_DATE_STYLE_SIMPLE"/>
      <property name="misc-folders-first" type="bool" value="true"/>
      <property name="misc-folder-item-count" type="string" value="THUNAR_FOLDER_ITEM_COUNT_ALWAYS"/>
      <property name="last-separator-position" type="int" value="170"/>
      <property name="tree-icon-size" type="string" value="THUNAR_ICON_SIZE_16"/>
      <property name="misc-directory-specific-settings" type="bool" value="true"/>
    </channel>
  '';
  
  # Configure desktop background and icons
  environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4-desktop" version="1.0">
      <property name="backdrop" type="empty">
        <property name="screen0" type="empty">
          <property name="monitor0" type="empty">
            <property name="workspace0" type="empty">
              <property name="color-style" type="int" value="0"/>
              <property name="image-style" type="int" value="5"/>
              <property name="last-image" type="string" value="/etc/bloom-nix/backgrounds/default.jpg"/>
            </property>
          </property>
        </property>
      </property>
      <property name="desktop-icons" type="empty">
        <property name="icon-size" type="uint" value="48"/>
        <property name="file-icons" type="empty">
          <property name="show-home" type="bool" value="true"/>
          <property name="show-filesystem" type="bool" value="false"/>
          <property name="show-trash" type="bool" value="true"/>
          <property name="show-removable" type="bool" value="true"/>
        </property>
      </property>
    </channel>
  '';
  
  # Configure the window manager
  environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfwm4" version="1.0">
      <property name="general" type="empty">
        <property name="activate_action" type="string" value="bring"/>
        <property name="borderless_maximize" type="bool" value="true"/>
        <property name="box_move" type="bool" value="false"/>
        <property name="box_resize" type="bool" value="false"/>
        <property name="button_layout" type="string" value="O|SHMC"/>
        <property name="button_offset" type="int" value="0"/>
        <property name="button_spacing" type="int" value="0"/>
        <property name="click_to_focus" type="bool" value="true"/>
        <property name="cycle_apps_only" type="bool" value="false"/>
        <property name="cycle_draw_frame" type="bool" value="true"/>
        <property name="cycle_hidden" type="bool" value="true"/>
        <property name="cycle_minimum" type="bool" value="true"/>
        <property name="cycle_preview" type="bool" value="true"/>
        <property name="cycle_tabwin_mode" type="int" value="0"/>
        <property name="cycle_workspaces" type="bool" value="false"/>
        <property name="double_click_action" type="string" value="maximize"/>
        <property name="double_click_distance" type="int" value="5"/>
        <property name="double_click_time" type="int" value="250"/>
        <property name="easy_click" type="string" value="Alt"/>
        <property name="focus_delay" type="int" value="250"/>
        <property name="focus_hint" type="bool" value="true"/>
        <property name="focus_new" type="bool" value="true"/>
        <property name="frame_opacity" type="int" value="100"/>
        <property name="full_width_title" type="bool" value="true"/>
        <property name="horiz_scroll_opacity" type="bool" value="false"/>
        <property name="inactive_opacity" type="int" value="100"/>
        <property name="maximized_offset" type="int" value="0"/>
        <property name="mousewheel_rollup" type="bool" value="true"/>
        <property name="move_opacity" type="int" value="100"/>
        <property name="placement_mode" type="string" value="center"/>
        <property name="placement_ratio" type="int" value="20"/>
        <property name="popup_opacity" type="int" value="100"/>
        <property name="prevent_focus_stealing" type="bool" value="false"/>
        <property name="raise_delay" type="int" value="250"/>
        <property name="raise_on_click" type="bool" value="true"/>
        <property name="raise_on_focus" type="bool" value="false"/>
        <property name="raise_with_any_button" type="bool" value="true"/>
        <property name="repeat_urgent_blink" type="bool" value="false"/>
        <property name="resize_opacity" type="int" value="100"/>
        <property name="scroll_workspaces" type="bool" value="true"/>
        <property name="shadow_delta_height" type="int" value="0"/>
        <property name="shadow_delta_width" type="int" value="0"/>
        <property name="shadow_delta_x" type="int" value="0"/>
        <property name="shadow_delta_y" type="int" value="-3"/>
        <property name="shadow_opacity" type="int" value="50"/>
        <property name="show_app_icon" type="bool" value="false"/>
        <property name="show_dock_shadow" type="bool" value="false"/>
        <property name="show_frame_shadow" type="bool" value="true"/>
        <property name="show_popup_shadow" type="bool" value="true"/>
        <property name="snap_resist" type="bool" value="false"/>
        <property name="snap_to_border" type="bool" value="true"/>
        <property name="snap_to_windows" type="bool" value="true"/>
        <property name="snap_width" type="int" value="10"/>
        <property name="theme" type="string" value="Arc-Dark"/>
        <property name="title_alignment" type="string" value="center"/>
        <property name="title_font" type="string" value="Noto Sans Bold 10"/>
        <property name="title_horizontal_offset" type="int" value="0"/>
        <property name="titleless_maximize" type="bool" value="false"/>
        <property name="title_shadow_active" type="string" value="false"/>
        <property name="title_shadow_inactive" type="string" value="false"/>
        <property name="title_vertical_offset_active" type="int" value="0"/>
        <property name="title_vertical_offset_inactive" type="int" value="0"/>
        <property name="toggle_workspaces" type="bool" value="false"/>
        <property name="unredirect_overlays" type="bool" value="true"/>
        <property name="use_compositing" type="bool" value="true"/>
        <property name="workspace_count" type="int" value="4"/>
        <property name="wrap_cycle" type="bool" value="true"/>
        <property name="wrap_layout" type="bool" value="true"/>
        <property name="wrap_resistance" type="int" value="10"/>
        <property name="wrap_windows" type="bool" value="true"/>
        <property name="wrap_workspaces" type="bool" value="false"/>
        <property name="zoom_desktop" type="bool" value="true"/>
        <property name="zoom_pointer" type="bool" value="true"/>
        <property name="margin_top" type="int" value="0"/>
        <property name="margin_left" type="int" value="0"/>
        <property name="margin_right" type="int" value="0"/>
        <property name="margin_bottom" type="int" value="0"/>
        <property name="workspace_names" type="array">
          <value type="string" value="Workspace 1"/>
          <value type="string" value="Workspace 2"/>
          <value type="string" value="Workspace 3"/>
          <value type="string" value="Workspace 4"/>
        </property>
      </property>
    </channel>
  '';
  
  # Create a custom Gtk theme based on Bloom Nix colors
  environment.etc."bloom-nix/gtk-theme/gtk.css".text = ''
    /* Bloom Nix GTK3 Theme customizations */
    @define-color bg_color #454d6e;
    @define-color fg_color #f1efee;
    @define-color base_color #353d5e;
    @define-color text_color #f1efee;
    @define-color selected_bg_color #ab6470;
    @define-color selected_fg_color #f1efee;
    @define-color tooltip_bg_color #454d6e;
    @define-color tooltip_fg_color #f1efee;
    @define-color accent_color #999a5e;
    @define-color secondary_color #989cad;
    
    /* Override Arc-Dark theme with our colors */
    .thunar .standard-view .view {
      background-color: @base_color;
      color: @text_color;
    }
    
    .thunar .sidebar {
      background-color: @bg_color;
    }
    
    .xfce4-panel {
      background-color: @bg_color;
    }
    
    window.xfce4-panel widget > box > button {
      color: @fg_color;
    }
    
    .xfce4-panel button:hover {
      background-color: shade(@bg_color, 1.2);
    }
    
    #whiskermenu-button {
      background-color: @accent_color;
      color: @fg_color;
      padding: 3px;
    }
    
    /* Improve selected items visibility */
    .view:selected {
      background-color: @selected_bg_color;
      color: @selected_fg_color;
    }
    
    /* Fix links color */
    *:link {
      color: @accent_color;
    }
    
    /* Improve buttons appearance */
    button {
      background-image: none;
      background-color: @bg_color;
      color: @fg_color;
      border: 1px solid shade(@bg_color, 0.8);
      border-radius: 4px;
      padding: 4px 8px;
    }
    
    button:hover {
      background-color: shade(@bg_color, 1.1);
    }
    
    button:active {
      background-color: @accent_color;
      color: @fg_color;
    }
    
    /* Make headerbar match our colors */
    headerbar, .titlebar {
      background-color: @bg_color;
      color: @fg_color;
      border-bottom: 1px solid shade(@bg_color, 0.8);
      padding: 6px;
    }
  '';
  
  # Add a custom gtk-3.0 settings file to load our theme
  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=1
    gtk-theme-name=Arc-Dark
    gtk-icon-theme-name=Papirus-Dark
    gtk-font-name=Noto Sans 10
    gtk-cursor-theme-name=Adwaita
    gtk-cursor-theme-size=16
    gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
    gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
    gtk-button-images=1
    gtk-menu-images=1
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=0
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintslight
    gtk-xft-rgba=rgb
  '';
  
  # Customize lightdm greeter with Bloom Nix branding
  services.xserver.displayManager.lightdm.greeters.gtk = {
    enable = true;
    theme.name = "Arc-Dark";
    iconTheme.name = "Papirus-Dark";
    cursorTheme.name = "Adwaita";
    clock-format = "%H:%M";
    indicators = [ "~host" "~spacer" "~clock" "~spacer" "~session" "~power" ];
    extraConfig = ''
      [greeter]
      background = /etc/bloom-nix/backgrounds/login.jpg
      background-color = #454d6e
      theme-name = Arc-Dark
      icon-theme-name = Papirus-Dark
      font-name = Noto Sans 10
      xft-antialias = true
      xft-dpi = 96
      xft-hintstyle = hintslight
      xft-rgba = rgb
      position = 50%,center 50%,center
      panel-position = top
      clock-format = %a, %b %d  %H:%M
      indicators = ~host;~spacer;~clock;~spacer;~layout;~session;~a11y;~power
      user-background = false
      hide-user-image = false
      
      [greeter-hotkeys]
      mod-key = meta
      shutdown-key = s
      restart-key = r
      hibernate-key = h
      suspend-key = u
      
      [greeter-theme]
      panel-bg-color = #454d6e
      panel-fg-color = #f1efee
      error-bg-color = #ab6470
      error-fg-color = #f1efee
      panel-error-color = #ab6470
      success-bg-color = #999a5e
      success-fg-color = #f1efee
      panel-success-color = #999a5e
    '';
  };
  
  # Set up Plank dock for a more modern feel
  environment.etc."xdg/autostart/plank.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Plank
    Comment=Dock for Bloom Nix
    Exec=plank
    Icon=plank
    Terminal=false
    NoDisplay=false
    X-GNOME-Autostart-enabled=true
  '';
  
  # Configure default Plank settings
  environment.etc."xdg/plank/dock1/settings".text = ''
    [PlankDockPreferences]
    #Whether to show only windows of the current workspace.
    CurrentWorkspaceOnly=false
    #The size of dock icons (in pixels).
    IconSize=48
    #If 0, the dock won't hide. If 1, the dock intelligently hides. If 2, the dock auto-hides. If 3, the dock dodges active maximized windows. If 4, the dock dodges every window.
    HideMode=1
    #Time (in ms) to wait before hiding the dock.
    HideDelay=500
    #Time (in ms) to wait before showing the dock.
    ShowDelay=200
    #The monitor number for the dock. If -1, primary monitor is used.
    Monitor=-1
    #List of *.dockitem files on this dock. DO NOT MODIFY
    DockItems=firefox.dockitem;;thunar.dockitem;;xfce4-terminal.dockitem;;libreoffice-writer.dockitem;;xfce4-settings-manager.dockitem
    #The position for the dock on the monitor. If 0, left. If 1, right. If 2, top. If 3, bottom.
    Position=3
    #The dock's position offset from center (in percent).
    Offset=0
    #The name of the dock's theme to use.
    Theme=Bloom
    #The alignment for the dock on the monitor's edge. If 0, panel-mode (left or right edge). If 1, left-aligned. If 2, right-aligned. If 3, centered.
    Alignment=3
    #Whether to prevent drag'n'drop actions and lock items on the dock.
    LockItems=false
    #Whether to use pressure-based revealing of the dock if the support is available.
    PressureReveal=false
    #Whether to show only pinned applications.
    PinnedOnly=false
    #Whether to automatically pin an application if it seems useful to do.
    AutoPinning=true
    #Whether to show the item for the dock itself.
    ShowDockItem=false
    #Whether the dock will zoom when hovered.
    ZoomEnabled=true
    #The dock's icon-zoom (in percent).
    ZoomPercent=150
  '';
  
  # Create custom Plank theme
  environment.etc."xdg/plank/themes/Bloom/dock.theme".text = ''
    [PlankTheme]
    #The roundness of the top corners.
    TopRoundness=4
    #The roundness of the bottom corners.
    BottomRoundness=0
    #The thickness (in pixels) of lines drawn.
    LineWidth=1
    #The color (RGBA) of the outer stroke.
    OuterStrokeColor=0;;0;;0;;100
    #The starting color (RGBA) of the fill gradient.
    FillStartColor=69;;77;;110;;215
    #The ending color (RGBA) of the fill gradient.
    FillEndColor=53;;61;;94;;215
    #The color (RGBA) of the inner stroke.
    InnerStrokeColor=69;;77;;110;;245
  '';
  
  # Create Plank launcher items for common applications
  environment.etc."xdg/plank/dock1/launchers/firefox.dockitem".text = ''
    [PlankDockItemPreferences]
    Launcher=file:///run/current-system/sw/share/applications/firefox.desktop
  '';
  
  environment.etc."xdg/plank/dock1/launchers/thunar.dockitem".text = ''
    [PlankDockItemPreferences]
    Launcher=file:///run/current-system/sw/share/applications/thunar.desktop
  '';
  
  environment.etc."xdg/plank/dock1/launchers/xfce4-terminal.dockitem".text = ''
    [PlankDockItemPreferences]
    Launcher=file:///run/current-system/sw/share/applications/xfce4-terminal.desktop
  '';
  
  environment.etc."xdg/plank/dock1/launchers/libreoffice-writer.dockitem".text = ''
    [PlankDockItemPreferences]
    Launcher=file:///run/current-system/sw/share/applications/libreoffice-writer.desktop
  '';
  
  environment.etc."xdg/plank/dock1/launchers/xfce4-settings-manager.dockitem".text = ''
    [PlankDockItemPreferences]
    Launcher=file:///run/current-system/sw/share/applications/xfce4-settings-manager.desktop
  '';
  
  # Configure sound properly
  hardware.pulseaudio.enable = false;
  
  # Set default browser
  environment.variables = {
    BROWSER = "brave";
    DEFAULT_BROWSER = "brave";
  };
  
  # Create custom backgrounds directory
  system.activationScripts.bloombrandingXfce = ''
    mkdir -p /etc/bloom-nix/backgrounds
    mkdir -p /etc/bloom-nix/icons
    
    # Create a simple colored background if none exists yet
    if [ ! -f /etc/bloom-nix/backgrounds/default.jpg ]; then
      ${pkgs.imagemagick}/bin/convert -size 1920x1080 canvas:#454d6e /etc/bloom-nix/backgrounds/default.jpg
    fi
    
    if [ ! -f /etc/bloom-nix/backgrounds/login.jpg ]; then
      ${pkgs.imagemagick}/bin/convert -size 1920x1080 canvas:#353d5e /etc/bloom-nix/backgrounds/login.jpg
    fi
    
    # Create a simple Bloom Nix logo if none exists
    if [ ! -f /etc/bloom-nix/icons/bloom-nix-logo.png ]; then
      ${pkgs.imagemagick}/bin/convert -size 128x128 canvas:#353d5e -fill "#f1efee" -draw "circle 64,64 64,32" -fill "#ab6470" -draw "circle 64,64 32,64" /etc/bloom-nix/icons/bloom-nix-logo.png
    fi
    
    # Copy logo to system locations
    cp -f /etc/bloom-nix/icons/bloom-nix-logo.png /usr/share/icons/hicolor/128x128/apps/ || true
    
    # Load our custom GTK CSS
    mkdir -p /etc/xdg/gtk-3.0/
    if [ -f /etc/bloom-nix/gtk-theme/gtk.css ]; then
      cat /etc/bloom-nix/gtk-theme/gtk.css >> /etc/xdg/gtk-3.0/gtk.css
    fi
  '';
}
