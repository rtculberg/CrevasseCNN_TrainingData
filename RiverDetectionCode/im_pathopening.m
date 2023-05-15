function outputFileName = im_pathopening(imageFile,lengthThreshold,histCountThreshold,outputpath)

[path,name,ext]=fileparts(imageFile);
outputFileName=strcat(outputpath, '/', name, '_cpo', num2str(lengthThreshold), ext);
fprintf('process %s\n',name);

if ~isfile(outputFileName)

%initialize dip_image toolbox
% run('/home/rc5007/share/DIPimage/dipstart.m');

info = geotiffinfo(imageFile);
[image,R] = geotiffread(imageFile);

image=single(image);

%I planed to use mask image to reduce computational time but it seems this
%mask image does not work in path opening function
mask = ones(size(image));

%dip_mask = dip_image(mask,'bin');
%dip_data = dip_image(image,'dfloat');
%dip_mask = mat2im(mask); %, 'bin');
dip_data = mat2im(image); %, 'dfloat');

% out = dip_pathopening(dip_data,dip_mask,lengthThreshold,0,1);
% image_path_opened = dip_array(out);
out = pathopening(dip_data,lengthThreshold,{'constrained','robust'});
image_path_opened = im2mat(out);

clear image;
clear dip_data;
clear out;

%pixels smaller than mean cannot be rivers. This stretch is used for final
%display purpose
meanPO = mean(image_path_opened(:));
image_path_opened(image_path_opened<meanPO) = meanPO;

image_path_opened=mat2gray(image_path_opened);
image_path_opened=uint8(image_path_opened*255);

image_path_opened = histCountCut(image_path_opened,histCountThreshold);

geotiffwrite(outputFileName,image_path_opened,R,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);

clear image_path_opened;
end

end
