if status is-interactive
    # Starship custom prompt
    command -v starship &>/dev/null && starship init fish | source

    # Mise
    mise activate fish | source

    # Direnv + Zoxide
    command -v direnv &>/dev/null && direnv hook fish | source
    command -v zoxide &>/dev/null && zoxide init fish | source

    # Better ls
    command -v eza &>/dev/null && alias ls='eza --icons --group-directories-first -1'

    # git Abbrs
    abbr lg lazygit
    abbr lzd lazydocker
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

    # Arch Abbrs
    abbr s pacseek
    abbr i 'paru -S'
    abbr u 'paru -Rns'
    abbr q 'paru -Qs'
    abbr qi 'paru -Qi'

    abbr ff fastfetch
    abbr of onefetch
    abbr fame git-fame

    # ls Abbrs
    abbr l ls
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    # Custom colours (skip inside tmux to preserve background transparency)
    if not set -q TMUX
        cat ~/.local/state/caelestia/sequences.txt 2>/dev/null
    end

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    # Custom fish config
    set -q XDG_CONFIG_HOME && set -l cConf $XDG_CONFIG_HOME/caelestia || set -l cConf $HOME/.config/caelestia
    source $cConf/user-config.fish 2>/dev/null
end

# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<
