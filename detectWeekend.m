%% Function to create a time series with weekend classification

function weekendColumn = detectWeekend(dateValues)
weekendColumn = zeros(length(dateValues),1);

for i=1:length(dateValues)
    if isweekend(dateValues(i))
        weekendColumn(i) = 1;
    end    
end
