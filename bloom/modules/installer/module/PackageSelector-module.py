#!/usr/bin/env python3
# packageSelector.py - Calamares module for package group selection
# This module allows the user to select package groups to install

import os
import libcalamares
from libcalamares.utils import debug, warning
import yaml

def pretty_name():
    return "Select package categories"

def pretty_status_message():
    return "Configuring package selection..."

class PackageGroup:
    def __init__(self, group_id, name, description, packages):
        self.id = group_id
        self.name = name
        self.description = description
        self.packages = packages
        self.selected = False

def parse_config():
    # Read the module configuration
    config = libcalamares.job.configuration
    
    # Parse package groups
    groups = []
    for group in config.get("packageGroups", []):
        groups.append(PackageGroup(
            group.get("id", ""),
            group.get("name", ""),
            group.get("description", ""),
            group.get("packages", [])
        ))
    
    return groups

def run():
    # Get configuration
    groups = parse_config()
    
    # Create a viewdata structure for the QML UI
    viewdata = {
        "groups": [
            {
                "id": group.id,
                "name": group.name,
                "description": group.description,
                "packages": group.packages
            }
            for group in groups
        ]
    }
    
    # Pass the viewdata to the QML interface
    libcalamares.globalstorage.insert("packageSelectorViewData", viewdata)
    
    return None

def run_operations():
    # Get selected packages from global storage
    selected_groups = libcalamares.globalstorage.value("selectedPackageGroups") or []
    
    # Get all package groups
    groups = parse_config()
    
    # Collect packages from selected groups
    packages_to_install = []
    for group in groups:
        if group.id in selected_groups:
            packages_to_install.extend(group.packages)
    
    # Add packages to global storage for the packages module to use
    current_packages = libcalamares.globalstorage.value("packageOperations") or {"install": []}
    
    # Ensure we have the install list
    if "install" not in current_packages:
        current_packages["install"] = []
    
    # Add our packages
    current_packages["install"].extend(packages_to_install)
    
    # Update global storage
    libcalamares.globalstorage.insert("packageOperations", current_packages)
    
    return None
