@echo off
set ERR=%1
shift
shift
%0 %1 %2 %3 %4 %5 %6 %7 %8 %9 2> %ERR%
