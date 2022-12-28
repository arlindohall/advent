
if ! test -f /usr/local/bin/advent-helper
  echo '#!/bin/bash
  ./helper $@
  ' > /usr/local/bin/advent-helper
end

if ! complete -c advent-helper | grep advent-helper
  complete advent-helper \
    -a "current open code current-input current-example next repl input day create example help"
end