function [ signal ] = AR_gen( poles, duree, fech )
coeff = poly(poles);
bruit = randn(1, fech * duree);
signal = filter(1, coeff, bruit);
end