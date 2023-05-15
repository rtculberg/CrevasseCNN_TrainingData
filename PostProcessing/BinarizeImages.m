%% Binarize Images

% Directory where the outputs of Kang Yang's river detection code was saved
in_dir = "D:\Data\Greenland\Crevasses\SWIceSlabs\processed\";
% Directory where you want to save the files
out_dir = "D:\Data\Greenland\Crevasses\SWIceSlabs\binary\";

% Make a list of all valid image files in the input directory
dat = dir(in_dir);
files = [];
for k = 1:length(dat)
    if length(data(k).name) > 4
        files = vertcat(files, string(data(k).name));
    end
end

% Binarize images by setting all pixels > 10 to 1 and all pixels <= 10 to
% 0 - note that you can play with this threshold to get more or less
% features. I recommend looking at a "noisy" place in one of the images to
% get a sense of the best cutoff. (A place where the linear edge detection
% appears to be picking up sastrugi or other non-stream, non-fracture
% features). 
for k = 1:length(files)
    fprintf('%s\n', files(k));
    [A1,R] = georasterread(char(strcat(dir1, files(k), "_bandpass_gabor_cpo20.tif")));    
    bin = imbinarize(double(A1),10);
    outfile = strcat(out_dir, files(k), "_binary_10.tif");
    geotiffwrite(char(outfile), bin, R, 'CoordRefSysCode', 3413);
end
