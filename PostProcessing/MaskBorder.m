%%

clear;

% List of all images to process
images = ["WV01_20120803164856" "QB02_20120729152314" "QB02_20120731154958" ...
    "QB02_20120731155001" "QB02_20120731155004" "WV01_20120713164417" ...
    "WV01_20120713164418" "WV01_20120713164419" "WV01_20120803164853" ...
    "WV01_20120803164854" "WV01_20120803164855"...
    "WV01_20120802153817" "WV01_20120802153816" "WV01_20120802153815" ...
    "WV01_20120802153814" "WV01_20120802153813" "WV01_20120713005153" ...
    "WV01_20120713005152" "WV01_20120713005151"];

% Directory with WorldView images
img_dir = "Z:\RileyCulberg\FeatureExtraction\WVImages\";
% Directory with binary fractures images that have been clipped to only
% show regions where we think there are fractures
crev_dir = "D:\Data\Greenland\FirnStructure\IceBlobs\BinaryFiles\CrevasseOnly\";
% Place where you want to save the masks
out_dir = "D:\Data\Greenland\FirnStructure\IceBlobs\BinaryFiles\CleanFractureMaps\";

for k = 1:length(images)
    fprintf("Processing: %s\n", images(k));
    
    clear image_file;
    clear img;
    clear R;
    clear index;
    clear ind;
    clear split;
    clear crev_file;
    clear crev_img;
    clear clean_data;

    % Read in the WorldView file
    img_file = strcat(img_dir, images(k), ".tif");
    [img, R] = readgeoraster(img_file);

    % Find the edges of where the image actually begins the data and add a
    % 5 pixel buffer on all sides

    % Top and bottom borders
    index = uint8(ones(size(img)));
    for m = 1:size(img,1)
        ind = find(img(m,:) == 0);
        if length(ind) < size(img,2)
            split = find(diff(ind) > 1);
            index(m,1:ind(split)+5) = 0;
            index(m,ind(split+1)-5:end) = 0;
        else
            index(m,:) = 0;
        end
    end

    % Left and right borders
    for m = 1:size(img,2)
        ind = find(img(:,m) == 0);
        if length(ind) < size(img,2)
            split = find(diff(ind) > 1);
            index(1:ind(split)+5,m) = 0;
            index(ind(split+1)-5:end,m) = 0;
        else
            index(m,:) = 0;
        end
    end

    clear img;
   
    % Load the binary fracture files
    crev_file = strcat(crev_dir, "Crevasse_", images(k), "_binary_10.tif");
    [crev_img, ~] = readgeoraster(crev_file);

    % Remove the image processing induced border around the binary fracture
    % image by multiplying it with "good" data mask with the 5 pixel edge
    % buffer
    clean_data = crev_img(1:size(index,1), 1:size(index,2)).*index;

    % Write the clean binary fracture image to the output directory
    outfile1 = strcat(out_dir, "FracMap_", images(k), ".tif");
    geotiffwrite(outfile1, clean_data, R, "CoordRefSysCode", 3413);

    % Write the data mask to the output directory (1 where there is data in
    % the original image, 0 where there is no data)
    outfile2 = strcat(out_dir, "DataMask_", images(k), ".tif");
    geotiffwrite(outfile2, index, R, "CoordRefSysCode", 3413);
end



