
set advent_commands "current open code current-input current-example next repl input day create example"
if ! complete -c advent-helper | grep $advent_commands
  complete -e advent-helper
  complete -c advent-helper -f -a $advent_commands
end
set advent_commands