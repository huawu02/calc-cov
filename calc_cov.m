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
img = zeros(nx, ny, ns, ne, nc);
R   = zeros(nc, nc, ns, ne);

% Reconstruct range of slices and echoes
%
for sidx = 1:ns
    fprintf(1, '...Slice: %d\n', srange(sidx));
    for eidx = 1:ne
        for c = 1:nc
            % Get raw data
            %
            ksp(:,:,sidx,eidx,c) = GERecon('Pfile.KSpace', srange(sidx), erange(eidx), c, pfile);
            img(:,:,sidx,eidx,c) = GERecon('Transform', squeeze(ksp(:,:,sidx,eidx,c)));
        end
        R(:,:,sidx,eidx) = cov(reshape(img(:,:,sidx,eidx,:), [nx*ny,nc]));   
    end
end

f = figure('visible','on');
if ns*ne > 1
    montage(abs(reshape(R, [nc,nc,ns*ne]))); % montage will somehow change the image resolution automatically
else
    imagesc(abs(reshape(R, [nc,nc,ns*ne])));
end
caxis('auto');colormap(jet(256));colorbar;
saveas(f,fullfile(outpath, 'Noise_covariance.png'));
save(fullfile(outpath, 'Noise_covariance.mat'), 'R');
%close(f);

