#!/bin/bash

# Project Zomboid Mod CLI (pzmcli).
# Terminal tool for create mods on Linux for Project Zomboid.
#
# Copyright (c) 2024 Pavel Korotkiy (outdead).
# Use of this source code is governed by the MIT license.
#
# DO NOT EDIT THIS FILE!

# VERSION of Project Zomboid Mod CLI.
# Follows semantic versioning, SEE: http://semver.org/.
VERSION="0.0.0"
YEAR="2024"
AUTHOR="Pavel Korotkiy (outdead)"

# Color variables. Used when displaying messages in stdout.
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; BLUE='\033[0;36m'; NC='\033[0m'

# Message types. Used when displaying messages in stdout.
OK=$(echo -e "[ ${GREEN} OK ${NC} ]"); ER=$(echo -e "[ ${RED} ER ${NC} ]"); WARN=$(echo -e "[ ${YELLOW} YELLOW ${NC} ]"); INFO=$(echo -e "[ ${BLUE}INFO${NC} ]")

BASEDIR=$(dirname "$(readlink -f "${BASH_SOURCE[@]}")")
SCRIPT_LOCATION=${BASEDIR}
MOD_LOCATION=${BASEDIR}

# NOW is the current date and time in default format Y%m%d_%H%M%S.
# You can change format in config file.
NOW=$(date "+%Y%m%d_%H%M%S")

# TIMESTAMP is current timestamp.
TIMESTAMP=$(date "+%s")

ENV_FILE="${BASEDIR}/.env"

# Import env file if exists.
# shellcheck source=.env
test -f "${ENV_FILE}" && . "${ENV_FILE}"

fn_exists() { declare -F "$1" > /dev/null; }

# echoerr prints red error message to stderr and FILE_PZLSM_LOG file.
function echoerr() {
  echo "${ER} $1"
  if [ "${WRITE_PZLSM_LOGS}" == "true" ]; then
    mkdir -p "${DIR_LOGS}"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $0 - $1" >> "${FILE_PZLSM_LOG}"
  fi
}

# echowarn prints yellow error message to stderr and FILE_PZLSM_LOG file.
function echowarn() {
  echo "${WARN} $1"
  if [ "${WRITE_PZLSM_LOGS}" == "true" ]; then
    mkdir -p "${DIR_LOGS}"
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $0 - $1" >> "${FILE_PZLSM_LOG}"
  fi
}

# is_dir_exist returns true if directory is exist.
function is_dir_exist() {
  [ -d "$1" ] && echo "true" || echo "false"
}

# is_file_exist returns true if file is exist.
function is_file_exist() {
  [ -f "$1" ] && echo "true" || echo "false"
}

# is_symlink returns true if file is symlink.
function is_symlink() {
  [ -L "$1" ] && echo "true" || echo "false"
}

# init_variables creates pzmcli variables.
function init_variables() {
  # Project Zomboid Mod CLI definitions.
  DIR_STATE="${SCRIPT_LOCATION}/state"
  DIR_CONFIG="${SCRIPT_LOCATION}/config"
  DIR_LOGS="${SCRIPT_LOCATION}/logs"
  FILE_PZMCLI_CONFIG="${SCRIPT_LOCATION}/pzmcli.cfg"
  [ -z "${PZMCLI_SOURCE_LINK}" ] && PZMCLI_SOURCE_LINK="https://raw.githubusercontent.com/openzomboid/pzmcli/master"

  # Mod definitions.
  DIR_TESTS="${MOD_LOCATION}/tests"
}

# print_variables prints pzmcli variables.
function print_variables() {
  check_dir() {
    [ ! -d "$1" ] && echo -e "${RED} (not exists)${NC}"
  }

  check_file() {
    [ ! -f "$1" ] && echo -e "${RED} (not exists)${NC}"
  }

  echo "${INFO} NOW:       ${NOW}"
  echo "${INFO} TIMESTAMP: ${TIMESTAMP}"
  echo "${INFO} BASEDIR:   ${BASEDIR}"
  echo "${INFO}"

  echo "${INFO} SCRIPT_LOCATION:    ${SCRIPT_LOCATION}$(check_dir "${SCRIPT_LOCATION}")"
  echo "${INFO} DIR_STATE:          ${DIR_STATE}$(check_dir "${DIR_STATE}")"
  echo "${INFO} DIR_LOGS:           ${DIR_LOGS}$(check_dir "${DIR_LOGS}")"
  echo "${INFO} DIR_CONFIG:         ${DIR_CONFIG}$(check_dir "${DIR_CONFIG}")"
  echo "${INFO} FILE_PZMCLI_CONFIG: ${FILE_PZMCLI_CONFIG}$(check_file "${FILE_PZMCLI_CONFIG}")"
  echo "${INFO}"

  echo "${INFO} MOD_LOCATION: ${MOD_LOCATION}$(check_dir "${MOD_LOCATION}")"
  echo "${INFO} DIR_TESTS:    ${DIR_TESTS}$(check_dir "${DIR_TESTS}")"
}

# print_version prints versions.
function print_version() {
  echo "${INFO} pzmcli version ${VERSION}"
#  echo "${INFO} mod version ${UTIL_RCON_VERSION}"
}

# save_config_example saves pzmlci config example.
function save_config_example() {
  bash -c "cat <<'EOF' > ${DIR_CONFIG}/pzmcli.example.cfg
#!/usr/bin/env bash

# DIR_TESTS contains directory for test definitions.
DIR_TESTS=\"${DIR_TESTS}\"
EOF"
}

# install_dependencies installs the necessary dependencies to pzmcli.
# You must have sudo privileges to call function install_dependencies.
# This is the only function in this script that needs root privileges.
# You can install dependencies yourself before running this script and do
# not call this function.
function install_dependencies() {
  sudo apt-get update \
    && echo "${OK} dependencies installed" \
    || echo "${ER} dependencies is not installed"
}

# create_folders creates folders for pzmcli script.
function create_folders() {
  mkdir -p "${DIR_TESTS}"

  # Config.
  save_config_example

  echo "${OK} folders created"
}

function self_download() {
    local install_dir=$1
    if [ ! "$(is_dir_exist "${install_dir}")" == "true" ]; then
      echo "${ER} ${install_dir} is not exists"; return 0
    fi

    wget -q -O "${install_dir}/pzmcli" "${PZMCLI_SOURCE_LINK}/pzmcli.sh"
    chmod +x "${install_dir}/pzmcli"
}

function self_install() {
  local install_dir=$1
  if [ "$(is_dir_exist "${install_dir}")" == "true" ]; then
    echo "${ER} ${install_dir} already exists"; return 0
  fi

  mkdir -p "${install_dir}"

  # Download pzmcli.
  self_download "${install_dir}"

  ln -s "${install_dir}/pzmcli" "$HOME/.local/bin/pzmcli"

  echo "${OK} pzmcli successfully installed"
}

# self_update downloads pzmcli updates from repository.
# TODO: Add chose tags: version|latest|develop.
function self_update() {
  local update_dir="${DIR_STATE}/update"

  rm -rf "${update_dir}"
  mkdir -p "${update_dir}"

  wget -q -O "${update_dir}/pzmcli" "${PZMCLI_SOURCE_LINK}/pzmcli.sh"
  chmod +x "${update_dir}/pzmcli"

  local new_version; new_version=$(grep "^VERSION" "${update_dir}/pzmcli" | awk -F'[="]' '{print $3}')

  if [ -z "${new_version}" ]; then
    echoerr "self_update: failed to download pzmcli update"; return 1
  fi

  if [ "${VERSION}" \< "${new_version}" ]; then
    mv "${update_dir}/pzmcli" "${SCRIPT_LOCATION}/pzmcli"

    echo "${INFO} pzmcli successfully updated"
  else
    echo "${INFO} Nothing to update"
  fi

  rm -rf "${update_dir}"
}

# main contains a proxy for entering permissible functions.
function main() {
  case "$1" in
    -s)
      BASEDIR="${BASEDIR}/gameservers/$2"

      shift
      shift
      ;;
  esac

  init_variables

  case "$1" in
    self-install)
      self_install "$2" ;;
    self-update)
      self_update ;;
    --variables|--vars)
      print_variables ;;
    --version)
      print_version ;;
  esac
}

main "$@"
