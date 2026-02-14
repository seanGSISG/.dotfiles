# Docker Aliases
# Container management shortcuts

function d { & docker @args }                       # docker shorthand
function dc { & docker compose @args }              # docker compose
function dcu { & docker compose up -d @args }       # compose up (detached)
function dcd { & docker compose down @args }        # compose down
function dcl { & docker compose logs -f @args }     # compose logs (follow)
function dcb { & docker compose build @args }       # compose build
function dcr { & docker compose restart @args }     # compose restart
function dps { & docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' }  # formatted ps
function dpsa { & docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' }  # all containers
function dprune { & docker system prune -af --volumes }  # nuclear prune

# Docker functions
function dex {
    param([Parameter(Mandatory, Position = 0)][string]$Container, [Parameter(Position = 1)][string]$Shell = "sh")
    & docker exec -it $Container $Shell
}
function dsh {
    param([Parameter(Mandatory, Position = 0)][string]$Container)
    & docker exec -it $Container sh
}
function dbash {
    param([Parameter(Mandatory, Position = 0)][string]$Container)
    & docker exec -it $Container bash
}
function dlog {
    param([Parameter(Mandatory, Position = 0)][string]$Container)
    & docker logs -f $Container
}
