# Viewing Tomograms Via Imod

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

