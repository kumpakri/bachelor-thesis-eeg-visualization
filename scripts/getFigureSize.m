function [width,height] = getFigureSize(ScreenSize,cols,rows)
% Returns optimal width and height of a figure to plot square shaped
% pictures in number of columns and rows specified in input.
% ScreenSize    - size (1x2) of the screen [x,y]
% cols          - number of columns in figure
% rows          - number of rows in figure
screenWidth = ScreenSize(3);
screenHeight = ScreenSize(4);

%expects a screen with larger width than its height
a = screenHeight;

while( (rows*a) > screenHeight )
    a = a-1;
end

while( (cols*a) > screenWidth )
    a = a-1;
end

width = cols*a;
height = rows*a;