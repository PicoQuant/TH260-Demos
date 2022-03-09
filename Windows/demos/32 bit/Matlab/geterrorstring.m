
function errstr = geterrorstring(errcode)


if nargin<1
    errstr = ' Invalid argument calling geterrorstring.m ';
end

Tmpstr    = blanks(40); % reserve enough length!
TmpstrPtr = libpointer('cstring', Tmpstr);

if (libisloaded('TH260lib'))   
        [ret, Tmpstr] = calllib('TH260lib', 'TH260_GetErrorString', TmpstrPtr, errcode);
	if (ret<0)
		errstr = ' Failed calling TH260_GetErrorString  ';
	else
		errstr = Tmpstr;
	end;
else
    errstr = ' TH260lib not loaded ';
end

