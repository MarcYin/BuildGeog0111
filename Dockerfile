# This is derived from Jose 
# at https://github.com/jgomezdans/geog_docker/blob/master/Dockerfile
# and Lewis 
# at https://github.com/profLewis/geog0111-core
FROM continuumio/miniconda3:4.8.2-alpine
LABEL maintainer="Feng Yin <ucfafyi@ucl.ac.uk>"
USER root

# add time
RUN apk add tzdata \
    && ls /usr/share/zoneinfo/Europe/London \
    && cp /usr/share/zoneinfo/Europe/London /etc/localtime \
    && echo "Europe/London" >  /etc/timezone \
    && date \
    && apk del tzdata

ARG NB_USER="Jeremy"
ARG NB_UID="1000"
ARG NB_GID="100"


ENV SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# name of envrionment
RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories &&\
    apk --update add bash &&\
    echo "### Cleanup unneeded files" && \
    rm -rf /usr/include/c++/*/java && \
    rm -rf /usr/include/c++/*/javax && \
    rm -rf /usr/include/c++/*/gnu/awt && \
    rm -rf /usr/include/c++/*/gnu/classpath && \
    rm -rf /usr/include/c++/*/gnu/gcj && \
    rm -rf /usr/include/c++/*/gnu/java && \
    rm -rf /usr/include/c++/*/gnu/javax

#RUN bash  /usr/local/bin/fix-permissions $HOME
#RUN chmod 0755 $HOME/environment.yml


COPY environment.yml /root/
RUN /opt/conda/bin/conda env create -f /root/environment.yml \
    && /opt/conda/bin/conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete

ENV PATH /opt/conda/envs/uclgeog/bin:$PATH
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
        rm -rf /root/.node-gyp && \
        rm -rf /root/.local

COPY fix-permissions /usr/local/bin/fix-permissions

RUN /usr/sbin/adduser \
    --disabled-password \
    --gecos "" \
    --shell /bin/bash \
    --home "/home/$NB_USER" \
    --uid "$NB_UID" "$NB_USER" \
    && chown $NB_USER:$NB_GID  /opt/conda \
    && bash  /usr/local/bin/fix-permissions $HOME \
    && bash  /usr/local/bin/fix-permissions $CONDA_DIR

USER $NB_UID
WORKDIR $HOME   
# Clone the git repo
RUN git clone https://github.com/profLewis/geog0111-core.git
WORKDIR $HOME/geog0111-core/notebooks
RUN /usr/local/bin/fix-permissions $HOME\
    && bash  /usr/local/bin/fix-permissions $CONDA_DIR
# Run jupyter notebook
#RUN jupyter notebook --ip 0.0.0.0 --no-browser --allow-root
RUN jupyter trust *ipynb 
