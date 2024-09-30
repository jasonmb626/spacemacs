#!/bin/bash

zettelpath=$1

if [[ -z $zettelpath ]]; then
  zettelpath=~/Documents/zettelkasten
fi
ln -s ~/git/spacemacs ~/.emacs.d
ln -s ~/git/spacemacs/.spacemacs ~/.spacemacs
mkdir -p $zettelpath/templates
cp -a ~/git/spacemacs/templates/* $zettelpath/templates/.
