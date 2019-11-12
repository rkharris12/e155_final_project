load pic.txt;

% convert to a value from 0 to 1
minval=min(min(pic));
maxval=max(max(pic));
s=1/(maxval-minval);
for i=1:(length(pic))
    for j=1:(length(pic))
        normPic(i,j)=(pic(i,j)-minval)*s;
    end
end   

hold on
for i=1:16
    for j=1:16
        val=normPic(i,j);
        scatter(i,17-j,1000,[val val val],'filled','s');
    end
end
hold off