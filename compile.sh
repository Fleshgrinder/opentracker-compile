#!/bin/sh

# -----------------------------------------------------------------------------
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Compile and install opentracker from source.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2015 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# -----------------------------------------------------------------------------

# Check return status of every command.
set -e


# ----------------------------------------------------------------------------- Variables


# The version string of the nginx release that should be installed.
readonly LIBOWFAT_VERSION='0.29'

# The absolute path to the opentracker configuration directory.
readonly CONFIGURATION_DIRECTORY='/etc/opentracker'

# The absolute path to the opentracker installation directory.
readonly INSTALL_DIRECTORY='/usr/local/sbin'

# The absolute path to the downloaded and extracted source files.
readonly SOURCE_DIRECTORY='/usr/local/src'

# For more information on shell colors and other text formatting see:
# http://stackoverflow.com/a/4332530/1251219
readonly RED=$(tput bold; tput setaf 1)
readonly GREEN=$(tput bold; tput setaf 2)
readonly YELLOW=$(tput bold; tput setaf 3)
readonly NORMAL=$(tput sgr0)

# Absolute path to the current directory of the script.
readonly __DIRNAME__="$(cd -- "$(dirname -- "${0}")"; pwd)"


# ----------------------------------------------------------------------------- Functions


usage()
{
    cat << EOT
Usage: ${0##*/} [OPTION]...
Compile and install opentracker from source.

  -h  Display this help and exit.

Report bugs to richard@fussenegger.info
GitHub repository: https://github.com/Fleshgrinder/opentracker-compile
For complete documentation, see: README.md
EOT
}


# -----------------------------------------------------------------------------


# Check for possibly passed options.
while getopts 'h' OPT
do
    case "${OPT}" in
        h|[?]) usage && exit 0 ;;
        *) usage && exit 1 ;;
    esac

    # We have to remove found options from the input for later evaluations of
    # passed arguments in subscripts that are not interested in these options.
    shift $(( $OPTIND - 1 ))
done

# Remove possibly passed end of options marker.
if [ "${1}" = "--" ]
    then shift $(( $OPTIND - 1 ))
fi

printf -- 'Installing opentracker with libowfat %s ...\n' "${YELLOW}${LIBOWFAT_VERSION}${NORMAL}"

printf -- 'Updating package sources ...\n'
apt-get -- update 1>/dev/null

printf -- 'Installing build dependencies ...\n'
apt-get --yes -- install build-essential git bzip2

cd -- "${SOURCE_DIRECTORY}"

if [ ! -d "${SOURCE_DIRECTORY}/libowfat" ]
then
    rm --recursive --force -- "${SOURCE_DIRECTORY}/libowfat"
    wget "http://dl.fefe.de/libowfat-${LIBOWFAT_VERSION}.tar.bz2"
    tar --bzip2 --extract --file="${SOURCE_DIRECTORY}/libowfat-${LIBOWFAT_VERSION}.tar.bz2"
    rm --force -- "${SOURCE_DIRECTORY}/libowfat-${LIBOWFAT_VERSION}.tar.bz2"
    ln --symbolic -- "${SOURCE_DIRECTORY}/libowfat-${LIBOWFAT_VERSION}" "${SOURCE_DIRECTORY}/libowfat"
    chown --recursive -- root:root "${SOURCE_DIRECTORY}/libowfat"
    cd -- "${SOURCE_DIRECTORY}/libowfat"
    make
fi

if [ -e "${SOURCE_DIRECTORY}/opentracker/.git" ]
then
    cd -- "${SOURCE_DIRECTORY}/opentracker"
    git pull
else
    rm --recursive --force -- "${SOURCE_DIRECTORY}/opentracker"
    git clone --depth 1 --single-branch -- "git://erdgeist.org/opentracker" "${SOURCE_DIRECTORY}/opentracker"
    cd -- "${SOURCE_DIRECTORY}/opentracker"
fi

CFLAGS='-m64 -march=native' FEATURES='-DWANT_FULLSCRAPE -DWANT_RESTRICT_STATS -DWANT_SYSLOGS' make

mkdir --parents -- "${CONFIGURATION_DIRECTORY}"

cp -- "${SOURCE_DIRECTORY}/opentracker/opentracker.conf.sample" "${CONFIGURATION_DIRECTORY}"

if [ ! -e /etc/init.d/opentracker ] && [ -e "${__DIRNAME__}/opentracker" ]
then
    install --mode=0755 -- "${__DIRNAME__}/opentracker" /etc/init.d
    update-rc.d opentracker defaults
fi

set +e
service opentracker stop 2>/dev/null
set -e

BINDIR="${INSTALL_DIRECTORY}" make install

if [ -e "${CONFIGURATION_DIRECTORY}/opentracker.conf" ]
    then service opentracker start
fi

cat << EOT

[${GREEN}ok${NORMAL}] Installation finished.

BINARY: ${YELLOW}${INSTALL_DIRECTORY}/opentracker${NORMAL}
CONFIG: ${YELLOW}${CONFIGURATION_DIRECTORY}${NORMAL}

Have a look at ${YELLOW}opentracker.conf.sample${NORMAL} in your configuration directory and create your own configuration based on the
information provided in the sample. Place your custom configuration in the same directory as ${YELLOW}opentracker.conf${NORMAL} and start
your new opentracker with ${GREEN}service opentracker start${NORMAL}.

You may want to delete the source files in ${YELLOW}${SOURCE_DIRECTORY}${NORMAL}.

EOT

exit 0
