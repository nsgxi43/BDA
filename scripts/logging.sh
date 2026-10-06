start_log() {
  local name="$1"
  exec > >(tee "$ROOT/output/${name}.log") 2>&1
  trap 's=$?; printf "EXIT_STATUS=%s\\n" "$s"' EXIT
}
