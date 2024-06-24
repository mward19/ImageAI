from cryoet_data_portal import Client, Run, Tomogram
import sys
import os

client = Client()
# IDs for run to download
datasetid = sys.argv[1]
runid = sys.argv[2]
# get correct run and download it
run = Run.find(client, query_filters=[Run.id == runid, Run.dataset.id == datasetid])[0]
tomoid = run.tomogram_voxel_spacings[0].tomograms[0].id
tomogram = Tomogram.get_by_id(client, tomoid)
tomogram.download_mrcfile()

# rename and move the file
file_path = '/Users/mward19/Documents/Segmentation/tomogram_seg/raw_tomograms/dataset_'+datasetid+'/run_'+runid+'.mrc'
os.rename(tomogram.name+'.mrc',file_path)
# so you can get the file name in bash as a variable
print(file_path)