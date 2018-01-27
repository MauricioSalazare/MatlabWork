%% IMPORT WEATHER DATA FROM THE - KNMI 
% Information extracted from: 
% KNMI (Koninklijk Nederlands Meteorologisch Instituut)
% http://projects.knmi.nl/klimatologie/uurgegevens/selectie.cgi
% All elements Description:
% DD	Wind direction (in degrees) averaged over the last 10 minutes of the last hour (360 = north, 90 = east, 180 = south, 270 = west, 0 = windless 990 = changeable) See http://www.knmi.nl/ knowledge-and-datacentre / background / climatic-brochures-and-books
% FH	Hourly average wind speed (in 0.1 m / s). See http://www.knmi.nl/kennis-en-datacentrum/achtergrond/klimatologische-brochures-en-boeken
% FF	Wind speed (in 0.1 m / s) averaged over the last 10 minutes of the last hour
% FX	Highest gust (in 0.1 m / s) over the last hour
% T	Temperature (in 0.1 degrees Celsius) at 1.50 m altitude during observation
% T10N	Minimum temperature (in 0.1 degrees Celsius) at 10 cm height in the last 6 hours
% TD	Dew point temperature (in 0.1 degrees Celsius) at 1.50 m altitude during observation
% SQ	Duration of sunshine (in 0.1 hours) per hour, calculated from global radiation (-1 for <0.05 hours)
% Q	Global radiation (in J / cm2) per hour compartment
% DR	Duration of precipitation (in 0.1 hour) per hour compartment
% RH	Hourly of precipitation (in 0.1 mm) (-1 for <0.05 mm)
% P	Air pressure (in 0.1 hPa) converted to sea level, during observation
% VV	Horizontal view during observation (0 = less than 100m, 1 = 100-200m, 2 = 200-300m, ..., 49 = 4900-5000m, 50 = 5-6km, 56 = 6-7km, 57 = 7- 8km, ..., 79 = 29-30km, 80 = 30-35km, 81 = 35-40km, ..., 89 = more than 70km)
% N	Overcast (overlying degree of the upper air in eighths), during observation (9 = above air invisible)
% YOU	Relative humidity (in percentages) at 1.50 m altitude during observation
% WW	Weather code (00-99), visual (WW) or automatic (WaWa) observed, for the current weather or the weather in the past hour. See http://bibliotheek.knmi.nl/scholierenpdf/weercodes_Nederland
% IX	Weather code indicator for the way of observing on a manned or automatic station (1 = manned using code from visual observations, 2,3 = manned and omitted (no significant weather phenomenon, no data), 4 = automatic and recorded (using code from visual observations), 5.6 = automatic and omitted (no significant weather phenomenon, no data), 7 = automatic using code from automatic observations)
% M	Fog 0 = not occurred, 1 = occurred in the previous hour and / or during the observation
% R	Rain 0 = not occurred, 1 = occurred in the previous hour and / or during the observation
% S	Snow 0 = not occurred, 1 = occurred in the previous hour and / or during the observation
% O	Thunderstorm 0 = not occurred, 1 = occurred in the previous hour and / or during the observation
% Y	Ice formation 0 = not occurred, 1 = occurred in the previous hour and / or during the observation

% filename='KNMI_20180116_hourly.txt'
% filename='KNMI_20180121_hourly.txt'

function [weatherInfo, Station] = importWeather(filename)

% close all, clear all, clc, format compact
% filename =  'KNMI_20180107_hourly.txt';

fid = fopen(filename, 'r');
% Read the header lines of the climate data:
% Values on the comments is an example of the header from a weather file.

%% EXAMPLE OF A HEADER LINE - http://projects.knmi.nl/klimatologie/uurgegevens/selectie.cgi

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


%% READ UNTIL THE HEADER IS OVER
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
ii=ii-1;
% disp(num2str(ii))
% The loop stop, and I will loose first hour of the file
% disp(readline(6));   

%% END OF THE HEADER -> READING DATA....
buffer = fread(fid, Inf); % Read the rest of the file
fclose(fid);


%% CAPUTRE THE AMOUNT OF WEATHER VARIABLES IN THE FILE
totalVariables = ii-13;    % 13 are the number of lines with 1 data.

formatString = ' %f';
for jj = 1:totalVariables
   formatString = [formatString ' %f']; 
end

variablesNames = strsplit(readline{ii-2});
variablesNames = variablesNames(4:3+totalVariables);
variablesNames = regexprep(variablesNames,',','');


%% WEATHER STATION INFORMATION
% Read the Weather station information --> Usually is on the line 6 of the
% header
values = strsplit(readline{6});
Station.station = char(values(length(values)));
Station.lat = str2double(char(values(4)));
Station.lon = str2double(char(values(3)));



%% SAVE THE CLEAN DATA FILE
filename = [filename(1:end-4) '_clean' '.csv'];
fid = fopen(filename, 'w');
fwrite(fid,buffer);
fclose(fid);

data = readtable(filename, 'ReadVariableNames',false, 'Format',['%f %{yyyymmdd}D' formatString]);
dateValues = data{:,2};
dataArray =  data{:,[3:3+totalVariables]};
dateIndex = datetime([datestr(dateValues,'yyyy-MM-dd ')  num2str(dataArray(:,1)-1)], 'InputFormat', 'yyyy-MM-dd HH');
weatherInfo = array2timetable(data{:,[4:3+totalVariables]},'RowTimes',dateIndex,'VariableNames',variablesNames);
weatherInfo.Properties.Description = ['KNMI (Koninklijk Nederlands Meteorologisch Instituut)'];
end
