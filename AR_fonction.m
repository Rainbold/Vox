function [ coeff_ai, po_obtenus ] = AR_fonction( signal, p)
% reconstitution matrice de corrélation
c = xcorr(signal);% calcul auto corrélation
N = (length(c)+1)/2;
for i=1:p
    for j=1:(p-1)
        %calcul des coeff de chaque diagonale
        matrice_correlation(1:p,i)=c(N-i+1:N-i+p);
    end
end
%matrice_correlation
% reconstitution du vecteur contenant rxx(1) ... rxx(p)
vecteur_correlation = zeros(p,1);
vecteur_correlation(1:p,1) = c(N+1:N+p);
matrice_correlation
vecteur_correlation
% reconstition des ai
coeff_ai = -inv(matrice_correlation)*vecteur_correlation;
po_obtenu = [1;coeff_ai];% rajoute 1 pour degré 0
po_obtenus = roots(po_obtenu);
end

