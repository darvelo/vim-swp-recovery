# Recover Your Work

Have you ever had vim open with a ton of files, only to be be burned by a computer crash, leaving a horde of vim swap files in its wake? Amigo/Amiga, this is for you.

This script will automatically find vim swapfiles recursively under the current directory. One by one, it'll delete the swapfile if it's byte-equal to the original file it points to, and if not, optionally vimdiff with the original.

If one of the swapfiles points to a directory, which can happen while using netrw, the swapfile will be deleted automatically for your convenience.

A message will be displayed if the swapfile or original file are already in use by another process. The files will be skipped.

## Usage

You can search automatically under the current directory with the single argument, `--use-find`.

You can also instead pass your own swapfiles as arguments. To do this quickly you could pass a directory as the first argument rather than a bunch of files as arguments and `find` will be used under the hood:

```bash
vim-swp-recovery.sh .first.swp .second.swp

# OR

vim-swp-recovery.sh dir-to-search
```

**DO NOT** pass a directory or swapfiles with spaces in the filename, nor a directory with swapfiles that have spaces in the filenames. Unpredictable things may happen. You've been warned!

# Credits

This is an expanded and cleaned up version of a script posted on [the vim wiki](http://vim.wikia.com/wiki/Swap_file_%22...%22already_exists!_-_so_diff_it). Many thanks to Fritzophrenic, who has saved me many precious life-minutes. They add up, ya know!
