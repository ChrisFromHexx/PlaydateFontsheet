#!/bin/zsh
if [ ! -f fontsheet ]; then
    echo -e "Building \033[1;32mfontsheet\033[0m commandline tool..."
    swift build -c release
    cp .build/release/fontsheet .
    chmod +x fontsheet
fi

if [ ! -f ~/Library/Fonts/VeraSeBd.ttf ]; then
    echo -e "The demo needs a (license free) font to be installed. If you are comfortable doing that, run \033[1;36m./scripts/installSampleFont.sh\033[0m to install the font, then run this script again."
    echo -e "Otherwise use this script to understand how to use \033[1;32mfontsheet\033[0m with your own fonts."
    exit 0
fi

# Runs 'fontsheet' to create a playdate font file
./fontsheet \
./samples/glyphs.txt \
--name "VeraSerif" \
--font BitstreamVeraSerif-Bold \
--output "./fonts" \
--size 30 \
--threshold 0.6 \
--weight bold \
--embedded \
&& open ./fonts/VeraSerif/sample-*.png
