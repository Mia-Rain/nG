#!/bin/sh
# create a base system at ./chroot
# EVERYTHING (minus go) is fresh compiled
has() {
  case "$(command -v $1 2>/dev/null)" in
    alias*|"") return 1
  esac
}
has go || { echo "golang compiler is required on the host system..."; exit 1;}
# needed for kati
has curl || { echo "curl is required on the host systtem"; exit 1;}
# for downloading sources
has bsdtar || { echo "bsdtar is required on the host system"; exit 1;}
# for extracting sources
has mkdir || { echo "basic coreutils are required..."; exit 1;}
mkdir ./chroot ./bin 2>/dev/null
rm chroot/* bin/* -rf 2>/dev/null # clean chroot and bin before starting
mkdir -p chroot/builddir; bdir="$(realpath chroot/builddir)"
cd chroot; org=$(realpath ${PWD}/../)
IFS=""; while read -r p; do # no need for EOF check
  case "$p" in
    "#"*) ;; # ignore lines with comments
     *) url="${p##*- }"
      echo "Downloading/Extracting ${p%% -*} ..." 
      cd ${bdir}; curl -L "$url" --progress-bar | bsdtar -xf -;;
  esac
done < ${org}/sources # read from sources and download
cd ${org}
for i in bin etc lib dev usr; do # create some base folders
  mkdir -p "${org}/chroot/${i}"
done
# ./loc read func
loc(){
  while read -r p || [ -n "$p" ]; do
    case "$p" in # basically grep for $1
      *"${1}"*) printf '%s\n' "${p##*- }"
    esac
  done < ${org}/loc
}
for i in ${org}/bscripts/*; do # loop over all build scripts
  . ${i} # source build script
  [ "$pkg" = "ex" ] && continue # DO NOT ATTEMPT TO READ EXAMPLE SCRIPT
  IFS=" "; for dep in ${hbinrequires}; do # loop over all host bin deps
    has $dep || { echo "$i is required on the hostsystem"; exit 1;}
  done
  cd ${dir}; ${cmd}
  [ -e "${out}" ] && {
    chmod +x "${out}" # mark as excutable
    cp "${out}" "${org}/bin/" # copy to nG's local bin/
    export PATH="${org}/bin:$PATH" # set PATH to contain local bin/
    # also make sure local bin/ is first in PATH
  :;} || {
    echo "$out NOT FOUND... CANNOT CONTINUE; BUILD MUST HAVE FAILED"
    exit 1
  }
done
