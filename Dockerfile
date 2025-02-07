# Start with the Matlab r2018b runtime container
FROM flywheel/matlab-mcr:v95

MAINTAINER Hua Wu <huawu@stanford.edu>

# Install dependencies
RUN apt-get update && apt-get install -y jq
RUN apt-get install -y libgomp1  #for Orchestra mex file??

# ADD the Matlab Stand-Alone (MSA) into the container.
COPY calc_cov /bin
COPY run_calc_cov.sh /bin

# Ensure that the executable files are executable
RUN chmod +x /bin/*

# Make directory for flywheel spec (v0)
ENV FLYWHEEL /flywheel/v0
RUN mkdir -p ${FLYWHEEL}

# Copy and configure run script and metadata code
COPY run ${FLYWHEEL}/run
RUN chmod +x ${FLYWHEEL}/run
COPY manifest.json ${FLYWHEEL}/manifest.json

# Configure entrypoint
ENTRYPOINT ["/flywheel/v0/run"]
