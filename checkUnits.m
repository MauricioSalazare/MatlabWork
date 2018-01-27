function data = checkUnits(data)
    for i=1:length(data)
       if data(i) > 600
           data(i) = data(i)./1000;
       end
    end
end