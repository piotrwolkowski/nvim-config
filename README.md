# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Requirements

- Neovim >= 0.9.0
- NerdFont - Needs to be installed in the system and if this is run through WSL, needs to be added to the WSL terminal (in WSL settings)
- lua-language-server
- For python - language server, `python3`, `pip3`, `debugpy`, `pyright`
- `ripgrep`
- `fd`
- `npm`

Script to install dependencies:

```
sudo apt update
sudo apt install -y neovim git curl unzip ripgrep fd-find gcc make

curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

sudo apt install -y python3 python3-pip
pip3 install debugpy

sudo npm install -g pyright lua-language-server

# clipboard
sudo apt install -y xclip
```

## Key Bindings

<F11> is mapped to step in when debugging. Some of the terminal will have that mapped to full screen. To avoid the collision remap <F11> in the terminal to a different key binding.

<Ctrl-v> for visual block selection can be captured by terminal as paste - in this confit the visual blcok is <Ctrl-q>.
