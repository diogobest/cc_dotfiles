#!/bin/sh

if [ ! -d "$HOME/.cc_dotfiles" ]
then
  echo "Installing Campus Code Dotfiles"
  echo "We'll install:"
  echo "  - tmux"
  echo "  - fzf"
  echo "  - zsh"
  echo "  - rvm"
  echo "  - nodejs"
  echo "  - bat"

  case "$(uname -s)" in
    Linux)
      echo "  - vim (vim-gnome)"
      NODE_VERSION=12

      sudo apt-get update
      sudo apt-get install -y software-properties-common gnupg2 curl
      gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
      curl -sSL https://get.rvm.io | bash -s stable --ruby
      curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
      curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
      curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.2.1
      echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

      sudo apt-get install -y fzf \
        fd-find \
        playerctl \
        git \
        xclip \
        build-essential \
        zsh \
        dconf-cli \
        vim-gtk3 \
	neovim \
        nodejs \
        yarn \
        ruby \
        libevent-dev \
        ncurses-dev \
        bison \
        pkg-config \
        bat
      ;;
    Darwin )
      echo "  - vim (macvim)"
      echo "  - google-chrome (mac)"
      echo "  - iterm2 (mac)"
      echo "  - atom (mac)"
      gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
      curl -sSL https://get.rvm.io | bash -s stable --ruby
      sudo usermod -a -G rvm `whoami`
      ;;
    *)
      echo 'Operational system not recognized, aborting installation'
      return
      ;;
  esac
  git clone --depth=10 https://github.com/diogobest/cc_dotfiles.git "$HOME/.config/nvim"
  cd "$HOME/.cc_dotfiles"
  rake install
else
  echo "You already have Campus Code Dotfiles installed."
fi
