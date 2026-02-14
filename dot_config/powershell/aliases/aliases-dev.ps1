# Development Aliases
# Language-specific development shortcuts

# Python
function py { & python @args }                      # python shorthand
function pip { & pip3 @args }                       # pip3 shorthand
function venv { & python -m venv .venv }            # create virtualenv
function va { & .\.venv\Scripts\Activate.ps1 }      # activate virtualenv
function vd { & deactivate }                        # deactivate virtualenv
function pipr { & pip install -r requirements.txt } # install requirements
function uvs { & uv sync @args }                    # uv sync
function uvr { & uv run @args }                     # uv run
function uvp { & uv pip @args }                     # uv pip

# Testing
function pt { & pytest @args }                      # pytest
function ptv { & pytest -v @args }                  # pytest verbose
function ptc { & pytest --cov @args }               # pytest with coverage
function ptvv { & pytest -vv @args }                # pytest very verbose

# Code quality
function ruffc { & ruff check . @args }             # ruff check
function rufff { & ruff format . @args }            # ruff format

# Node/NPM
function ni { & npm install @args }                 # npm install
function nid { & npm install --save-dev @args }     # npm install dev
function nr { & npm run @args }                     # npm run
function nrs { & npm run start }                    # npm start
function nrd { & npm run dev }                      # npm dev
function nrb { & npm run build }                    # npm build
function nrt { & npm run test }                     # npm test
function br { & bun run @args }                     # bun run
function bi { & bun install @args }                 # bun install
