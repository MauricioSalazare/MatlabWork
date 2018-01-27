%% IMPORT DATA FROM THE GLOBAL RADIANCE 
% Information extracted from: 
% KNMI (Koninklijk Nederlands Meteorologisch Instituut)
% http://projects.knmi.nl/klimatologie/uurgegevens/selectie.cgi
% filename='KNMI_20180116_hourly.txt'


function [dateIndex, dataArray, Station] = importSolar(filename)

% close all, clear all, clc, format compact
% filename =  'KNMI_20180107_hourly.txt';

fid = fopen(filename, 'r');
% Read the header lines of the climate data:
% Values on the comments is an example of the header from a weather file.

% line1 = fgetl(fid); % # BRON: KONINKLIJK NEDERLANDS METEOROLOGISCH INSTITUUT (KNMI)
% line2 = fgetl(fid); % # Opmerking: door stationsverplaatsingen en veranderingen in waarneemmethodieken zijn deze tijdreeksen van uurwaarden mogelijk inhomogeen! Dat betekent dat deze reeks van gemeten waarden niet geschikt is voor trendanalyse. Voor studies naar klimaatverandering verwijzen we naar de gehomogeniseerde reeks maandtemperaturen van De Bilt <http://www.knmi.nl/klimatologie/onderzoeksgegevens/homogeen_260/index.html> of de Centraal Nederland Temperatuur <http://www.knmi.nl/klimatologie/onderzoeksgegevens/CNT/>.
% line3 = fgetl(fid); % #
% line4 = fgetl(fid); % #
% line5 = fgetl(fid); % # STN      LON(east)   LAT(north)     ALT(m)  NAME
% line6 = fgetl(fid); % # 391:         6.197       51.498      19.50  ARCEN
% line7 = fgetl(fid); % #
% line8 = fgetl(fid); % # YYYYMMDD = datum (YYYY=jaar,MM=maand,DD=dag); 
% line9 = fgetl(fid); % # HH       = tijd (HH=uur, UT.12 UT=13 MET, 14 MEZT. Uurvak 05 loopt van 04.00 UT tot 5.00 UT; 
% line10 = fgetl(fid); % # Q        = Globale straling (in J/cm2) per uurvak; 
% line11 = fgetl(fid);% #
% line12 = fgetl(fid);% # STN,YYYYMMDD,   HH,    Q
% line13 = fgetl(fid);% #

readline(1) = {'#'};
ii=1;
continueLoop = true;
while continueLoop
   readline(ii) =  {fgetl(fid)};    
%    disp(readline{ii});
   if ~(readline{ii}(1) == '#')
       continueLoop = false;
   end
   ii=ii+1;
end
% The loop stop, and I will loose first hour of the file
% disp(readline(6));   
buffer = fread(fid, Inf); % Read the rest of the file
fclose(fid);

% Read the Weather station information
values = strsplit(readline{6});
Station.station = char(values(length(values)));
Station.lat = str2double(char(values(4)));
Station.lon = str2double(char(values(3)));

filename = [filename(1:end-4) '_clean' '.csv'];
fid = fopen(filename, 'w');
fwrite(fid,buffer);
fclose(fid);

data = readtable(filename, 'ReadVariableNames',false, 'Format','%f %{yyyymmdd}D %f %f');
dateValues = data{:,2};
dataArray =  data{:,[3:4]};
dateIndex = datetime([datestr(dateValues,'yyyy-MM-dd ')  num2str(dataArray(:,1)-1)], 'InputFormat', 'yyyy-MM-dd HH');
dataArray = dataArray(:,2);
end
