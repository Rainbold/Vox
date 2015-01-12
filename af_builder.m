function [ af ] = af_builder ( N, f, fech )

    af = zeros(N,1);

    for i = 1:N
        af(i,1) = exp(-1i*2*pi*(i-1)*f/fech);
    end
end

