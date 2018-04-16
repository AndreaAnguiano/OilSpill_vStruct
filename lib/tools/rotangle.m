function [Ur, Vr] = rotangle(U,V)

% Componentes de viento - matriz
% U
% V
% d_angle = matriz de angulo de desviación propuesto
%           por Samuels (1982) en grados
% W = intensidad del viento
% nu= viscosidad cinematica
% g= gravedad
%              d_angle=25*exp(-10⁻8* W^3/nu*g)

mu=1.307*10^-6;  
g=9.81;
W=sqrt(U.^2+V.^2); %intensidad del viento a 10 en superficie
%c=mu*g
%d_angle=25*exp(-(10^-8).*(W.^3/(mu*g)));
d_angle=34-7.5*(W).^(1/2);
angled=d_angle*(2*pi)/360;

% Formación de los vectores complejos de U, V
Z=complex(U,V);

% Calculo del angulo del los vectores complejos en grados
ang=angle(Z);

% Magnitud de las corrientes en el golfo
r = abs(Z);
%r=sqrt(U.^2+V.^2);

% Rotamos los las corrientes del golfo con la expresion de euler para
% numeros complejos
complex_vectors=r.*exp(i*(ang-angled));

% Componentes de los vectores rotados
Ur=real(complex_vectors);
Vr=imag(complex_vectors);

clear angled
clear Z
clear ang
clear r
clear complex_vectors

clear mu
clear g
clear W


