# This is derived from Jose 
# at https://github.com/jgomezdans/geog_docker/blob/master/Dockerfile
# and Lewis 
# at https://github.com/profLewis/geog0111-core
FROM continuumio/miniconda3
LABEL maintainer="Feng Yin <ucfafyi@ucl.ac.uk>"
USER root
ARG NB_USER="Jeremy"
ARG NB_UID="1000"
ARG NB_GID="100"


ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get install -yq --no-install-recommends \
    sudo \
    locales \
    fonts-liberation \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_GB.UTF-8 \
    LANG=en_GB.UTF-8 \
    LANGUAGE=en_GB.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

# Create NB_USER wtih name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd && \
    fix-permissions $HOME && \
    fix-permissions $CONDA_DIR


SHELL ["/bin/bash", "-o", "pipefail", "-c"]

#RUN bash  /usr/local/bin/fix-permissions $HOME
#RUN chmod 0755 $HOME/environment.yml

COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

USER $NB_UID
WORKDIR $HOME

COPY environment.yml $HOME
RUN /opt/conda/bin/conda env create -f $HOME/environment.yml \
    && /opt/conda/bin/conda clean -afy

#RUN echo "source activate uclgeog" > ~/.bashrc
ENV PATH /opt/conda/envs/uclgeog/bin:$PATH
#RUN echo $PATH
# enable the Nbextensions
RUN jupyter contrib nbextension install --user \
    && jupyter nbextension enable contrib_nbextensions_help_item/main \
    && jupyter nbextension enable autosavetime/main \
    && jupyter nbextension enable codefolding/main \
    && jupyter nbextension enable code_font_size/code_font_size \ 
    && jupyter nbextension enable code_prettify/code_prettify \
    && jupyter nbextension enable collapsible_headings/main \
    && jupyter nbextension enable comment-uncomment/main \
    && jupyter nbextension enable equation-numbering/main \
    && jupyter nbextension enable execute_time/ExecuteTime \
    && jupyter nbextension enable gist_it/main \
    && jupyter nbextension enable hide_input/main \
    && jupyter nbextension enable spellchecker/main \
    && jupyter nbextension enable toc2/main \
    && jupyter nbextension enable toggle_all_line_numbers/main
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV JUPYTER_ENABLE_LAB=yes
RUN jupyter labextension install nbdime-jupyterlab --no-build && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build && \
    jupyter labextension install jupyter-matplotlib --no-build && \
    jupyter labextension install @jupyterlab/debugger --no-build && \
    jupyter labextension install jupyter-leaflet --no-build && \
    jupyter lab build && \
        jupyter lab clean && \
        jlpm cache clean && \
        npm cache clean --force

USER root
RUN find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete\
    && rm -rf /root/.node-gyp\
    && rm -rf /root/.local

USER $NB_UID
WORKDIR $HOME   
# Clone the git repo
RUN git clone https://github.com/profLewis/geog0111-core.git
WORKDIR $HOME/geog0111-core/notebooks
# Run jupyter notebook
#RUN jupyter notebook --ip 0.0.0.0 --no-browser --allow-root
RUN jupyter trust *ipynb 
