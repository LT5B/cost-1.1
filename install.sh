#!/bin/bash

clear

echo "  ::::    ::::      ::::    ::::::"
echo "::      ::    ::  ::          ::"
echo "::      ::    ::    ::::      ::"
echo "::      ::    ::        ::    ::"
echo "  ::::    ::::      ::::      ::"
echo ""
echo "Installing Cost..."
sleep 1

echo "Making folders..."
sudo mkdir -p "/opt/cost"
sudo mkdir -p "/opt/cost/bin"
sudo mkdir -p "/opt/cost/doc"
sudo mkdir -p "/opt/cost/cellar"
sudo mkdir -p "/opt/cost/libexec"
sudo mkdir -p "/opt/cost/flag"

# Fix: Get the actual user, even if the script is run with 'sudo'
ACTUAL_USER="${SUDO_USER:-$USER}"
sudo chown -R "$ACTUAL_USER" "/opt/cost"
sleep 1

echo "Making repository installer script..."
curl -sL -O https://www.kernel.org/pub/software/scm/git/git-2.55.0.tar.gz
tar zxf git-2.55.0.tar.gz
rm git-2.55.0.tar.gz
cd git-2.55.0
./Configure
cd ..
rm -rf git-2.55.0
sleep 1

echo "Making doc..."
cat << 'EOF' > "/opt/cost/doc/license.md"
# COST LICENSE

Copyright (c) 2026 LT5B

## 1. Permission

Permission is hereby granted, free of charge, to any person obtaining a copy of the `cost` Bash package and associated files (the "Software"), to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, subject to the conditions stated in this License.

## 2. Conditions

The following conditions apply:

* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* Modified versions of the Software must clearly indicate that changes have been made.
* The name "LT5B" shall not be used to endorse or promote products derived from the Software without prior written permission.

## 3. Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

IN NO EVENT SHALL LT5B BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## 4. Attribution

When the Software is redistributed or included in another project, reasonable attribution to **LT5B** and the `cost` Bash package is appreciated.

## 5. License Version

This license is the **COST License, Version 1.0**, created for the `cost` Bash package by **LT5B**.

Copyright (c) 2026 LT5B. All rights reserved.

EOF

cat << 'EOF' > "/opt/cost/doc/readme.md"
Cost

Cost is a Bash-based package management script designed to provide a simple and lightweight way to manage software packages directly from the command line.

Created by LT5B.

Features
📦 Simple package management
⚡ Lightweight Bash implementation
🖥️ Command-line interface
🔍 Search for available packages
📥 Install packages
🗑️ Remove packages
🔄 Update packages
📋 View package information
🧩 Designed to be easy to extend
🐧 Built for Unix-like environments

Philosophy

Cost is designed around three principles:

Simplicity
Package management should not require complicated commands.
Lightweight Design
Cost is implemented as a Bash script, keeping the project small and easy to inspect.
Ease of Use
Commands should be understandable and predictable for users.
Requirements

Cost requires:

Bash
A Unix-like operating system
Standard command-line utilities

Version

Current Project: Cost
Language: Bash
Creator: LT5B

Author

LT5B

Cost is an independent Bash project created to make package management more accessible through a simple command-line experience.

Cost — Simple package management, powered by Bash.
EOF

cat << 'EOF' > "/opt/cost/doc/help.md"
cost:

install: Install a package
uninstall: Remove a package
help: Show usage and flag information
license: Show license
readme: Show readme
package-readme: Show package readme
package-license: Show package license
version: Show cost version
set-version: Install old version or new version
EOF

cat << 'EOF' > "/opt/cost/doc/version.md"
Cost 1.1
EOF

sleep 1
echo "Making main executable file..."
cat << 'EOF' > "/opt/cost/bin/cost"
#!/bin/bash

if [ -z "$1" ]; then
    echo "Run 'cost help' to see the usage and flag information"
    exit 1
fi

if [ ! -f "/opt/cost/flag/$1" ]; then
    echo "Cost: Command not found: cost $1"
else
    bash "/opt/cost/flag/$1" "${@:2}"
fi
EOF
chmod +x "/opt/cost/bin/cost"

sleep 1
echo "Making flags..."

# --- UPDATED INSTALL FLAG LOGIC ---
cat << 'EOF' > "/opt/cost/flag/install"
#!/bin/bash

PACKAGE="$1"

if [ -z "$PACKAGE" ]; then
    echo "Usage: cost install <package> OR cost install <username/repo>"
    exit 1
fi

if [[ "$PACKAGE" == */* ]]; then
    REPO_URL="https://github.com/$PACKAGE"
    DIR_NAME="${PACKAGE#*/}"
else
    REPO_URL="https://github.com/$PACKAGE/$PACKAGE"
    DIR_NAME="$PACKAGE"
fi

echo "Cloning $REPO_URL..."
git clone "$REPO_URL" "$DIR_NAME"
if [ $? -ne 0 ]; then
    echo "Cost: Failed to clone repository."
    exit 1
fi

echo "Moving to /opt/cost/cellar/$DIR_NAME..."
# Clean up any previous broken installs of this package first
rm -rf "/opt/cost/cellar/$DIR_NAME"

# Move the folder, and throw an error immediately if permissions fail
mv "$DIR_NAME" "/opt/cost/cellar/$DIR_NAME" || { echo "Cost: Failed to move package to cellar. Try running with 'sudo cost install $PACKAGE'."; exit 1; }

echo "Running installer..."
# Exit immediately if cd fails
cd "/opt/cost/cellar/$DIR_NAME" || { echo "Cost: Failed to enter directory /opt/cost/cellar/$DIR_NAME"; exit 1; }

if [ -f "Makefile" ]; then
    sudo make install
elif [ -f "Configure" ]; then
    ./Configure
else
    chmod -R +x "/opt/cost/cellar/$DIR_NAME"
fi

echo "export PATH=\"\$PATH:/opt/cost/cellar/$DIR_NAME\"" >> "$HOME/.bashrc"
echo "export PATH=\"\$PATH:/opt/cost/cellar/$DIR_NAME\"" >> "$HOME/.zshrc"

echo "$DIR_NAME was installed successfully."
echo "Please run 'source ~/.bashrc' or 'source ~/.zshrc' to apply PATH changes."
EOF

cat << 'EOF' > "/opt/cost/flag/license"
#!/bin/bash
cat "/opt/cost/doc/license.md"
EOF

cat << 'EOF' > "/opt/cost/flag/readme"
#!/bin/bash
cat "/opt/cost/doc/readme.md"
EOF

cat << 'EOF' > "/opt/cost/flag/help"
#!/bin/bash
cat "/opt/cost/doc/help.md"
EOF

cat << 'EOF' > "/opt/cost/flag/uninstall"
#!/bin/bash
PACKAGE="$1"

if [ -z "$PACKAGE" ]; then
    echo "Usage: cost uninstall <package>"
    exit 1
fi

if [ ! -d "/opt/cost/cellar/$PACKAGE" ]; then
    echo "Cost: Package not found: $PACKAGE"
    exit 1
fi

rm -rf "/opt/cost/cellar/$PACKAGE"
echo "Package $PACKAGE has been uninstalled."
EOF

cat << 'EOF' > "/opt/cost/flag/package-readme"
#!/bin/bash
PACKAGE="$1"

if [ -z "$PACKAGE" ]; then
    echo "Usage: cost package-readme <package>"
    exit 1
fi

if [ ! -d "/opt/cost/cellar/$PACKAGE" ]; then
    echo "Cost: Package not found: $PACKAGE"
    exit 1
fi

cd "/opt/cost/cellar/$PACKAGE"
if [ -f "README.md" ]; then
    cat "README.md"
else
    echo "Cost: README file not found on package: $PACKAGE"
fi
EOF

cat << 'EOF' > "/opt/cost/flag/package-license"
#!/bin/bash
PACKAGE="$1"

if [ -z "$PACKAGE" ]; then
    echo "Usage: cost package-license <package>"
    exit 1
fi

if [ ! -d "/opt/cost/cellar/$PACKAGE" ]; then
    echo "Cost: Package not found: $PACKAGE"
    exit 1
fi

cd "/opt/cost/cellar/$PACKAGE"
if [ -f "LICENSE" ]; then
    cat "LICENSE"
else
    echo "Cost: LICENSE file not found on package: $PACKAGE"
fi
EOF

cat << 'EOF' > "/opt/cost/flag/version"
#!/bin/bash
cat "/opt/cost/doc/version.md"
EOF

cat << 'EOF' > "/opt/cost/flag/set-version"
#!/bin/bash
VERSION="$1"

if [ -z "$VERSION" ]; then
    echo "Usage: cost set-version <version>"
    exit 1
fi

echo "Setting the version..."
git clone "https://github.com/LT5B/cost-${VERSION}" "cost-${VERSION}"
cd "cost-${VERSION}"

if [ -f "Makefile" ]; then
    sudo make install
elif [ -f "Configure" ]; then
    ./Configure
elif [ -f "install.sh" ]; then
    bash "install.sh"
else
    echo "Cost: Installer not found on this version"
fi

cd ..
rm -rf "cost-${VERSION}"
EOF

sleep 1
echo "Making alias..."
sudo ln -sf "$(realpath "/opt/cost/bin/cost")" "/usr/local/bin/cost"
sleep 1

echo "Installation complete."
