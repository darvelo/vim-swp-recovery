#!/usr/bin/env bash
#
# The MIT License (MIT)
#
# Copyright (c) 2014 David Arvelo
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

args=()

if [ -z "$1" ]; then
  echo "Automatically find vim swapfiles created after a crash and one by one, delete it if it's byte-equal to the original file it points to, and if not, optionally vimdiff with the original. Also checks if the original file is a directory or currently in use by another process."
  echo
  echo "usage: $0 [--use-find | vim-swap-files...]"
  echo
  echo "  --use-find: uses the find command to search recursively for *.sw[a-z] files under the current directory to process."
  exit 0
elif [ -d "$1" ]; then
  args=($(find "$1" -name "*.sw[a-z]"))
elif [ "$1" == "--use-find" ]; then
  args=($(find $PWD -name "*.sw[a-z]"))
else
  args=($@)
fi

printf "Files found:"

if [ -z "$args" ]; then
  printf " none.\n"
  exit 0
else
  printf "\n"
  echo "------------"
  for arg in "${args[@]}"; do
    echo "$arg" 
  done
fi

function _prompt_yn () {
  while true; do
    read -p "$1 [y|n] " yn

    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

function diffRecoveredFile () {
  local origfile="$1"
  local swapfile="$2"
  local recoverfile="$3"

  echo "Removing the swapfile in order to open the original file with vimdiff."
  rm "$swapfile"

  vimdiff "$recoverfile" "$origfile"

  if _prompt_yn "Delete recovered file?"; then
    echo "Removing the recoverfile."
    rm "$recoverfile"
  fi
}

function processSwapFile() {
  # path plus swapfile filename
  local swapfile=`readlink -f "$1"`

  if [[ ! "$swapfile" =~ \.sw[a-z]$ ]]; then
    echo "File $swapfile was not a swapfile. Skipping."
    return
  fi

  # just the full dirpath the swapfile is in, no trailing slash
  local path=`dirname "$swapfile"`
  # the swap filename itself
  local swapfileMinusPath=`basename "$swapfile"`
  # the original file the swap file is referring to. just the filename
  local origfileMinusPath=$(echo $swapfileMinusPath | sed -r 's/^\.([^/]*)\.sw[a-z]$/\1/')
  # the original file prepended with its path
  local origfile="$path/$origfileMinusPath"
  # the tmp file it'll be recovered to in order to perform a vimdiff
  local recoverfile=${3:-"${path}/${swapfileMinusPath}-recovered"}

  echo "* Working on file: $swapfile"

  if [[ "$swapfileMinusPath" == ".sw[a-z]" ]]; then
    echo "The file $realfile was only a .swp file, meaning it could have been an unsaved buffer. You should recover it manually. Leaving it alone."
    return
  fi

  for f in "$origfile" "$swapfile"; do
    if [ -d "$f" ]; then
      echo "File $f is a directory. Deleting swp file."
      rm "$swapfile"
      return
    elif [ ! -f "$f" ]; then
      echo "File $f does not exist." >&2
      return
    elif fuser "$f"; then
      echo "File $f in use by another process." >&2
      return
    fi
  done

  if [ -f "$recoverfile" ]; then
      echo "Recover file $recoverfile already exists. Delete existing recover file first." >&2
      return
  fi

  # create recoverfile
  vim -E -s -X -u /dev/null --noplugin -r "$swapfile" -c ":w $recoverfile" -c ":q"

  if cmp -s "$origfile" "$recoverfile"; then
    echo "Original file and the recoverfile (created from the swapfile) were byte-equal. Removing the swapfile and recoverfile."
    rm "$swapfile" "$recoverfile"
    return
  else
    echo "Original file and recoverfile were not byte-equal."
  fi

  if [ "$origfile" -nt "$swapfile" ] && [ `stat -c%s "$origfile"` -gt `stat -c%s "$recoverfile"` ]; then
    echo "The original file is newer than the swapfile and larger than the recoverfile."

    if _prompt_yn "Delete recovered file and swapfile without doing a diff? If no, the swapfile will be removed anyway in order to perform a vimdiff."; then
      echo "Removing the swapfile and recoverfile."
      rm "$swapfile" "$recoverfile"
      return
    fi
  else
    echo "Swapfile is not newer than the original file and/or the recoverfile is not larger than the original file. Let's do a diff."
  fi

  printf "\nPress Enter to continue...\n"
  read

  # origfile wasn't byte-equal with recoverfile and:
  # - swapfile was newer than origfile
  # - recoverfile was larger than origfile
  # - user requested not to delete recoverfile outright
  diffRecoveredFile "$origfile" "$swapfile" "$recoverfile"
}

for swapfile in "${args[@]}"; do
  echo
  processSwapFile "$swapfile"
done

exit 0
