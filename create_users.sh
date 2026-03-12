#!/bin/bash

# Avsluta vid fel, undefined variabler och pipeline-fel.
set -euo pipefail

# Kontrollera att scriptet körs som root (UID 0).
if [[ "${EUID}" -ne 0 ]]; then
  echo "Fel: Detta script måste köras som root." >&2
  exit 1
fi

# Kontrollera att minst ett användarnamn skickas in.
if [[ "$#" -lt 1 ]]; then
  echo "Användning: $0 <anvandare1> [anvandare2 ...]" >&2
  exit 1
fi

# Loopa igenom varje användarnamn som skickats in som argument.
for username in "$@"; do
  # Skapa användaren med hemkatalog om den inte redan finns.
  if id "${username}" &>/dev/null; then
    echo "Info: Användaren ${username} finns redan, hoppar över skapande."
  else
    useradd -m -s /bin/bash "${username}"
    echo "Skapade användare: ${username}"
  fi

  home_dir="/home/${username}"

  # Säkerställ att hemkatalogen finns.
  mkdir -p "${home_dir}"
  chown "${username}:${username}" "${home_dir}"

  # Skapa undermapparna som krävs.
  for subdir in Documents Downloads Work; do
    mkdir -p "${home_dir}/${subdir}"
    chown "${username}:${username}" "${home_dir}/${subdir}"
    chmod 700 "${home_dir}/${subdir}"
  done

  # Skapa välkomstfil:
  # Rad 1: personligt välkomstmeddelande.
  # Resterande rader: alla andra användare som finns i systemet.
  {
    echo "Välkommen ${username}"
    cut -d: -f1 /etc/passwd | grep -vx "${username}" || true
  } > "${home_dir}/welcome.txt"

  chown "${username}:${username}" "${home_dir}/welcome.txt"
  chmod 600 "${home_dir}/welcome.txt"
done
