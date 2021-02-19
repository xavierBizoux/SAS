libname VISUAL cas caslib="VISUAL";

data selection;
set VISUAL.postsecondary_school_locations;
distance=geodist(%sysevalf(&lat),%sysevalf(&lon), lat, lon, 'M');
if distance < %sysevalf(&dist) then output;
run;

proc json out=_webout nosastags pretty;
export selection;
run;