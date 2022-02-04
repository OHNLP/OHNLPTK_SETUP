#!/bin/bash

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

mkdir OHNLPTK_RECOVER
cd OHNLPTK_RECOVER

# Install Backbone
BACKBONE_TAG=$(get_latest_release OHNLP/Backbone)
echo "Installing Backbone $BACKBONE_TAG..."
wget https://github.com/OHNLP/Backbone/releases/download/$BACKBONE_TAG/Backbone.zip -O Backbone.zip
unzip Backbone.zip
rm Backbone.zip

MEDTAGGER_TAG=$(get_latest_release OHNLP/MedTagger)
echo "Installing MedTagger $MEDTAGGER_TAG..."
mkdir temp
cd temp
wget https://github.com/OHNLP/MedTagger/releases/download/$MEDTAGGER_TAG/MedTagger.zip -O MedTagger.zip
unzip MedTagger.zip
mv -f MedTagger.jar ../modules/MedTagger.jar

if [ -f "../resources/pasc" ]; then
    echo "PASC resources already exist; new resources will not be copied to prevent overwriting any end-user changes. Please manually merge"
else
    mv medtaggerieresources/pasc ../resources/pasc
fi
cd ..
rm -r temp

echo "OHNLPTK Installed Successfully (Backbone $BACKBONE_TAG, MedTagger $MEDTAGGER_TAG)"
