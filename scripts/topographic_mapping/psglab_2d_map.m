function[X] = psglab_2d_map(data,labels,PSmin,PSmax)
%PSGLAB_2D_MAP creates the 2D brain image form EEG signals
%
% function[X] = psglab_2d_map(data, ch_pos_path, show_text, color_map, grid_precision, global_vars)
%
% data: input data matrix
% options: input parameters definition
% global_vars: global variables definition
%
% See also PSGLAB_RUN PSGLAB_2D_MAPS_TO_AVI

% Additional:
% ch_pos_path: path to channels-position definiton file
% color_map: used colormap
% grid_precision: grid precision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PSGLab ver. 2.1: Polysomnographic Data Processing Matlab Toolbox (c) 2009-2013  %
% http://bio.felk.cvut.cz/psglab/                                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global mapObj

    % normalization
    data = (data - PSmin)/(PSmax-PSmin);


show_text = 1;
color_map =  jet(256);
grid_precision = 0.01;

min_x = 0.1;
min_y = 0.1;
max_x = 0.9;
max_y = 0.9;

center_x = max_x - min_x;
center_y = max_y - min_y;

n = length(labels);
posIndex = 1;
for ch1 = 1:(n)
    if( isnan(labels{ch1})~=1 )
        v=mapObj(labels{ch1});
        positions_electrodes(posIndex,1) = 0.9 * (v(1) - min_x) + min_x + 0.005;
        positions_electrodes(posIndex,2) = 0.9 * (v(2) - min_y) + min_y + 0.02;
        posIndex = posIndex + 1;
    end
end

electrodes_count = length(data);

for i = 1 : electrodes_count
	c = color_map(1 + floor(254 * data(i)), :);
end;

distance_matrix_electrodes = psglab_distance(positions_electrodes, positions_electrodes);
tmp = exp(-3*distance_matrix_electrodes);
weights_between_electrodes = tmp ./ repmat(sum(tmp, 2), 1, electrodes_count);

% -------------------------------------------------------------------------------------
data_real = data * inv(weights_between_electrodes'); % "subdural", original


for i = 1 : electrodes_count
	c = color_map(max(1, min(255, floor(255 * data_real(i)))), :);
end;

potentials_unmixed = weights_between_electrodes * data_real'; % for control
% -------------------------------------------------------------------------------------

% grid points
% [X Y] = meshgrid(0:0.01:1);
[X Y] = meshgrid(0:grid_precision:1);
X = X(:); Y = Y(:); grid_count = length(X);
distance_matrix_grid = psglab_distance([X Y], positions_electrodes);
tmp = exp(-3*distance_matrix_grid);
weights_between_electrodes_and_grid = tmp ./ repmat(sum(tmp, 2), 1, electrodes_count);

grid_potentials = weights_between_electrodes_and_grid * data_real';
% -------------------------------------------------------------------------------------

f(1) = figure;
clf;
hold on;
for i = 1 : grid_count
	c = color_map(max(1, min(255, floor(255 * grid_potentials(i)))), :);
	inx = find(X(i) == positions_electrodes(:, 1) & Y(i) == positions_electrodes(:, 2));
	if(~isempty(inx))
		%fprintf('%d: %2.2f vs %2.2f\n', inx, data(inx), grid_potentials(i));
	end;
   plot(X(i), Y(i), '.', 'MarkerSize', 20, 'Color', c);
end;

for i = 1 : electrodes_count
	c = color_map(1 + floor(254 * data(i)), :);
	plot(positions_electrodes(i, 1), positions_electrodes(i, 2), '.', 'MarkerSize', 15, 'Color', [0 0 0]);
end;

% xlabel('<--- left side    right side --->');
% ylabel('<--- back side    front side --->');
% title('coherence');
% axis([0 1 0 1]);
axis off;

F = getframe(f(1));
[X,Map1] = frame2im(F);
close(f);
%figure;

im01 = imread('define-electrodes-A.png');
if show_text
    im02 = imread('define-electrodes-B.png');
else
    im02 = imread('define-electrodes-C.png');
end;


X = (min(max(X,im01),im02));
X = X(21:size(X,1)-13, 66:size(X,2)-60, :);