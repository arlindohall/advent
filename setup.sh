#!/bin/bash

echo "To reset the helper autocomplete, run: 'complete -e advent-helper'"

function install-helper {
  if ! test -f /usr/local/bin/advent-helper ; then
    sudo touch /usr/local/bin/advent-helper
    sudo chown "$USER" /usr/local/bin/advent-helper
    sudo chmod u+x /usr/local/bin/advent-helper
    echo '#!/bin/bash
    ./helper $@
    ' > /usr/local/bin/advent-helper
  fi
}

function install-fish-helper {
  cp ./advent.fish "$HOME"/.config/fish/conf.d/
}

function setup {
  install-helper
  install-fish-helper
}

setup
