# This is derived from Jose 
# at https://github.com/jgomezdans/geog_docker/blob/master/Dockerfile
# and Lewis 
# at https://github.com/profLewis/geog0111-core
FROM continuumio/miniconda3:4.8.2-alpine
LABEL maintainer="Feng Yin <ucfafyi@ucl.ac.uk>"
USER root
     
     
# name of envrionment
COPY environment.yml /root/
ARG conda_env=uclgeog
RUN /opt/conda/bin/conda env create -f /root/environment.yml \
    && /opt/conda/bin/conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete
ENV PATH /opt/conda/envs/uclgeog/bin:$PATH
# install  jupyterthemes
#RUN python -m pip install jupyterthemes
#RUN python -m pip install --upgrade jupyterthemes
#RUN python -m pip install jupyter_contrib_nbextensions
RUN jupyter contrib nbextension install --user
# enable the Nbextensions
RUN jupyter nbextension enable contrib_nbextensions_help_item/main
RUN jupyter nbextension enable autosavetime/main
RUN jupyter nbextension enable codefolding/main
RUN jupyter nbextension enable code_font_size/code_font_size
RUN jupyter nbextension enable code_prettify/code_prettify
RUN jupyter nbextension enable collapsible_headings/main
RUN jupyter nbextension enable comment-uncomment/main
RUN jupyter nbextension enable equation-numbering/main
RUN jupyter nbextension enable execute_time/ExecuteTime
RUN jupyter nbextension enable gist_it/main
RUN jupyter nbextension enable hide_input/main
RUN jupyter nbextension enable spellchecker/main
RUN jupyter nbextension enable toc2/main
RUN jupyter nbextension enable toggle_all_line_numbers/main
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
        npm cache clean --force && \
        rm -rf $HOME/.node-gyp && \
        rm -rf $HOME/.local
     
COPY fix-permissions /root/
RUN chmod a+rx /root/fix-permissions && \
    /root/fix-permissions $CONDA_DIR $HOME
# Clone the git repo
RUN git clone https://github.com/profLewis/geog0111-core.git
WORKDIR $HOME/geog0111-core/notebooks
# Run jupyter notebook
RUN jupyter notebook --ip 0.0.0.0 --no-browser --allow-root
