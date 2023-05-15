clear;

% List of all images that you want to process
images = ["WV01_20120802153817" "WV01_20120802153816" "WV01_20120802153815" ...
    "WV01_20120802153814" "WV01_20120802153813" "WV01_20120713005153" ...
    "WV01_20120713005152" "WV01_20120713005151" "WV01_20120803164856" ...
    "QB02_20120729152314" "QB02_20120731154958" "QB02_20120731155001" ...
    "QB02_20120731155004" "WV01_20120713164417" "WV01_20120713164418" ...
    "WV01_20120713164419" "WV01_20120803164853" "WV01_20120803164854" ...
    "WV01_20120803164855"];

% Directory where WorldView image files are located
img_dir = "G:\WV_FullImage\";
% Directory where binary fracture maps and data masks are located
crev_dir = "D:\Data\Greenland\FirnStructure\IceBlobs\BinaryFiles\CleanFractureMaps\";

% Size of image chips - numerator is the approximate dimension in meters,
% denominator is the approximate resolution of the imagery
kernel = floor(150/0.51);

total_tiles = 0;
for k = 1:length(images)
    fprintf("Processing: %s\n", images(k));

    % Load binary fracture map
    file = strcat(crev_dir, "FracMap_", images(k), ".tif");
    [img, R] = readgeoraster(file);

    % Load data mask
    mask_file = strcat(crev_dir, "DataMask_", images(k), ".tif");
    [mask_img, ~] = readgeoraster(mask_file);

    % Load WorldView image
    img_file = strcat(img_dir, images(k), ".tif");
    [data, ~] = readgeoraster(img_file);

    % Horizontal and vertical dimensions of the whole image
    x_dim = size(img,2);
    y_dim = size(img,1);

    % Calculate leftover pixels in each dimension that don't make up a
    % whole image chip
    x_del = mod(x_dim, kernel);
    y_del = mod(y_dim, kernel);

    % Split the leftover pixels in half so that we skip half on each side
    % of the image
    x_shift = ceil(x_del/2);
    y_shift = ceil(y_del/2);

    % Variable to save all of the tiles
    tiles = floor(y_dim/kernel)*floor(x_dim/kernel);
    % First pixel of left side of image chip
    x_start = zeros(tiles,1); 
    % Last pixel of right side of image chip
    x_stop = zeros(tiles,1);
    % First pixel of top of image chip
    y_start = zeros(tiles,1);
    % Last pixel of bottom of image chip
    y_stop = zeros(tiles,1);
    % X coordinate of image chip center point
    x_coord = zeros(tiles,1);
    % Y coordinate of image chip center point
    y_coord = zeros(tiles,1);
    count = 1;
    % Tile the whole image based on the size of the kernel
    for m = 1:floor(y_dim/kernel)
        for p = 1:floor(x_dim/kernel)
            % Calculate left, right, top, and bottom bounds of image chip
            % in pixels
            a = (p-1)*kernel + 1 + x_shift;  % left
            b = p*kernel + x_shift;          % right
            c = (m-1)*kernel + 1 + y_shift;  % top
            d = m*kernel + y_shift;          % bottom

            % Calculate center pixel position in image chip
            x_center = floor(a + 0.5*(b - a));
            y_center = floor(c + 0.5*(d - c));

            % Extract the image chip from the image mask
            seg = double(mask_img(c:d, a:b));

            % If more than 75% of the image chip contains valid imagery,
            % save the pixel bounds of the image and calculate the
            % real-world x and y coordinates of the center of the image
            % chip
            if mean(seg(:)) >= 0.75
                x_start(count) = a;
                x_stop(count) = b;
                y_start(count) = c;
                y_stop(count) = d;
                x_coord(count) = R.XWorldLimits(1) + x_center*R.CellExtentInWorldX;
                y_coord(count) = R.YWorldLimits(1) + y_center*R.CellExtentInWorldY;
                count = count + 1;
            end
        end
    end

    % Remove extra, empty slots in the variable list
    ind = find(x_start == 0);
    x_start(ind) = [];
    x_stop(ind) = [];
    y_start(ind) = [];
    y_stop(ind) = [];
    x_coord(ind) = [];
    y_coord(ind) = [];

    % Generate a unique id number for each image chip
    id = 1:1:length(x_start);
    id = id';

    % Define Schema and Generate NetCDF Files
    schema = DefineSchema(size(x_start,1), kernel, kernel, images(k));
    file = strcat(crev_dir, images(k), ".nc");
    ncwriteschema(file, schema);
    ncwrite(file, 'id', id);
    ncwrite(file, 'x', x_coord);
    ncwrite(file, 'y', y_coord);
    ncwrite(file, 'x_start', x_start);
    ncwrite(file, 'x_stop', x_stop);
    ncwrite(file, 'y_start', y_start);
    ncwrite(file, 'y_stop', y_stop);

    % Extract the image chip from the WorldView image and binary fracture
    % map and then calculate fracture density for image chip
    image_data = uint8(zeros(size(x_start,1), kernel, kernel));
    label_data = uint8(zeros(size(x_start,1), kernel, kernel));
    fracture_density = zeros(length(x_start),1);
    for m = 1:size(fracture_density,1)
        % Actual image from WorldView
        image_data(m,:,:) = data(y_start(m):y_stop(m),x_start(m):x_stop(m));
        % Image chip from binary fracture map
        seg = img(y_start(m):y_stop(m),x_start(m):x_stop(m));
        label_data(m,:,:) = seg;
        % Image chip fracture density
        fracture_density(m) = mean(seg(:));
    end
    % Write to NetCDF file
    ncwrite(file, 'fracture_density', fracture_density);
    ncwrite(file, 'image_data', image_data);
    ncwrite(file, 'label_data', label_data);

    % Write CSV Metadata Files
    results = table(id,x_start,x_stop,y_start,y_stop,x_coord,y_coord,fracture_density);
    out_file = strcat(crev_dir, "FracTiles_", images(k), ".csv");
    writetable(results, out_file);

    % Keep track of total image chips we created
    total_tiles = total_tiles + length(id);

    % Clear the really large variables so that the whole system doesn't run
    % out of memory
    clear img;
    clear mask_img;
    clear data;
    clear image_data;
    clear label_data;
end


