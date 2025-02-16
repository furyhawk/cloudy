# Use the CentOS 7 based CUDA image
FROM nvidia/cuda:11.3.1-base-centos7

# Set the working directory
WORKDIR /opt/ollama

# Update the system and install necessary packages. CentOS 7 uses yum.
# Note: The '--nogpgcheck' option can be used if you face GPG key issues, but it's better to resolve these properly.
RUN yum update -y && \
    yum install -y curl

# Download and install Ollama
RUN curl -L https://ollama.com/download/ollama-linux-amd64 -o /usr/bin/ollama && \
    chmod +x /usr/bin/ollama

ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV NVIDIA_VISIBLE_DEVICES=all
ENV OLLAMA_HOST=0.0.0.0:11434
EXPOSE 11434
# Set the entrypoint
ENTRYPOINT [ "/usr/bin/ollama" ]

# Default command
CMD ["serve"]