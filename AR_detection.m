function [poles, ar] = AR_detection( signal, ordre )

    x = xcorr(signal);
    p = ordre;
    Rxx = zeros(p);
    
    for i=1:p
        for j=1:p
            Rxx(i,j) = x(fix((length(x))/2)+1+j-i);
        end
    end
    
    rxx_vect = x(fix((length(x)+1)/2)+1:fix((length(x)+1)/2)+p);
    Rxx
    rxx_vect
    [j, k] = size(rxx_vect)
    size(inv(Rxx))
    
    if(j == 1)
       rxx_vect = rxx_vect'; 
    end
    ar = -inv(Rxx)*rxx_vect;

    p = [1; ar];
    
    poles = roots(p);
end