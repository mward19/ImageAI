# About
`segmentation` contains scripts and information about segmenting tomograms. 
Tomograms from the CryoET Data Portal are generally saved with the `.mrc` file format.
This file format is not compatible with ITK-SNAP, an open source 3D segmenation program.
Many of the scripts in `segmentation/scripts` simply convert between file formats.

# Segmentation Goals
Our goal is to segment some subset of the tomograms stored on the CryoET Data Portal.

# Organizing Files for Segmentation
 - Directories of tomograms and segmentations should be organized by dataset ID with the 
 prefix `dataset`, i.e., a directory called `dataset_10067`.
 - Tomograms should be organized by run ID and placed inside dataset directories with
 the prefix `run`, i.e., `dataset_10067/run_1012.mrc` or `dataset_10067/run_1012.mha`.
 - Segmentations should be organized by run ID and placed inside dataset directories with
 the prefix `seg`, i.e., `dataset_10067/seg_1012.mha`.

# Segmentation Pipeline
 - Setup (already done on the Mac with the Wacom tablet)
        - Download `seg_setup.sh`, install 
        [ITK-SNAP](http://www.itksnap.org/pmwiki/pmwiki.php?n=Downloads.SNAP3).

        - Run the script `seg_setup.sh` by typing `source seg_setup.sh` where the script is
        located.

        - Be sure that ITK-SNAP is installed and callable from the terminal with the
        command `itksnap`. In Linux this seems to require editing $PATH to include the
        `itksnap` executable included in the downloaded directory.

         - Be sure the current python environment has the necessary packages installed
         (like `mrcfile`). This is easy with a Python virtual environment.

 - Activate the python environment in which the necessary packages are installed. On the
 Mac, where setup is complete, call `source py_research/bin/activate`.

 - Download and/or locate a tomogram to segment.

 - Call `segment [path/to/myfile.mrc]` to convert `myfile.mrc` to a .mha file and open it 
 in ITK-SNAP

 - Segment the image as desired

 - When you are done segmenting, in the program, do the following:
         - Save the segmentation by selecting "Segmentation -> Save Segmentation Image..." 
         and use the `.mha` (MetaImage) filetype, with whatever filename you choose.
         - Save the labels by selecting "Segmentation -> Label Editor -> Actions... ->
         Export", with whichever filetype or filename you choose.

 - Close itksnap

 - In the terminal, the segmenatation and labeling you have just created are now saved in 
 the SegData folder.

 - In the folder in which the original .mrc file came from, call
 `to_julia SegData/[mysegmentation.mha]` to convert the .mha segmentation data to a Julia
 array, which is saved in a `.jld2` (JLD2) file.
