#!/bin/bash

# Cores para melhorar a visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Variáveis para métricas
TOTAL_DOWNLOADED=0
TOTAL_REMOVED=0
ERRORS_COUNT=0
UPDATE_LOG="$HOME/.system-update.log"  # Mudado para o diretório home do usuário

# Funções de exibição
status_msg() {
    local msg="$1"
    printf "\n${BLUE}== [ %s ] ${NC}%s\n" "$(date +'%H:%M:%S')" "$msg"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] STATUS: $msg" >> "$UPDATE_LOG"
}

success_msg() {
    printf "${GREEN}✔ %s${NC}\n" "$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$UPDATE_LOG"
}

error_msg() {
    printf "${RED}✖ %s${NC}\n" "$1" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$UPDATE_LOG"
    ((ERRORS_COUNT++))
}

warning_msg() {
    printf "${YELLOW}⚠ %s${NC}\n" "$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$UPDATE_LOG"
}

info_msg() {
    printf "${CYAN}➤ %s${NC}\n" "$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$UPDATE_LOG"
}

metric_msg() {
    printf "${MAGENTA}📊 %s${NC}\n" "$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] METRIC: $1" >> "$UPDATE_LOG"
}

human_size() {
    echo "$1" | numfmt --to=iec --suffix=B --padding=7
}

safe_dir_size() {
    sudo du -s "$1" 2>/dev/null | cut -f1 || echo 0
}

check_internet() {
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        error_msg "Sem conexão com a internet. Verifique sua conexão e tente novamente."
        exit 1
    fi
}

check_disk_space() {
    local available_space=$(df / --output=avail | tail -1)
    if [ "$available_space" -lt 1048576 ]; then  # Menos que 1GB
        error_msg "Espaço em disco insuficiente (menos de 1GB disponível)"
        exit 1
    fi
}

check_package_manager() {
    for manager in "flatpak" "snap"; do
        if command -v "$manager" &> /dev/null; then
            success_msg "$manager está instalado"
        else
            warning_msg "$manager não está instalado. Pulando atualizações de $manager."
        fi
    done
}

try_step() {
    local STEP_DESC=$1
    local MAX_RETRIES=${2:-1}
    local RETRY_DELAY=${3:-5}
    shift 3

    status_msg "${STEP_DESC}..."
    
    for ((i=1; i<=$MAX_RETRIES; i++)); do
        if sudo timeout 300 "$@"; then  # Timeout de 5 minutos
            success_msg "${STEP_DESC} concluído com sucesso!"
            return 0
        else
            error_msg "Falha na tentativa $i/${MAX_RETRIES}: ${STEP_DESC}"
            if [ $i -lt $MAX_RETRIES ]; then
                info_msg "Aguardando ${RETRY_DELAY} segundos antes de tentar novamente..."
                sleep $RETRY_DELAY
            fi
        fi
    done
    
    error_msg "Falha crítica após ${MAX_RETRIES} tentativas: ${STEP_DESC}"
    return 1
}

update_snap_packages() {
    if ! command -v snap &> /dev/null; then
        return 0
    fi

    local SNAP_DIR="/var/lib/snapd/snaps"
    local SNAP_BEFORE_SIZE=$(safe_dir_size "$SNAP_DIR")
    
    status_msg "Atualizando pacotes Snap"
    if sudo snap refresh; then
        success_msg "Atualização Snap concluída"
        
        # Limpar snaps antigos
        info_msg "Removendo versões antigas de snaps..."
        local SNAPS_TO_REMOVE=$(snap list --all | awk '/disabled/{print $1, $3}')
        while read -r snap_name revision; do
            if [ ! -z "$snap_name" ]; then
                sudo snap remove "$snap_name" --revision="$revision"
            fi
        done <<< "$SNAPS_TO_REMOVE"
        
        local SNAP_AFTER_SIZE=$(safe_dir_size "$SNAP_DIR")
        local SNAP_DOWNLOADED=$((SNAP_AFTER_SIZE - SNAP_BEFORE_SIZE))
        TOTAL_DOWNLOADED=$((TOTAL_DOWNLOADED + SNAP_DOWNLOADED))
    else
        error_msg "Falha na atualização dos pacotes Snap"
    fi
}

show_update_summary() {
    local END_TIME=$1
    local START_TIME=$2
    local TOTAL_TIME=$((END_TIME - START_TIME))

    printf "\n${BLUE}===============================================${NC}\n"
    if [ $ERRORS_COUNT -eq 0 ]; then
        success_msg "Todas as operações foram concluídas com sucesso!"
    else
        warning_msg "Operações concluídas com $ERRORS_COUNT erros. Verifique o log em $UPDATE_LOG"
    fi

    printf "\n${MAGENTA}📊 Estatísticas da atualização:${NC}\n"
    printf "%-25s ${GREEN}%s${NC}\n" "Tempo total:" "$(date -u -d @${TOTAL_TIME} +'%Hh %Mm %Ss')"
    printf "%-25s ${CYAN}%s${NC}\n" "Dados baixados:" "+$(human_size $((TOTAL_DOWNLOADED * 1024)))"
    printf "%-25s ${YELLOW}%s${NC}\n" "Espaço liberado:" "-$(human_size $((TOTAL_REMOVED * 1024)))"
    printf "%-25s ${MAGENTA}%s${NC}\n" "Erros encontrados:" "$ERRORS_COUNT"

    if [ -f /var/run/reboot-required ]; then
        printf "\n${YELLOW}⚠ ATENÇÃO: O sistema precisa ser reiniciado!${NC}\n"
        printf "${BLUE}➤ Execute: sudo reboot${NC}\n\n"
    else
        printf "\n${GREEN}✅ Sistema atualizado sem necessidade de reinício${NC}\n\n"
    fi
}

# Início do script
clear
printf "${BLUE}===============================================${NC}\n"
printf "${GREEN}  INICIANDO ATUALIZAÇÃO COMPLETA DO SISTEMA${NC}\n"
printf "${BLUE}===============================================${NC}\n"

# Criar/limpar arquivo de log
touch "$UPDATE_LOG"
echo "=== Início da atualização do sistema $(date) ===" > "$UPDATE_LOG"

START_TIME=$(date +%s)

# Verificações iniciais
check_internet
check_disk_space
check_package_manager

# Atualizações do sistema
try_step "Atualizando lista de pacotes" 2 5 apt update -q
try_step "Recarregando unidades systemd" 1 2 systemctl daemon-reload

# Atualização APT
APT_CACHE_DIR="/var/cache/apt/archives"
APT_BEFORE_SIZE=$(safe_dir_size "$APT_CACHE_DIR")

if try_step "Realizando upgrade de pacotes" 2 5 apt upgrade -y -q; then
    try_step "Realizando dist-upgrade" 2 5 apt dist-upgrade -y -q
fi

APT_AFTER_SIZE=$(safe_dir_size "$APT_CACHE_DIR")
APT_DOWNLOADED=$((APT_AFTER_SIZE - APT_BEFORE_SIZE))
TOTAL_DOWNLOADED=$((TOTAL_DOWNLOADED + APT_DOWNLOADED))

# Atualização Snap
update_snap_packages

# Atualização Flatpak
if command -v flatpak &> /dev/null; then
    FLATPAK_DIR="/var/lib/flatpak/repo/objects"
    [ -d "$FLATPAK_DIR" ] || FLATPAK_DIR="$HOME/.local/share/flatpak/repo/objects"
    
    FLATPAK_BEFORE_SIZE=$(safe_dir_size "$FLATPAK_DIR")
    
    if try_step "Atualizando aplicativos Flatpak" 3 10 flatpak update -y; then
        try_step "Limpando flatpaks não usados" 2 5 flatpak uninstall --unused -y
    fi
    
    FLATPAK_AFTER_SIZE=$(safe_dir_size "$FLATPAK_DIR")
    FLATPAK_DOWNLOADED=$((FLATPAK_AFTER_SIZE - FLATPAK_BEFORE_SIZE))
    TOTAL_DOWNLOADED=$((TOTAL_DOWNLOADED + FLATPAK_DOWNLOADED))
fi

# Limpeza final
CLEAN_BEFORE_SIZE=$(sudo df --output=avail / | tail -1 | tr -d ' ')
try_step "Removendo pacotes não necessários" 2 5 apt autoremove -y -q
try_step "Limpando cache de pacotes" 1 5 apt clean -q
CLEAN_AFTER_SIZE=$(sudo df --output=avail / | tail -1 | tr -d ' ')
TOTAL_REMOVED=$((CLEAN_AFTER_SIZE - CLEAN_BEFORE_SIZE))

END_TIME=$(date +%s)
show_update_summary "$END_TIME" "$START_TIME"

echo "=== Fim da atualização do sistema $(date) ===" >> "$UPDATE_LOG"
