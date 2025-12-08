#!/bin/bash
set -euo pipefail

sudo apt update
sudo apt install -y build-essential libssl-dev libreadline-dev zlib1g-dev git

# Install rbenv if not present
if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
else
  echo "rbenv exists"
fi

# Shell integration
grep -qxF 'export PATH="$HOME/.rbenv/bin:$PATH"' ~/.zshrc || echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
grep -qxF 'eval "$(rbenv init -)"' ~/.zshrc || echo 'eval "$(rbenv init -)"' >> ~/.zshrc

# ruby-build plugin
if [ ! -d "$HOME/.rbenv/plugins/ruby-build" ]; then
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

echo "rbenv installed. Install Ruby with: rbenv install <version> && rbenv global <version>"
