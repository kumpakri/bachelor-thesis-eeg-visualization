data = [0 0.2 0.1 0.4 0.5 0.3 0.1 0.2 0.7 0.6 0.7 0.9 0.3 0.2 0.3 0.4 0.7 0.1 1];

% http://commons.wikimedia.org/wiki/File:21_electrodes_of_International_10-20_system_for_EEG.svg
%
% Fp1
% Fp2
% F3
% F4
% C3
% C4
% P3
% P4
% O1
% O2
% F7
% F8
% T3
% T4
% T5
% T6
% Fz
% Cz
% Pz

im = psglab_2d_map(data,labels1020);

imshow(im);