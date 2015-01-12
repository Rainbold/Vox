d = 0.95;
f = 1;
signal = fcno01fz(8000*d:8000*f);

% FFT
figure(1);
subplot(1,2,1);
plot(d:1/8000:f,signal);
title('Signal temporel');
ylabel('Amplitude');
xlabel('Temps (s)');

xlim([d f]);
subplot(1,2,2);
N=512;
plot(((1:N)/N -0.5)*8000, fftshift(abs(fft(signal, N)).^2));
title('DSP du signal');
xlabel('Fréquence (Hz)');
ylabel('Amplitude');

%% AR
figure(2);
subplot(1,2,1);
plot(d:1/8000:f,signal);
title('Signal temporel');
ylabel('Amplitude');
xlabel('Temps (s)');

xlim([d f]);
subplot(1,2,2);
N=512;

[poles,ar] = AR_detection(signal, 200);
H = freqz(ar, 1,4000);
H = H';
H = [ H fliplr(H)];
plot(-4000:3999,(abs(H).^2))

xlim([-4000 4000]);
title('DSP du signal');
xlabel('Fréquence (Hz)');
ylabel('Amplitude');


%% Capon
figure(3);
subplot(1,2,1);
plot(d:1/8000:f,signal);
title('Signal temporel');
ylabel('Amplitude');
xlabel('Temps (s)');
xlim([d f]);

puissances = Capon_process(signal, 8000, 1);
N = length(puissances);
subplot(1,2,2);
plot(((0:(N-1))/N-0.5)*8000, puissances);
title('Spectre de puissance');
xlabel('Frequence (Hz)');
ylabel('Amplitude');
xlim([-4000 4000]);

%%
% FFT
figure(6);
d = 0;
f = 0.2;
fech = 500;
signal = sin(2*pi*(d:1/fech:f)*30) + 0.5*sin(2*pi*(d:1/fech:f)*200);
subplot(1,2,1);
plot(d:1/fech:f,signal);
title('Signal temporel');
ylabel('Amplitude');
xlabel('Temps (s)');
xlim([d f]);

subplot(1,2,2);
N=512;
plot(((1:N)/N -0.5)*fech, fftshift(abs(fft(signal, N)).^2));
title('DSP du signal');
xlabel('Fréquence (Hz)');
ylabel('Amplitude');

%% AR
figure(7);

fech = 1000;
d = 0.1;
signal = AR_gen([0.1*exp(1i*2*pi*100/fech) 0.1*exp(-1i*2*pi*100/fech)], d, fech);
subplot(1,2,1);
plot((1:length(signal))/length(signal) *d,signal);
title('Signal temporel');
ylabel('Amplitude');
xlabel('Temps (s)');
xlim([0 d]);

subplot(1,2,2);
N=512;



[poles,ar] = AR_detection(signal, 20);
poles
H = freqz(ar, 1,fech/2);
H = H';
H = [ H fliplr(H)];
plot(-fech/2:fech/2 -1,(abs(H).^2))

xlim([-fech/2 fech/2]);
title('DSP du signal');
xlabel('Fréquence (Hz)');
ylabel('Amplitude');
%% Capon
figure(8);
d = 0;
f = 0.2;
fech = 500;
signal = sin(2*pi*(d:1/fech:f)*30) + 0.5*sin(2*pi*(d:1/fech:f)*200);
subplot(1,2,1);
plot(d:1/fech:f,signal);
title('Signal temporel');
ylabel('Amplitude');
xlabel('Temps (s)');
xlim([d f]);

subplot(1,2,2);
N=512;
power = Capon_process(signal, fech, 1);
length(power)
plot(-250:250, power);
title('DSP du signal');
xlabel('Fréquence (Hz)');
ylabel('Amplitude');

%%
figure(10);
poles = [  0.2472 - 0.7608i; 0.2472 + 0.7608i;-0.1545 - 0.4755i;-0.1545 + 0.4755i];
subplot(1,3,1);
zplane(poles);
title('Pôles initiaux');
s = AR_gen(poles, 0.05, 8000);
subplot(1,3,2);
plot((1:length(s))/length(s)*0.05,s);
title('Signal généré');
xlabel('Temps (s)');
ylabel('Aplitude');
p = AR_detection(s, 4);
subplot(1,3,3);

zplane(p);
title('Pôles retrouvés');
