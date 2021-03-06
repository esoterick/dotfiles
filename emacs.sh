#!/bin/bash

set -eE

release=26.1

################

function determine_os_type () {
    if [ -f /etc/redhat-release ] ; then
        echo rhel
    elif [ -f /etc/debian-release ] ; then
        echo debian
    elif [ -f /etc/system-release ] ; then
        echo $(determine_os_type_from_file /etc/system-release)
    elif [ -f /etc/os-release ] ; then
        echo $(determine_os_type_from_file /etc/os-release)
    else
        echo "ERROR: cannot determine os type. install dependencies manually" >&2
        exit 1
    fi
}

function determine_os_type_from_file () {
    local file=$1
    local type
    read contents <$file
    case $contents in
        'Red Hat'*) type=rhel ;;
        'Debian'*) type=debian ;;
        *)
            echo "unknown os type: $contents" >&2
            exit 1
    esac
    echo $type
}

################
# dependencies

case $(determine_os_type) in
    rhel)
        # sudo yum install gtk2 gtk2-devel libXpm-devel giflib-devel libtiff-devel libjpeg libjpeg-devel ncurses ncurses-devel
        sudo yum install ncurses ncurses-devel
        # NOTE: needed for lucid
        # sudo yum install libXaw libXaw-devel
        ;;
    debian)
        sudo apt-get install build-essential
        sudo apt-get build-dep emacs24
        ;;
    *)
        echo "ERROR: cannot determine os type. install dependencies manually or fix this script" >&2
        exit 1
        ;;
esac

################

keyring=gnu-keyring.gpg
keyring_local=~/Downloads/$keyring
if [ ! -f $keyring_local ] ; then
    curl -L --create-dirs --output $keyring_local http://ftp.gnu.org/gnu/$keyring
    gpg --import $keyring_local
fi

bundle=emacs-${release}.tar.xz
bundle_local=~/Downloads/$bundle
if [ ! -f $bundle_local ] ; then
    curl -L --create-dirs --output $bundle_local http://ftp.gnu.org/gnu/emacs/$bundle
fi

sig=${bundle}.sig
sig_local=~/Downloads/$sig
if [ ! -f $sig_local ] ; then
    curl -L --create-dirs --output $sig_local http://ftp.gnu.org/gnu/emacs/$sig
fi

# while ! gpg --verify $sig_local $bundle_local ; do
#     if [ -f $sig_local -a -f $bundle_local ] ; then
#         echo "ERROR: bundle file doesn't match its signature." >&2
#         read -e -p "Remove bundle and signature, and retry? [Y/n] " yn
#         case $yn in
#             Y|y)
#                 rm -f $sig_local $bundle_local
#                 ;;
#             N|n)
#                 echo "exiting because bundle does not match signature..."
#                 exit 1
#                 ;;
#         esac
#     fi
#     curl -L --create-dirs --output $sig_local http://ftp.gnu.org/gnu/emacs/$sig
#     curl -L --create-dirs --output $bundle_local http://ftp.gnu.org/gnu/emacs/$bundle
#     # gpg --keyserver pgpkeys.mit.edu --recv-key A0B0F199
#     # gpg --keyserver pgpkeys.mit.edu --recv-key 7C207910
# done

################

src_dir=~/src
build_dir=$src_dir/emacs-${release}

rm -rf $build_dir
tar -Jx -C $src_dir -f $bundle_local

################

cd $build_dir
./configure --with-modules --with-gnutls --with-gameuser=:games --with-x-toolkit=no --without-x --without-xpm --without-jpeg --without-tiff --without-gif --without-png --without-rsvg --without-imagemagick --without-xft --without-libotf --without-m17n-flt --without-toolkit-scroll-bars --without-xaw3d --without-xim --without-gconf --without-gsettings
# ./configure --with-x-toolkit=athena --without-toolkit-scroll-bars --without-dbus --without-gconf --without-gsettings
#./configure
make

sudo make install
sudo alternatives --install /usr/bin/emacs emacs /usr/local/bin/emacs 20000
sudo alternatives --install /usr/bin/emacsclient emacsclient /usr/local/bin/emacsclient 20000
