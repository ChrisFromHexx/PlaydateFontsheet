#!/bin/zsh
if [ ! -f ~/Library/Fonts/VeraSeBd.ttf ]; then
    echo -e "If you choose, when FontBook appears please click the \033[1;36m'Install'\033[0m button to install the license free font \"Bitstream Vera Serif\"."
    open -b com.apple.FontBook ./samples/bitstream_vera_seri/VeraSeBd.ttf
    exit 0
fi
echo -e "Thanks, the font \"Bitstream Vera Serif\" is already installed."
