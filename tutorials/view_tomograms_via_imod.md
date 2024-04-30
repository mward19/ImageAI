# Viewing Tomograms Via Imod
Imod is currently one of the top software for viewing and annotating tomorgams,
among [other](https://bio3d.colorado.edu/imod/doc/program_listing.html) things.
This tutorial is only for those using mac, although it is almost identical for
Linux. 

## MacOS(Sanoma 14.4.1)
1. Go [here](https://bio3d.colorado.edu/imod/download.html#Latest-Mac)
2. Download the [command line self installing file](https://bio3d.colorado.edu/imod/osx/imod_4.11.25_osx10.14.sh)
3. Run the file: `bash imod_4.11.25_osx10.14.sh`
  - You can run: `bash imod_4.11.25_osx10.14.sh -h`
4. Unless specified otherwise, this added the `IMOD` directory either in your home drive or in `/Applications`. Normally you would be done. But there is a pathing error that needs to be fixed. There is a script in the `IMOD` directory called `IMOD-mac.sh` sourcing this script will fix your pathing so you can run `imod` from the command line. SO I dont have to run this every time I reopen the terminal I simply add `source <path/to/IMOD-mac.sh` to my`.bashrc`
5. Done now you should be able to run Imod!

## Downloading a Tomogram (TODO)
1. Option 1: Download a tomogram and .mod file from one of the super computer
2. Option 2: Download via the czi cryoET data portal

## View Tomogram and annotation using IMOD
1. Run: `imod <path/to/mrc> <path/to/.mod>`
2. Now you should see the tomogram
3. if you want to see the annotation open the slicer window `Image>Slicer` then open the angles window `Edit>Angles` 

## Install Imod on the SuperComputer(Red Hat)
1. Run the linux install .sh [file](https://bio3d.colorado.edu/imod/AMD64-RHEL5/imod_4.11.25_RHEL7-64_CUDA10.1.sh) using the -dir <dir> and -skip options. replace <dir> with the location you want the application to be located. Helpful tip, when you see the symbols < > never actually put them in the command they always are just to show what needs to be decided by the user. 
2. Unless specified otherwise, this added the `IMOD` directory either in your home drive or in `/Applications`. Normally you would be done. But there is a pathing error that needs to be fixed. There is a script in the `IMOD` directory called `IMOD-linux.sh` sourcing this script will fix your pathing so you can run `imod` from the command line. SO I dont have to run this every time I reopen the terminal I simply add `source <path/to/IMOD-linux.sh` to my`.bashrc`

3. Now you can run imod comamnds in your terminal on the supercomputer. If you
   want to use the GUI to see tomograms you will need to use X forwarding. This
   is done by adding -X option when sshing into the super computer. If you are
   using mac you will need to have [xQuartzs](https://www.xquartz.org/) installed.
