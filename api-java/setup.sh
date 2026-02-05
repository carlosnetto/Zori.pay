#!/usr/bin/env bash
set -euo pipefail

# Zori.pay - Java API Setup Script
# Installs required dependencies via Homebrew (macOS)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

JAVA_VERSION=25
REQUIRED_TOOLS=("openjdk" "maven")

# --- Check macOS ---
if [[ "$(uname)" != "Darwin" ]]; then
    fail "This script is for macOS only. Adapt for your OS."
fi

# --- Check Homebrew ---
if ! command -v brew &>/dev/null; then
    fail "Homebrew not found. Install it from https://brew.sh"
fi

info "Homebrew found: $(brew --version | head -1)"

# --- Install OpenJDK ---
if brew list openjdk &>/dev/null; then
    INSTALLED_JAVA=$(/opt/homebrew/opt/openjdk/bin/java --version 2>&1 | head -1 | awk '{print $2}' | cut -d. -f1)
    if [[ "$INSTALLED_JAVA" -ge "$JAVA_VERSION" ]]; then
        info "OpenJDK $INSTALLED_JAVA already installed"
    else
        warn "OpenJDK $INSTALLED_JAVA found but Java $JAVA_VERSION+ required. Upgrading..."
        brew upgrade openjdk
    fi
else
    warn "OpenJDK not found. Installing..."
    brew install openjdk
fi

# --- Symlink for system Java wrappers ---
JDK_LINK="/Library/Java/JavaVirtualMachines/openjdk.jdk"
if [[ ! -L "$JDK_LINK" ]]; then
    warn "System JDK symlink missing. Run manually:"
    echo "  sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk $JDK_LINK"
fi

# --- Ensure java is on PATH ---
if ! command -v java &>/dev/null; then
    warn "java not on PATH. Add to your shell profile:"
    echo '  export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"'
fi

# --- Install GraalVM (for native image builds) ---
if brew list --cask graalvm-jdk@25 &>/dev/null; then
    info "GraalVM JDK 25 already installed"
else
    warn "GraalVM JDK 25 not found. Installing..."
    brew install --cask graalvm-jdk@25
fi

GRAALVM_HOME="/Library/Java/JavaVirtualMachines/graalvm-25.jdk/Contents/Home"
if [[ -d "$GRAALVM_HOME" ]]; then
    info "GraalVM home: $GRAALVM_HOME"
    if ! grep -q "GRAALVM_HOME" ~/.zshrc 2>/dev/null; then
        warn "Add to your shell profile for native builds:"
        echo "  export GRAALVM_HOME=$GRAALVM_HOME"
    fi
else
    warn "GraalVM home not found at expected path. Check: /Library/Java/JavaVirtualMachines/"
fi

# --- Install Maven ---
if brew list maven &>/dev/null; then
    info "Maven already installed: $(mvn --version 2>&1 | head -1)"
else
    warn "Maven not found. Installing..."
    brew install maven
fi

# --- Summary ---
echo ""
echo "================================="
echo " Environment"
echo "================================="
echo " OpenJDK:  $(java --version 2>&1 | head -1)"
echo " Maven:    $(mvn --version 2>&1 | head -1)"
if [[ -d "$GRAALVM_HOME" ]]; then
    echo " GraalVM:  $("$GRAALVM_HOME/bin/java" --version 2>&1 | head -1)"
    echo " Native:   mvn -Pnative clean package"
fi
echo "================================="
echo ""
info "Setup complete. Ready to build api-java."
