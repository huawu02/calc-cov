function R = calc_cov(pfname, srange, erange)

% Calculate the noise covariance matrix of specified slices/echoes using data
% from a noise scan.

outpath = fileparts(pfname);

pfile = GERecon('Pfile.Load', pfname);
if ~exist('srange','var')
    srange = ceil(pfile.slices/2);
end
if ~exist('erange','var')
    erange = ceil(pfile.echoes/2);
end
nx = pfile.xRes;
ny = pfile.yRes;
ns = length(srange);
ne = length(erange);
nc = pfile.channels;

ksp = zeros(nx, ny, ns, ne, nc);
R   = zeros(nc, nc, ns, ne);
cor = zeros(nc, nc, ns, ne);

% Reconstruct range of slices and echoes
%
for sidx = 1:ns
    fprintf(1, '...Slice: %d\n', srange(sidx));
    for eidx = 1:ne
        for c = 1:nc
            % Get raw data
            %
            ksp(:,:,sidx,eidx,c) = GERecon('Pfile.KSpace', srange(sidx), erange(eidx), c, pfile);
        end
        R(:,:,sidx,eidx) = cov(reshape(ksp(:,:,sidx,eidx,:), [nx*ny,nc]));   
        k_std = std(reshape(ksp(:,:,sidx,eidx,:), [], nc));
        for i = 1:nc
            for j = 1:nc
                cor(i,j,sidx,eidx) = R(i,j,sidx,eidx)/k_std(i)/k_std(j);
            end
        end
        R(:,:,sidx,eidx) = R(:,:,sidx,eidx) / sum(diag(abs(R(:,:,sidx,eidx)))) * nc;  % normalize to an average of 1 in each channel
        tmp = cor(:,:,sidx,eidx);
        meancor(sidx,eidx) = mean(abs(tmp(find(triu(tmp,1)))));
    end
end

f1 = figure('visible','off');
if ns*ne > 1
    montage(abs(reshape(R, [nc,nc,ns*ne]))); % montage will somehow change the image resolution automatically
else
    imagesc(abs(R));
end
title('Noise covariance normalized to the number of channels');
caxis('auto');colormap(jet(256));colorbar;
saveas(f1,fullfile(outpath, 'Noise_covariance.png'));
save(fullfile(outpath, 'Noise_covariance.mat'), 'R');

f2 = figure('visible','off');
if ns*ne > 1
    montage(abs(reshape(cor, [nc,nc,ns*ne]))); % montage will somehow change the image resolution automatically
else
    imagesc(abs(cor)); 
end
title(sprintf('Noise correlation, mean correlation %.4f', mean(meancor,'all')));
caxis('auto');colormap(jet(256));colorbar;
saveas(f2,fullfile(outpath, 'Noise_correlation.png'));
save(fullfile(outpath, 'Noise_correlation.mat'), 'cor');

f3 = figure('visible','off');
for sidx = 1:ns
    for eidx = 1:ne
        plot(sort(abs(diag(R(:,:,sidx,eidx))),'descend'));
    end
end
title('Noise covariance matrix diagonal elements in descending order');
saveas(f3,fullfile(outpath, 'Noise_covariance_diagonal.png'));

close all;

