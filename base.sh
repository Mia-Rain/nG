#!/bin/sh
# create a base system at ./chroot
# EVERYTHING (minus go) is fresh compiled
has() {
  case "$(command -v $1 2>/dev/null)" in
    alias*|"") return 1
  esac
}
has go || { echo "The golang compiler is required on the host system..."; exit 1;}
# needed for kati
has curl || { echo "curl is required on the host systtem"; exit 1;}
# for downloading sources
has bsdtar || { echo "bsdtar is required on the host system"; exit 1;}
# for extracting sources
rm chroot/builddir -rf 2>/dev/null
mkdir -p chroot/builddir; bdir="$(realpath chroot/builddir)"
IFS=""; while read -r p; do # no need for EOF check
  case "$p" in
    "#"*) ;; # ignore lines with comments
     *) org=${PWD}; url="${p##*- }"
      echo "Downloading/Extracting ${p%% -*} ..." 
      cd ${bdir}; curl -L "$url" --progress-bar | bsdtar -xf -;;
  esac
done < ./sources # read from sources and download
cd ${org}
