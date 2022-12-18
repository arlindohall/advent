
echo '#!/bin/bash
./helper $@
' > /usr/local/bin/advent-helper

if ! complete -c advent-helper | grep advent-helper
  complete advent-helper \
    -a "current current-input current-example next repl input day create example help"
end