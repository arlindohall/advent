#!/bin/bash

function install-helper {
  sudo touch /usr/local/bin/advent-helper
  sudo chown "$USER" /usr/local/bin/advent-helper
  sudo chmod u+x /usr/local/bin/advent-helper
  echo '#!/bin/bash
  ./helper $@
  ' > /usr/local/bin/advent-helper
}

function install-fish-helper {
  cp ./advent.fish "$HOME"/.config/fish/conf.d/
}

function setup {
  install-helper
  install-fish-helper
}

setup
