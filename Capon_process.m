function [ power ] = Capon_process( signal, fech, step )

    x = xcorr(signal);
    N1 = length(signal);
    N2 = (length(x)+1) / 2;

    Rxx = zeros(N1);
    for i=1:N1
        Rxx(1:N1, i) = x(N2-i+1:N2-i+N1);
    end
    
    f=fix(-fech/2):step:fix(fech/2);
    N3 = length(f);

    power = zeros(1, N3);
    for i=1:N3
        af = af_builder(N1, f(i), fech);
        power(i) = real(af'*Rxx*af);
    end
end

