#!/usr/bin/env sh

# Define variables
INSTALL_DIR="$HOME/.config/conventional"
SCRIPT_NAME="conventional.sh"
ALIAS_NAME="conv"

# Detect the shell profile file
if [ -n "$ZSH_VERSION" ]; then
    PROFILE_FILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    PROFILE_FILE="$HOME/.bashrc"
else
    echo "Unsupported shell. Please use bash or zsh."
    exit 1
fi

# Create the installation directory if it doesn't exist
mkdir -p $INSTALL_DIR

# Copy the script to the installation directory
cp $SCRIPT_NAME $INSTALL_DIR

# Make the script executable
chmod +x $INSTALL_DIR/$SCRIPT_NAME

# Check if the script's path is already in the PATH
if ! grep -q "$INSTALL_DIR" $PROFILE_FILE; then
    echo 'export PATH="$HOME/.config/conventional:$PATH"' >> $PROFILE_FILE
    echo "Added $INSTALL_DIR to your PATH in $PROFILE_FILE"
else
    echo "$INSTALL_DIR is already in your PATH"
fi

# Add alias for convenience
if ! grep -q "alias $ALIAS_NAME=" $PROFILE_FILE; then
    echo "alias $ALIAS_NAME=\"$INSTALL_DIR/$SCRIPT_NAME\"" >> $PROFILE_FILE
    echo "Alias '$ALIAS_NAME' added to $PROFILE_FILE"
else
    echo "Alias '$ALIAS_NAME' already exists in $PROFILE_FILE"
fi

# Source the profile file to apply changes
echo "Sourcing $PROFILE_FILE to apply changes..."
source $PROFILE_FILE

# Display completion message
echo "Installation complete! You can now use the '$ALIAS_NAME' command to commit with conventional commits."

