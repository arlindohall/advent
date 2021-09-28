(ns advent.core
  (:gen-class))

(use 'advent.y2020)

(defn help
  "Print usage and quit."
  [args]
  (println "Usage: advent <command> [args...]"))

(defn run
  "Execute one day."
  [args]
  (let [day (get args "day" "unknown")]
    (println "Running day" day)
    ((puzzles day) "test")))

(defn prop-error
  [& messages]
  (help)
  (throw (new RuntimeException (clojure.string/join " " ["ParseError: "] messages))))

(defn parse-one
  "Parse a single command line option or error"
  [prop val]
  (if (.startsWith prop "--")
      (hash-map (.substring prop 2 (.length prop)) val)
      (prop-error "invalid property" prop)))

(defn parse-props
  "Parse the props for a command"
  [props]
  (cond
    (empty? props) {}
    (empty? (rest props)) (parse-one (nth props 0) true)
    :else (let [first (first props) second (second props)]
      (if (.startsWith second "--")
        (merge (parse-one first true) (parse-props (rest props)))
              (merge (parse-one first second) (parse-props (rest (rest props))))))))

(defn parse-command
  [command props]
  (cond (.equals "help" command) [help {}]
        (.equals "run" command) [run (parse-props props)]
        :else [help {}]))

(defn parse-args
  "Parse arguments and quit."
  [args]
  (if-let [[command & rest] args]
    (parse-command command rest)
    [help {}]))

(defn -main
  "Entry point."
  [& args]
  (let [[command parsed] (parse-args args)]
    (command parsed)))