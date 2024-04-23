# Running a script using a GPU on the super computer

1. Log into the super computer `ssh <user>@ssh.rc.byu.edu`
2. allocate gpu resource `--time=$1:00:00 --ntasks=1 --nodes=1 --gpus=1 --mem=4096M`
3. now you can run any of your scripts using a GPU


### tips:
- If you plan to do this a lot consider making a bash function in your .bashrc
```
gpujob() {
    #time really is the
    salloc --time=$1:00:00 --ntasks=1 --nodes=1 --gpus=1 --mem=4096M
}
```
I have it set so that I can specify the runtime
