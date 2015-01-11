function [ output_args ] = AR_detection( signal )

    x = xcorr(signal, length(signal))
    x(fix(length(x)/2)+1)
    
    p = 3;
    Rxx = zeros(p);
    
    for i=1:p
        for j=1:p
            Rxx(i,j) = x(fix(length(x)/2)+1+j-i);
        end
    end
    
    rxx_inv = inv(Rxx)
    rxx_vect = fliplr(x(fix(length(x)/2)+1:fix(length(x)/2)+p))';
   
    rxx_inv*rxx_vect
    
end