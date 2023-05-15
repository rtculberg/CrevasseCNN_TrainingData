# CrevasseCNN_TrainingData
Workflow for generating labeled training data for identifying ice sheet surface crevasses in high-resolution optical imagery. 

## Workflow

1. Re-save the original PGC image files so that MATLAB can read them without choking. This is stupid, but necessary, because MATLAB 
   can't handle pyramids.
	> Run \PreProcessing\MakeCompatibleImages.m

2. Run Kang Yang's supraglacial river detection code on the original WorldView images.
	> Download original code here: https://github.com/njuRS
	> Note that you will need to install DipLib to run this code, which can be found here: https://diplib.org/. The code as 
	  original written is only compatible with the old version of DipLib (2.9 or earlier, I believe). I edited the code to 
	  be compatible with the latest version of DipLib, that code is include in the \RiverDetectionCode directory. 
	> Edit \RiverDetectionCode\run_batch_river_detection.m so that it know where to find DipLib and where to find the WorldView images
	> Default settings for width, ppolength, smooth, and histCountThreshold are generally fine, but you can play with them if needed.
	> This 100% has to be done on the cluster - it takes loads of memory. Use the bash script (run_rivers.sh) to submit a job on della.
	  I needed to request 100G of memory to get it to reliably run to completion and it takes roughly 1hr per image. 

3. Binarize the output files from Step 2 by running \PostProcessing\BinarizeImages.m.
	> You can play with the noise threshold as needed - 10 usually works well for WorldView imagery in ice slabs areas. But I 
	  recommend looking at a few noise areas where the linear feature extractor is picking up on sastrugi or other non-fracture,
	  non-stream features to set that threshold.

4. Manually digitize the regions that contain fractures from the WorldView imagery in QGIS. Output should be a shapefile that covers 
   the regions with crevasses. 
   
5. Use the "Extract by mask layer" function in QGIS with the binary fractures maps produced in Step 3 and the fracture region shapefile 
   produced in Step 4 to create new binary images that only contain linear features from the manually identified fracture areas.

6. Remove the spurious border created by the image processing algorithm by running \PostProcessing\MaskBorder.m on the output of Step 5.

7. Tile all of the images and create a NetCDF file with all of the training data by running \PostProcessing\CreateImageChips.m.
	> Note that if you do not want to include training images with 0 fracture density, you will need to modify the code to throw out those
	  image chips. 