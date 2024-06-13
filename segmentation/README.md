# About
`segmentation` contains scripts and information about segmenting tomograms. Tomograms from the CryoET Data Portal are generally saved with the `.mrc` file format. This file format is not compatible with ITK-SNAP, an open source 3D segmenation program. Many of the scripts in `segmentation/scripts` simply convert between file formats.

# Segmentation Goals
Our goal is to segment some subset of the tomograms stored on the CryoET Data Portal.

# Organizing Files for Segmentation
 - Directories of tomograms and segmentations should be organized by dataset ID with the prefix `dataset`, i.e., a directory called `dataset_10067`.
  
 - Tomograms should be organized by run ID and placed inside dataset directories with the prefix `run`, i.e., `dataset_10067/run_1012.mrc` or `dataset_10067/run_1012.mha`.
  
 - Segmentations should be organized by run ID and placed inside dataset directories with the prefix `seg`, i.e., `dataset_10067/seg_1012.mha`.

# Segmentation Pipeline
 - Setup (already done on the Mac with the Wacom tablet)
     - Download `seg_setup.sh`, install [ITK-SNAP](http://www.itksnap.org/pmwiki/pmwiki.php?n=Downloads.SNAP3).
     - Run the script `seg_setup.sh` by typing `source seg_setup.sh` where the script is located.
     - Be sure that ITK-SNAP is installed and callable from the terminal with the command `itksnap`. In Linux this seems to require editing $PATH to include the `itksnap` executable included in the downloaded directory.
     - Be sure the current python environment has the necessary packages installed (like `mrcfile`). This is easy with a Python virtual environment.

 - Activate the python environment in which the necessary packages are installed. See the section "Using the Mac" in this document to do this on the Mac, where setup is already complete.

 - Download and/or locate a tomogram to segment. Move and rename the file based on the guidelines in the "Organizing Files for Segmentation" section of this document.

 - Inside the main segmentation directory (on the Mac, this is `tomogram_seg`), call `segment [path/to/myfile.mrc]` to convert `myfile.mrc` to a .mha file and open it in ITK-SNAP. 
   - <small>(Calling the script in the main segmentation directory is not strictly necessary, but as `segment` is currently written, calling `segment` in other folders will create new `SegData` directories in wherever you called `segment`.)</small>

 - Segment the image as desired

 - When you are done segmenting, in the program, do the following:
      - Save the segmentation by selecting "Segmentation → Save Segmentation Image..." and use the `.mha` (MetaImage) filetype, with a filename like `seg_1234.mha`, as described in the "Organizing Files for Segmentation" section of this document.
      - If desired, save the labels by selecting "Segmentation → Label Editor → Actions... → Export", with whichever filetype or filename you choose.

 - Close ITK-SNAP. (See "How to Segment in ITK-SNAP".)

 - Interrupt the now completed `segment` script with **Ctrl+C**. In the terminal, the segmenatation and labeling you have just created are now saved in the SegData folder. 

 - Upload new segmentations to the supercomputer using `scp`. On the supercomputer, the segmenations are currently stored in `~/fsl_groups/grp_tomo_db1_d1/compute/Segmentation`. For example, to reupload the entire `SegData` folder to the supercomputer, in the local folder in which `SegData` is located, call `scp -r SegData [BYU ID]@ssh.rc.byu.edu:~/fsl_groups/grp_tomo_db1_d1/compute/Segmentation`.

# Extra Scripts
 - In the folder in which the original .mrc file came from, call `to_julia SegData/[mysegmentation.mha]` to convert the .mha segmentation data to a Julia array, which is saved in a `.jld2` (JLD2) file. 

# How to Segment in ITK-SNAP
- Begin by enhacing the contrast of the image with **Ctrl+J** or "Tools → Image Contrast → Auto-Adjust Contrast (all layers)".

- For basic manual segmentation, choose the paintbrush tool, which by default is a paintbrush icon located in the panel at the left of the screen under the heading "Main Toolbar".

- Use the paintbrush to color in the outer membrane of the bacteria every few layers of the image.

- Once you have colored in the membrane every few layers of the image, interpolate between the layers with "Tools → Interpolate Labels", selecting "Morphological Interpolation", "Interpolate a single label", and "Interpolate along a single axis" (Axial). The interpolation will take a minute or so. 

- To see the updated segmentation, click "update" below the 3D rendering window.

- For more information about segmentation in ITK-SNAP, see the [documentation](http://www.itksnap.org/pmwiki/pmwiki.php?n=Documentation.SNAP3).

# Using the Mac
 - Sign in with the "Matthew Ward" account.
 
 - The tomogram segmentation stuff is in `~/Documents/Segmentation/tomogram_seg`.

 - To activate the Python virtual environment, navigate to `~/Documents/Segmentation/tomogram_seg` and call `source py_research/bin/activate`.

 - Download new tomograms to `raw_tomograms` (for now. this is not strictly necessary). Rename and organize them as described in the Organizing Files for Segmentation section of this document.
