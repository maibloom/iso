# Scientific computing profile for Bloom Nix
{ config, lib, pkgs, ... }:

{
  imports = [
    # Include default profile
    ./default.nix
  ];
  
  # Scientific computing packages
  environment.systemPackages = with pkgs; [
    # Mathematics and statistics
    R
    rstudio
    octave
    gnuplot
    sage
    maxima
    wxmaxima
    
    # Python scientific stack
    python3
    python3Packages.numpy
    python3Packages.scipy
    python3Packages.matplotlib
    python3Packages.pandas
    python3Packages.sympy
    python3Packages.jupyter
    python3Packages.jupyterlab
    python3Packages.scikit-learn
    python3Packages.tensorflow
    python3Packages.pytorch
    python3Packages.seaborn
    python3Packages.statsmodels
    python3Packages.nltk
    python3Packages.networkx
    
    # Data analysis and visualization
    gephi
    orange3
    gnuplot
    paraview
    
    # Chemistry
    avogadro
    openbabel
    
    # Physics
    root
    
    # Astronomy
    stellarium
    celestia
    
    # Geographic Information Systems
    qgis
    
    # Bioinformatics
    biopython
    clustal-omega
    
    # LaTeX for scientific writing
    texlive.combined.scheme-full
    texmaker
    jabref
    
    # Document tools
    zotero
    pandoc
    
    # Other utilities
    imagemagick
    ghostscript
    ffmpeg
  ];
  
  # Add CUDA support for scientific computing
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
    vaapiVdpau
    libvdpau-va-gl
  ];
  
  # Enable high performance computing features
  security.pam.loginLimits = [
    # Increase stack size for computational workloads
    { domain = "*"; type = "soft"; item = "stack"; value = "unlimited"; }
    { domain = "*"; type = "hard"; item = "stack"; value = "unlimited"; }
    # Increase max memory for large computations
    { domain = "*"; type = "soft"; item = "memlock"; value = "unlimited"; }
    { domain = "*"; type = "hard"; item = "memlock"; value = "unlimited"; }
  ];
  
  # Julia language support
  environment.variables = {
    JULIA_DEPOT_PATH = "$HOME/.julia:/nix/store";
  };
  
  # Add additional fonts needed for publications
  fonts.packages = with pkgs; [
    lato
    fira
    fira-code
    fira-code-symbols
    cm_unicode
    libertine
    libertinus
    junicode
    dejavu_fonts
    noto-fonts
    noto-fonts-extra
    noto-fonts-cjk
    noto-fonts-emoji
  ];
  
  # Configure BLAS/LAPACK for better performance
  nixpkgs.config.packageOverrides = pkgs: {
    blas = pkgs.blas.override {
      blasProvider = pkgs.openblas;
    };
    lapack = pkgs.lapack.override {
      lapackProvider = pkgs.openblas;
    };
  };
  
  # Optimize system for compute-intensive tasks
  boot.kernel.sysctl = {
    # Increase memory available for file system caches
    "vm.vfs_cache_pressure" = 50;
    # Decrease swappiness to favor RAM over swap
    "vm.swappiness" = 10;
  };
  
  # Add virtual memory tuning for large dataset processing
  boot.kernel.sysctl."vm.max_map_count" = 262144;
  
  # Enable CPU frequency scaling for better performance
  services.thermald.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
}
