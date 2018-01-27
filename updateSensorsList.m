function updateSensorsList(filename)
filename = 'ID_Names.xlsx';

prefix = {'SALVADOR','DAVINCI','LAADPLEIN','ONBEKEND'};
disp('Updating sensor list........')
for i=1:2
   sensorGroup = i;
   [num,txt,raw] = xlsread(filename,sensorGroup,'D:D'); 
   txt = rmmissing(txt);
   num = rmmissing(num);

   for k=1:(length(txt)+length(num))
        if ~ischar(raw{k}) & ~ismissing(raw{k})
            raw{k} = num2str(raw{k});
        end

   end
   sensorList = raw(2:(length(txt)+length(num)));
   save([prefix{i} '_IDs.mat'],'sensorList');
   disp([prefix{i} '... OK']);
end


end
