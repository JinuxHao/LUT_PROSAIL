% %*************************************************************************
% %*                                                                       *
% 	main_PROSAIL
% 
% 09 01 2011
% This program allows modeling reflectance data from canopy
% - modeling leaf optical properties with PROSPECT-5 (feret et al. 2008)
% - modeling leaf inclination distribution function with the subroutine campbell
% (Ellipsoidal distribution function caracterised by the average leaf 
% inclination angle in degree), or dladgen (2 parameters LIDF)
% - modeling canopy reflectance with 4SAIL (Verhoef et al., 2007)

% This version has been implemented by Jean-Baptiste Feret
% Jean-Baptiste Feret takes the entire responsibility for this version 
% All comments, changes or questions should be sent to:
% jbferet@stanford.edu

% References:
% 	Verhoef et al. (2007) Unified Optical-Thermal Four-Stream Radiative
% 	Transfer Theory for Homogeneous Vegetation Canopies, IEEE TRANSACTIONS 
% 	ON GEOSCIENCE AND REMOTE SENSING, VOL. 45, NO. 6, JUNE 2007
% 	F閞et et al. (2008), PROSPECT-4 and 5: Advances in the Leaf Optical
% 	Properties Model Separating Photosynthetic Pigments, REMOTE SENSING OF 
% 	ENVIRONMENT
% The specific absorption coefficient corresponding to brown pigment is
% provided by Frederic Baret (EMMAH, INRA Avignon, baret@avignon.inra.fr)
% and used with his autorization.
% the model PRO4SAIL is based on a version provided by
%	Wout Verhoef
%	NLR	
%	April/May 2003

% The original 2-parameter LIDF model is developed by and described in:
% 	W. Verhoef, 1998, "Theory of radiative transfer models applied in 
%	optical remote sensing of vegetation canopies", Wageningen Agricultural
%	University,	The Netherlands, 310 pp. (Ph. D. thesis)
% the Ellipsoidal LIDF is taken from:
%   Campbell (1990), Derivtion of an angle density function for canopies 
%   with ellipsoidal leaf angle distribution, Agricultural and Forest 
%   Meteorology, 49 173-176
%*                                                                       *
%*************************************************************************
clc

TypeLidf=1;
% if 2-parameters LIDF: TypeLidf=1
if (TypeLidf==1)
    % LIDFa LIDF parameter a, which controls the average leaf slope
    % LIDFb LIDF parameter b, which controls the distribution's bimodality
    %	LIDF type 		a 		 b
    %	Planophile 		1		 0
    %	Erectophile    -1	 	 0
    %	Plagiophile 	0		-1
    %	Extremophile 	0		 1
    %	Spherical 	   -0.35 	-0.15
    %	Uniform 0 0
    % 	requirement: |LIDFa| + |LIDFb| < 1	
    LIDFa	=	-0.35;
    LIDFb	=	-0.15;
% if ellipsoidal LIDF: TypeLidf=2
elseif (TypeLidf==2)
    % 	LIDFa	= average leaf angle (degrees) 0 = planophile	/	90 = erectophile
    % 	LIDFb = 0
    LIDFa	=	30;
    LIDFb	=	0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LEAF CHEM & STR PROPERTIES	%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Cab		=	40;		% chlorophyll content (礸.cm-2) 
Car		=	8;		% carotenoid content (礸.cm-2)
Cbrown	=	0.0;	% brown pigment content (arbitrary units)
Cw		=	0.01;	% EWT (cm)
Cm		=	0.009;	% LMA (g.cm-2)
N		=	1.5;	% structure coefficient

data=dataSpec_P5B;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Soil Reflectance Properties	%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% rsoil1 = dry soil
% rsoil2 = wet soil
Rsoil1=data(:,10);Rsoil2=data(:,11);
psoil	=	1;		% soil factor (psoil=0: wet soil / psoil=1: dry soil)
rsoil0=psoil*Rsoil1+(1-psoil)*Rsoil2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%	4SAIL canopy structure parm	%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	LAI		=	3.;     	% leaf area index (m^2/m^2)
	hspot	=	0.01;       % hot spot
	tts		=	30.;		% solar zenith angle (�)
	tto		=	10.;		% observer zenith angle (�)
	psi		=	0.;         % azimuth (�)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%          CALL PRO4SAIL       %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% rdot: hemispherical-directional reflectance factor in viewing direction    
% rsot: bi-directional reflectance factor
% rsdt: directional-hemispherical reflectance factor for solar incident flux
% rddt: bi-hemispherical reflectance factor

%[rdot,rsot,rddt,rsdt]=PRO4SAIL(N,Cab,Car,Cbrown,Cw,Cm,LIDFa,LIDFb,TypeLidf,LAI,hspot,tts,tto,psi,rsoil0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	direct / diffuse light	%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the direct and diffuse light are taken into account as proposed by:
% Francois et al. (2002) Conversion of 400�1100 nm vegetation albedo 
% measurements into total shortwave broadband albedo using a canopy 
% radiative transfer model, Agronomie
% Es = direct
% Ed = diffuse
Es=data(:,8);
Ed=data(:,9);
rd=pi/180;
skyl	=	0.847- 1.61*sin((90-tts)*rd)+ 1.04*sin((90-tts)*rd)*sin((90-tts)*rd); % % diffuse radiation
PARdiro	=	(1-skyl)*Es;
PARdifo	=	(skyl)*Ed;

% 选取代表波段（波长 nm）
wl_blue  = 492;   % Sentinel-2 B2   
wl_green = 560;   % Sentinel-2 B3  
wl_red   = 665;   % Sentinel-2 B4   
wl_nir   = 842;   % Sentinel-2 B8A  
wl_swir1 = 1614;  % Sentinel-2 B11  
wl_swir2 = 2202;  % Sentinel-2 B12 

% 用 find 定位行索引（等价于 波长-400+1，但更稳健）
idx_blue  = find(data(:,1) == wl_blue , 1);
idx_green = find(data(:,1) == wl_green, 1);
idx_red   = find(data(:,1) == wl_red  , 1);
idx_nir   = find(data(:,1) == wl_nir  , 1);
idx_swir1 = find(data(:,1) == wl_swir1, 1);
idx_swir2 = find(data(:,1) == wl_swir2, 1);

waves_idx=[idx_blue,idx_green,idx_red,idx_nir,idx_swir1,idx_swir2];

%循环赋值前准备输出文件命令
heads = {'LAI','B1_blue','B2_green','B3_red','B4_NIR','B5_SWIR1','B6_SWIR2'};

fid = fopen("../Output.csv","w");
fprintf(fid, '%s,', heads{1:end-1});%end前每个输出后加逗号
fprintf(fid, '%s\n', heads{end});%最后一个输出后加换行符


% resv : directional reflectance
% 此处可以选择某一个或几个指标进行特定步长反射率计算
for LAI=1:(8-1)/150:8
    [rdot,rsot,rddt,rsdt]=PRO4SAIL(N,Cab,Car,Cbrown,Cw,Cm,LIDFa,LIDFb,TypeLidf,...
                                   LAI,hspot,tts,tto,psi,rsoil0);

    resv	= (rdot.*PARdifo+rsot.*PARdiro)./(PARdiro+PARdifo);
    %获得所需波段索引
    resv = resv(waves_idx);
    fprintf(fid,"%f,",LAI); %输出LAI值
    fprintf(fid,"%f,",resv(1:end-1));
    fprintf(fid,"%f\n",resv(end));


end

%关闭文件输出
fclose(fid);
