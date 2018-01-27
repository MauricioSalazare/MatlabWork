%% Read TRANSFORMER address and assign global coordinates in decimal notation
% The address of the Meter is in an Excel file
% The coordinates are requested via webrequest in openstreetmap database
% The coordinates in decimal notation are written back in the excel file

filename = 'Salvador_ID_Names_temp.xlsx';
[num,txt,raw] = xlsread(filename);
address = 2;                          % Specify column where is the address
coordinates = 'E';                    % Specify free column to write coordinates
sheet =1;
xlswrite(filename,["Latitude" "Longitude"],sheet,strcat(coordinates,num2str(1)));

for i=2:length(txt)                 % Assume that xls-file has table header
    getAddress = strsplit(char(txt(i,address)));
    query = [];
    for j = 1:length(getAddress)
        query = [query char(getAddress(j)) '+'];
    end
    requestHead = 'http://nominatim.openstreetmap.org/search?q=';
    requestTail = '&format=json&polygon=1&addressdetails=1';
    request = strcat(requestHead,query,requestTail);
    
    
    options   = weboptions('ContentType','text');
    getAnswer = webread(request, options);
    getAnswer = jsondecode(getAnswer);
    
    if ~isstruct(getAnswer)
        latitude  = getAnswer{1}.lat;
        latitude  = str2double(latitude);
        longitude = getAnswer{1}.lon;
        longitude = str2double(longitude);
    else
        latitude  = getAnswer.lat;
        latitude  = str2double(latitude);
        longitude = getAnswer.lon;
        longitude = str2double(longitude);       
    end
    
    toWrite = [latitude longitude];
    xlswrite(filename,toWrite,sheet,strcat(coordinates,num2str(i)));
    xlswrite(filename,latitude,sheet,strcat(coordinates,num2str(i)));    
end

