# Development Aliases
# Language-specific development shortcuts

# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv .venv'
alias va='source .venv/bin/activate'
alias vd='deactivate'
alias pipr='pip install -r requirements.txt'
alias uvs='uv sync'
alias uvr='uv run'
alias uvp='uv pip'

# Testing
alias pt='pytest'
alias ptv='pytest -v'
alias ptc='pytest --cov'
alias ptvv='pytest -vv'

# Code quality
alias ruffc='ruff check .'
alias rufff='ruff format .'

# Node/NPM
alias ni='npm install'
alias nid='npm install --save-dev'
alias nr='npm run'
alias nrs='npm run start'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrt='npm run test'
alias br='bun run'
alias bi='bun install'
