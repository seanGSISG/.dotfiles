# Git Aliases
# Version control shortcuts

function g { & git @args }                          # git shorthand
function gs { & git status @args }                  # git status
function ga { & git add @args }                     # git add
function gaa { & git add --all @args }              # git add all
function gc { & git commit @args }                  # git commit
function gcm { & git commit -m @args }              # git commit with message
function gp { & git push @args }                    # git push
function gpl { & git pull @args }                   # git pull
function gco { & git checkout @args }               # git checkout
function gcb { & git checkout -b @args }            # git checkout new branch
function gb { & git branch @args }                  # git branch
function gba { & git branch -a @args }              # git branch all
function glog { & git log --oneline -15 @args }     # short log (15 lines)
function glg { & git log --graph --oneline --decorate -15 @args }  # graph log
function gd { & git diff @args }                    # git diff
function gds { & git diff --staged @args }          # git diff staged
function gst { & git stash @args }                  # git stash
function gstp { & git stash pop @args }             # git stash pop
function gundo { & git reset HEAD~1 --soft }        # undo last commit (keep changes)
function gwip { & git add -A; & git commit -m "WIP" }  # quick WIP commit
function gca { & git commit --amend @args }         # amend last commit
function gcane { & git commit --amend --no-edit }   # amend without editing message

# Modern git (switch/restore replace checkout for clarity)
function gsw { & git switch @args }                 # git switch branch
function gswc { & git switch -c @args }             # git switch create new branch
function grs { & git restore @args }                # git restore file
function grss { & git restore --staged @args }      # git unstage file
function gcp { & git cherry-pick @args }            # git cherry-pick
function grb { & git rebase @args }                 # git rebase
function grbc { & git rebase --continue }           # git rebase continue
function grba { & git rebase --abort }              # git rebase abort

# TUI
function lg { & lazygit @args }                     # lazygit TUI
