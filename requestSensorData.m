function [station,filenameReturn] = requestSensorData(sensorGroup,sensorID)
% filename = 'ID_Names.xlsx';

prefix = {'SALVADOR_IDs.mat','DAVINCI_IDs.mat','LAADPLEIN_IDs.mat','ONBEKEND_IDs.mat'};
prefix2 = {'SALVADOR_','DAVINCI_','LAADPLEIN_','ONBEKEND_'};

if (sensorGroup < 5) & (sensorGroup > 0)
    % prompt          - List of sensor names in string format + asking for input
    % numberOfSensors - Numerical value of the number of sensors 
    %[prompt,numberOfSensors] = displaySensorsNames(sensorGroup);
    
    sensorListGroup = load(prefix{sensorGroup}); 
    sensorSelect = sensorID;
        if (sensorSelect <= length(sensorListGroup.sensorList)) & (sensorSelect > 0)            
            filename = [prefix2{sensorGroup} sensorListGroup.sensorList{sensorSelect} '.csv'];
            station = readtable(filename);
            filenameReturn = filename;
        else
            disp('Sensor number out of boundaries.');
            return
        end
  
else
    disp('Incorrect Sensor Group Number.');
    return
end

end