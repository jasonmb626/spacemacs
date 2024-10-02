###############################     Base    #################################################
FROM opensuse/tumbleweed:latest AS base

ARG UID=1000
ARG GID=1000
ARG AUPK="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIECZKhE/oPWLgBXE44YSUD4hSG3n4TVfg4CuMrDDRTht docker"

#These (esp the LANG variable) make sure tmux outputs UTF-8. Needed for special chars
ENV GDM_LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV ZDOTDIR=/home/app/.config/zsh/
ENV XDG_CACHE_HOME=/home/app/.local/cache
ENV ZETTEL_BASE=/home/app/Documents/zettelkasten
ENV TEMPLATE_BASE=/home/app/.emacs.d/templates

WORKDIR /app
RUN zypper -n install python3-pip npm zsh \
    && sed -i 's,root:x:0:0:root:/root:/bin/bash,root:x:0:0:root:/root:/bin/zsh,g' /etc/passwd

RUN if [[ $UID -ne 0 ]]; then \
        groupadd -g ${GID} app \
        && useradd -u ${UID} -g 1000 -s /bin/zsh app \
        && chmod 777 /tmp \
        && mkdir -p /app/node_modules\
        && chown -R app:app /app \
        && touch /run/sshd.pid && chmod 777 /run/sshd.pid \
        && echo "app:*" | chpasswd -e; \
    fi

USER app:app
RUN python3 -m venv /home/app/.venvs/app

COPY requirements.txt /tmp
RUN source /home/app/.venvs/app/bin/activate\
    && pip3 install -r /tmp/requirements.txt && rm /tmp/requirements.txt \
    && cat <<EOF >/tmp/zshrc_preamble
    SSHD_PID=\$(ps aux | grep sshd | grep -v grep | awk '{print \$2}')
   if [[ "\$SSHD_PID" == "" ]]; then
      exec sudo /usr/sbin/sshd -D -e "\$@" &
    fi
    source /home/app/.venvs/app/bin/activate
    /home/app/.config/nvim/bin/do_my_lazyvim_tweaks.sh 2>/dev/null
    if [[ -d /app/node_modules ]]; then
        size_of=\$(du /app/node_modules | tail -n 1 | awk {'print \$1'})
        if [[ \$size_of -eq 0 ]]; then
            echo -e "\\n\\tNode modules folder is empty. If this is a node project you may need to run 'npm i'\\n"
        fi
    fi
EOF

###############################     Prod    #################################################
FROM base AS prod

COPY app/. .
RUN if [[ -s package.json ]]; then\
        npm install;\
    fi

CMD ["node", "app.js"]

#############################   Development   ################################################
FROM base AS dev

USER root:root

RUN zypper -n install\
        dos2unix\
        git\
        lazygit\
        openssh\
        tmux neovim emacs\
        ripgrep\
        tree-sitter\
        sudo\
        fd\
        mercurial\
        wget\
    && npm install -g neovim\
    && mkdir -p /etc/sudoers.d && echo 'app ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/app \
    && mkdir -p /home/app/.config/tmux \
    && chown -R app:app /home/app/.config\
    && mkdir -p /home/app/.local \
    && chown -R app:app /home/app/.local \
    && mkdir -p /home/app/.ssh && chown -R app:app /home/app/.ssh \
    && mkdir -p /home/app/Documents/zettelkasten && chown -R app:app /home/app/Documents/zettelkasten \
    && echo 'HostKey /home/app/.ssh/id_ed25519' > /etc/ssh/sshd_config \
    && echo "$AUPK" >/home/app/.ssh/authorized_keys \
    && chown app:app /home/app/.ssh/authorized_keys && chmod 600 /home/app/.ssh/authorized_keys

USER app:app
COPY requirements-dev.txt /tmp
RUN source /home/app/.venvs/app/bin/activate\
    && pip3 install --upgrade pip \
    && pip3 install -r /tmp/requirements-dev.txt && rm /tmp/requirements-dev.txt\
    && pip3 install pynvim pylint\
    && mkdir -p /home/app/.config/tmux/plugins && chown app:app /home/app/.config/tmux/plugins/ \
    && git config --global http.version HTTP/1.1 \
    && git clone https://github.com/tmux-plugins/tpm /home/app/.config/tmux/plugins/tpm \
    && git clone https://github.com/jasonmb626/my-lazyvim-starter.git /home/app/.config/nvim \
    && git clone https://github.com/jasonmb626/dotfiles-dev.git /tmp/dotfiles-dev \
    && mv /tmp/dotfiles-dev/tmux/tmux.conf /home/app/.config/tmux/tmux.conf \
    && mv /tmp/dotfiles-dev/zsh /home/app/.config/ && rm -fr /tmp/dotfiles-dev \
    && /bin/zsh -c "source /home/app/.config/zsh/.zshrc" \
    && mv /home/app/.config/zsh/.zshrc /tmp/.zshrc \
    && cat /tmp/zshrc_preamble /tmp/.zshrc > /home/app/.config/zsh/.zshrc \
    && rm /tmp/zshrc_preamble /tmp/.zshrc \
    && dos2unix /home/app/.config/zsh/.zshrc \  
    && ssh-keygen -t ed25519 -f /home/app/.ssh/id_ed25519 -q -N "" -C dockercnt

RUN git clone https://github.com/jasonmb626/spacemacs.git ~/.emacs.d \
    && mkdir -p ~/.emacs.d/elpa && mkdir -p ~/.emacs.d/quelpa && mkdir -p ~/.emacs.d/.cache \
    && touch ~/.emacs.d/recentf\
    && ln -s /home/app/.emacs.d/.spacemacs /home/app/.spacemacs

CMD ["tmux"]
