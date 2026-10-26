function freq=dladgen(a,b)

for i1=1:8
    t=i1*10;
    freq(i1)=dcum(a,b,t);
end
for i2=9:12
    t=80.+(i2-8)*2.;
    freq(i2)=dcum(a,b,t);
end

freq(13)=1;
for i=13:-1:2
    freq(i)=freq(i)-freq(i-1);
end
