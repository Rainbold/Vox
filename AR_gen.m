function [ signal ] = AR_gen( AR, duree, fech )
bruit = randn(1, fech * duree);
signal = filter(1, AR, bruit);
end