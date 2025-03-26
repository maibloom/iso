# Development profile for Bloom Nix
{ config, lib, pkgs, ... }:

{
  imports = [
    # Include default profile
    ./default.nix
  ];
  
  # Development-specific packages
  environment.systemPackages = with pkgs; [
    # IDEs and editors
    vscode
    jetbrains.idea-community
    emacs
    neovim
    
    # Version control
    git
    gitui
    git-lfs
    mercurial
    subversion
    
    # Build tools
    gnumake
    cmake
    ninja
    meson
    
    # Compilers and interpreters
    gcc
    clang
    rustup
    go
    nodejs
    yarn
    python3
    python3Packages.pip
    python3Packages.setuptools
    python3Packages.wheel
    jdk
    php
    ruby
    
    # Debugging and analysis
    gdb
    lldb
    strace
    valgrind
    
    # Docker and containers
    docker
    docker-compose
    podman
    
    # Database tools
    dbeaver
    postgresql
    sqlite
    redis
    
    # Network tools
    curl
    wget
    postman
    wireshark
    
    # Documentation
    zeal
    man-pages
    man-pages-posix
    
    # Utilities
    jq
    yq
    ripgrep
    fd
    bat
    exa
    fzf
    direnv
    
    # LaTeX for documentation
    texlive.combined.scheme-full
  ];
  
  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
  
  # Enable virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      ovmf.enable = true;
      runAsRoot = true;
    };
  };
  virtualisation.virtualbox.host.enable = true;
  
  # Fix SSH through NAT
  networking.extraHosts = ''
    # For local development
    127.0.0.1 local.bloom-nix.org
    127.0.0.1 api.local.bloom-nix.org
    127.0.0.1 db.local.bloom-nix.org
  '';
  
  # GitHub integration
  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      Host github.com
        IdentityFile ~/.ssh/github
        User git
    '';
  };
  
  # Development shell enhancements
  programs.bash.enableCompletion = true;
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };
  
  # Add development-focused user to specific groups
  users.users.bloom.extraGroups = [ 
    "docker" 
    "libvirtd"
    "vboxusers"
    "wireshark"
  ];
  
  # Configure shell environment
  environment.shellAliases = {
    ll = "ls -la";
    grep = "grep --color=auto";
    gs = "git status";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
  };
  
  # Increase max number of file watchers (needed for large projects)
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
  };
  
  # Optimize system for development workloads
  nix.settings = {
    max-jobs = "auto";
    cores = 0;
    sandbox = true;
  };
  
  # Configure locale for development
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "en_GB.UTF-8/UTF-8"
    ];
  };
}
