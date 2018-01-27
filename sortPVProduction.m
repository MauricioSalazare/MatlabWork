

prefix = {'SALVADOR_','DAVINCI_','LAADPLEIN_','ONBEKEND_'};
BoxSelection = 2;
fileName = [prefix{BoxSelection} 'TimeSeries_Profiles_Corr.mat'];
load(fileName)

numberOfBoxes = length(structSeries);

for ii=1:numberOfBoxes
   stationName{ii} = cell2mat(structSeries(ii).StationName);
   disp(['Reading DALI-Box: ' stationName(ii)]);
   corrValue(ii) = structSeries(ii).corrSunlight.R(2,1);  
   meanValue(ii) = mean(structSeries(ii).timeTable15min.SumPhases);
   maxValue(ii)  = max(structSeries(ii).timeTable15min.SumPhases);
   
end

mergedTable = table(stationName',meanValue',maxValue',corrValue',(corrValue./meanValue)');
sortrows(mergedTable,4,'ascend')