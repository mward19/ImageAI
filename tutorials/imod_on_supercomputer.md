# Tutorial for using IMOD on the supercomputer

### Step 1:
Install XQuartz (for mac users) using [this link](https://www.xquartz.org/)

### Step 2:
 - log into the supercomputer
 - edit your .bashrc script by adding these two lines
```bash
export PATH="/grphome/fslg_imagseg/builds/imod_4.11.25/bin:$PATH"
export IMOD_DIR=/grphome/fslg_imagseg/builds/imod_4.11.25
```
### Step 3:
IMOD is now set up.
Next time you access the supercomputer simply type  `ssh -X` before your username login
##### For Example:
```bash
ssh -X myusername42@ssh.rc.byu.edu
imod
```
This will ensure that when the imod command is used, it will display through your mac GUI

