clear;

% Directory with original WorldView Images
in_path = "/scratch/gpfs/rc5007/WV_GrIS_SWIceSlabs/imagery";
% Directory to save MATLAB compatible images
out_path = "/scratch/gpfs/rc5007/WV_GrIS_SWIceSlabs/mc_imagery";

cd(in_path);
files=dir('*.tif');
m=size(files,1); 
for i=1:m
    image = files(i).name;
    fprintf("%s\n", image);
    [A,R] = readgeoraster(image);
    out_file = strcat(out_path, "/", image(1:19), ".tif");
    geotiffwrite(out_file, A, R, "CoordRefSysCode", 3413);
end