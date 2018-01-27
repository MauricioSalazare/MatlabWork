function [station,filenameReturn] = requestSensorDataUser()
% filename = 'ID_Names.xlsx';

prompt = ['Select sensor group: \n'...
          '1 - Salvador \n' ...
          '2 - Da Vinci \n' ...
          '3 - Laadplein Haverleij \n' ...
          '4 - Onbekend \n' ...
          'Number: '];
sensorGroup = input(prompt);
prefix = {'SALVADOR_IDs.mat','DAVINCI_IDs.mat','LAADPLEIN_IDs.mat','ONBEKEND_IDs.mat'};
prefix2 = {'SALVADOR_','DAVINCI_','LAADPLEIN_','ONBEKEND_'};

if (sensorGroup < 5) & (sensorGroup > 0)
    % prompt          - List of sensor names in string format + asking for input
    % numberOfSensors - Numerical value of the number of sensors 
    %[prompt,numberOfSensors] = displaySensorsNames(sensorGroup);
    
    sensorListGroup = load(prefix{sensorGroup});
    
    disp('================');
    disp('Select device ID:');
    
    for i=1:length(sensorListGroup.sensorList)
        disp([num2str(i) '- ' sensorListGroup.sensorList{i}])
    end
    
    sensorSelect = input('ID Number:  ');
        if (sensorSelect <= length(sensorListGroup.sensorList)) & (sensorSelect > 0)
            
            filename = [prefix2{sensorGroup} sensorListGroup.sensorList{sensorSelect} '.csv'];
            station = readtable(filename);
            filenameReturn = filename;
        else
            disp('Incorrect sensor number.');
            return
        end
  
else
    disp('Incorrect Sensor Group Number.');
    return
end

end