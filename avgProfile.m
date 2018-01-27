
function dayProfile = avgProfile(data,dateValues,month,year,periodSelect)
    count = 0;
    
    timeResolution = unique(diff(dateValues));
    timeResolution = minutes(timeResolution(1)); 
    
    if timeResolution == 15
        disp('Data with 15 min time resolution');
        numberOfSamples = 96;
        dataDay     = zeros(96,1);
    elseif timeResolution == 60
        disp('Data with hourly time resolution');
        numberOfSamples = 24;
        dataDay     = zeros(24,1);        
    else
        disp(['Very odd time resolution: ' num2str(timeResolution)]);
        return
    end
    
    
    for day = 1:31
        switch periodSelect 
            case 1
                if ~isweekend(datetime(year,month,day))
                    allow = true;
                else
                    allow = false;
                end
            case 2
                if isweekend(datetime(year,month,day))
                    allow = true;
                else
                    allow = false;
                end
            case 3
                    allow = true;
            otherwise
                disp('Invalid average Profile selection.');
        end        
        
        indexed = (dateValues.Day ==  day & ...
                 dateValues.Month == month & ...
                 dateValues.Year == year);
        if sum(indexed) == numberOfSamples && allow == true
            dataDay = dataDay + data(indexed);
            count = count + 1;            
        end
    end
    if count == 0
        disp('No available data in the month');
        dayProfile = [];
    else
        dayProfile = dataDay ./ count;
        disp(['Days with data: ' num2str(count)]);
    end
end
