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
VERSION="0.0.0.1"
YEAR="2024"
AUTHOR="Pavel Korotkiy (outdead)"

# Color variables. Used when displaying messages in stdout.
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; BLUE='\033[0;36m'; NC='\033[0m'

# Message types. Used when displaying messages in stdout.
OK=$(echo -e "[ ${GREEN} OK ${NC} ]"); ER=$(echo -e "[ ${RED} ER ${NC} ]"); WARN=$(echo -e "[ ${YELLOW} WARN ${NC} ]"); INFO=$(echo -e "[ ${BLUE}INFO${NC} ]")
FAIL=$(echo -e "[\033[0;31m fail \033[0m]")

FULL_FILE=$(readlink -f "${BASH_SOURCE[@]}")
BASEDIR=$(dirname "${FULL_FILE}")
if [ "${BASEDIR}" == "." ]; then
  BASEDIR=$(dirname "$BASH_SOURCE")
fi
BASEFILE=$(basename "${FULL_FILE}")

SCRIPT_LOCATION=${BASEDIR}
MOD_LOCATION=$(pwd)

DEFAULT_INSTALL_DIR=~/pzmcli

# NOW is the current date and time in default format Y%m%d_%H%M%S.
# You can change format in config file.
NOW=$(date "+%Y%m%d_%H%M%S")

# TIMESTAMP is current timestamp.
TIMESTAMP=$(date "+%s")

ENV_FILE="${SCRIPT_LOCATION}/.env"

# Import env file if exists.
# shellcheck source=.env
test -f "${ENV_FILE}" && . "${ENV_FILE}"

fn_exists() { declare -F "$1" > /dev/null; }

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

# get_pz_path searches and returns Project Zomboid installation path.
# PZ_PATH contains Project Zomboid installed files. This path is needed for
# mocks Project Zomboid server. Can be defined in env before running tests.sh script.
# If not defined try to import from local config or find on disk.
# Mostly located in ~/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid.
function get_pz_path() {
  local search_label="/media/lua/shared/luautils.lua"

  # Exclude directories from search where Project Zomboid cannot be installed.
  local excluded=(/proc /tmp /dev /sys /snap /etc /var /run /snap /boot)
  for ex in "${excluded[@]}"; do
    excluded_args="${excluded_args} -path ${ex} -prune -o"
  done

  # WARNING: don't quote excluded_args!
  # PZ_PATH=$(find / ${excluded_args} -path "*${search_label}" -print -quit 2> /dev/null | sed "s#${search_label}##g")
  find / ${excluded_args} -path "*${search_label}" -print -quit 2> /dev/null | sed "s#${search_label}##g"
}

# init_pzmcli_variables defines Project Zomboid Mod CLI variables.
function init_pzmcli_variables() {
  [ -z "${DIR_STATE}" ] && DIR_STATE="${SCRIPT_LOCATION}/state"
  [ -z "${PZMCLI_SOURCE_LINK}" ] && PZMCLI_SOURCE_LINK="https://github.com/openzomboid/pzmcli/"
  [ -z "${PZMCLI_SOURCE_LINK_RAW}" ] && PZMCLI_SOURCE_LINK_RAW="https://raw.githubusercontent.com/openzomboid/pzmcli/master"

  [ -z "${PZ_PATH}" ] && {
    echo -e "${INFO} PZ_PATH is not defined. Find Project Zomboid files..."

    PZ_PATH=$(get_pz_path)

    if [ -z "${PZ_PATH}" ]; then
      echo -e "${FAIL} Cannot find installed Project Zomboid for getting needed lua files." >&2
      echo -e "${INFO} Please define PZ_PATH env with path to Prozect Zomboid before executing test script." >&2
      echo -e "${INFO} Or place PZ_PATH declaration to the configuration .env file" >&2

      return 1
    fi

    echo -e "${OK} PZ_PATH=${PZ_PATH}"
  }

  [ -z "${DIR_TESTS}" ] && DIR_TESTS="${SCRIPT_LOCATION}/modules/testsrunner"
}

# init_mod_variables defines mod variables.
function init_mod_variables() {
  echo "${INFO} init mod variables is not implemented. Skip step"
}

# init_variables creates pzmcli variables.
function init_variables() {
  init_pzmcli_variables
  init_mod_variables
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
  echo "${INFO} FULL_FILE: ${FULL_FILE}"
  echo "${INFO} BASEDIR:   ${BASEDIR}"
  echo "${INFO} BASEFILE:  ${BASEFILE}"
  echo "${INFO}"

  echo "${INFO} SCRIPT_LOCATION: ${SCRIPT_LOCATION}$(check_dir "${SCRIPT_LOCATION}")"
  echo "${INFO} DIR_STATE:       ${DIR_STATE}$(check_dir "${DIR_STATE}")"
  echo "${INFO}"

  echo "${INFO} MOD_LOCATION: ${MOD_LOCATION}$(check_dir "${MOD_LOCATION}")"
  echo "${INFO} DIR_TESTS:    ${DIR_TESTS}$(check_dir "${DIR_TESTS}")"

  echo "${INFO} " # .env
  echo "${INFO} DEFAULT_INSTALL_DIR: ${DEFAULT_INSTALL_DIR}$(check_dir "${DEFAULT_INSTALL_DIR}")"
}

# print_version prints versions.
function print_version() {
  echo "${INFO} pzmcli version ${VERSION}"
  #echo "${INFO} mod version ${UTIL_RCON_VERSION}"
}

# save_config_example saves pzmlci config example.
function save_config_example() {
  bash -c "cat <<'EOF' > ${SCRIPT_LOCATION}/pzmcli.example.cfg
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
  # save_config_example

  echo "${OK} folders created"
}

# self_install installs pzmcli from repository.
# TODO: Add chose tags: version|latest|develop.
function self_install() {
  local install_dir=$1
  [ -z "${install_dir}" ] && install_dir=$DEFAULT_INSTALL_DIR

  rm -rf "${install_dir}" && rm -f "$HOME/.local/bin/pzmcli" # TODO: Remove me.
  if [ "$(is_dir_exist "${install_dir}")" == "true" ]; then
    echo "${ER} ${install_dir} already exists"; return 0
  fi

  echo "${INFO} installing pzmcli in ${install_dir}";

  mkdir -p "${install_dir}"

  # curl -L -o ./.tmp/master.tar.gz https://github.com/openzomboid/pzmcli/archive/master.tar.gz
  curl -L -o "${install_dir}/master.tar.gz" "${PZMCLI_SOURCE_LINK}/archive/master.tar.gz" || {
    # Retry.
    curl -L -o "${install_dir}/master.tar.gz" "${PZMCLI_SOURCE_LINK}/archive/master.tar.gz"
  }
  tar -zxvf "${install_dir}/master.tar.gz" -C "${install_dir}"
  mv -v "${install_dir}"/pzmcli-master/* "${install_dir}/" 1> /dev/null
  mv "${install_dir}/pzmcli.sh" "${install_dir}/pzmcli"

  rm -rf ${install_dir}/pzmcli-master
  rm -rf ${install_dir}/master.tar.gz

  ln -s "${install_dir}/pzmcli" "$HOME/.local/bin/pzmcli"

  echo "${OK} install pzmcli in ${install_dir} succes";
}

# self_update downloads pzmcli updates from repository.
# TODO: Add chose tags: version|latest|develop.
# Allowed only for production mode.
function self_update() {
  if [ "${BASEFILE}" == "pzmcli.sh" ]; then
    echo "${ER} prod functions is not allowed"; return 0
  fi

  local update_dir="${DIR_STATE}/update"

  rm -rf "${update_dir}"
  mkdir -p "${update_dir}"

  wget -q -O "${update_dir}/pzmcli" "${PZMCLI_SOURCE_LINK_RAW}/pzmcli.sh"
  chmod +x "${update_dir}/pzmcli"

  local new_version; new_version=$(grep "^VERSION" "${update_dir}/pzmcli" | awk -F'[="]' '{print $3}')

  if [ -z "${new_version}" ]; then
    echo "${ER} self_update: failed to download pzmcli update"; return 1
  fi

  if [ "${VERSION}" \< "${new_version}" ]; then
    mv "${update_dir}/pzmcli" "${SCRIPT_LOCATION}/pzmcli"
    rm -f "$HOME/.local/bin/pzmcli" && ln -s "${install_dir}/pzmcli" "$HOME/.local/bin/pzmcli"

    echo "${INFO} pzmcli successfully updated"
  else
    echo "${INFO} Nothing to update"
  fi

  rm -rf "${update_dir}"
}

# self_update_dev downloads pzmcli updates from local files.
# Allowed only for developer mode.
function self_update_dev() {
  if [ "${BASEFILE}" == "pzmcli" ]; then
    echo "${ER} dev functions is not allowed"; return 0
  fi

  local install_dir=$DEFAULT_INSTALL_DIR
  if [ ! "$(is_dir_exist "${install_dir}")" == "true" ]; then
    echo "${ER} ${install_dir} is not exists"; return 0
  fi

  if [ ! "$(is_file_exist "${install_dir}/pzmcli")" == "true" ]; then
    echo "${ER} ${install_dir}/pzmcli is not exists"; return 0
  fi

  echo "${INFO} dev upgrading pzmcli in ${install_dir}";

  rm -rf "${install_dir}/modules" && mkdir -p "${install_dir}/modules"

  cp -r "${SCRIPT_LOCATION}/modules/testsrunner" "${install_dir}/modules/"
  cp "${SCRIPT_LOCATION}/.env.dist" "${install_dir}/.env.dist"
  cp "${SCRIPT_LOCATION}/CHANGELOG.md" "${install_dir}/CHANGELOG.md"
  cp "${SCRIPT_LOCATION}/LICENSE" "${install_dir}/LICENSE"
  cp "${SCRIPT_LOCATION}/pzmcli.sh" "${install_dir}/pzmcli"
  cp "${SCRIPT_LOCATION}/README.md" "${install_dir}/README.md"

  rm -f "$HOME/.local/bin/pzmcli" && ln -s "${install_dir}/pzmcli" "$HOME/.local/bin/pzmcli"

  echo "${OK} dev upgrade pzmcli in ${install_dir} succes";
}

# self_uninstall removes pzmcli.
# Allowed only for production mode.
function self_uninstall() {
  if [ "${BASEFILE}" == "pzmcli.sh" ]; then
    echo "${ER} prod functions is not allowed"; return 0
  fi

  local install_dir=$SCRIPT_LOCATION
  if [ ! "$(is_file_exist "${install_dir}/pzmcli")" == "true" ]; then
    echo "${ER} ${install_dir}/pzmcli is not exists"; return 0
  fi

  echo "${INFO} uninstalling pzmcli from ${install_dir}";

  rm "$HOME/.local/bin/pzmcli"
  rm -rf "${install_dir}"

  echo "${OK} uninstall pzmcli from ${install_dir} succes";
}

# main contains a proxy for entering permissible functions.
function main() {
  init_variables

  case "$1" in
    self-install)
      self_install "$2";;
    self-update)
      local is_dev="false"

      while [[ -n "$2" ]]; do
        case "$2" in
          --dev|dev) is_dev="true"; shift ;;
        esac

        shift
      done

      if [ "${is_dev}" == "true" ]; then
        self_update_dev
      else
        self_update
      fi ;;
    self-uninstall)
      self_uninstall ;;
    --variables|--vars)
      print_variables ;;
    --version)
      print_version ;;
  esac
}

main "$@"
