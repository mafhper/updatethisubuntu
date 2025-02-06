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

# Funções de exibição
status_msg() {
    printf "\n${BLUE}== [ %s ] ${NC}%s\n" "$(date +'%H:%M:%S')" "$1"
}

success_msg() {
    printf "${GREEN}✔ %s${NC}\n" "$1"
}

error_msg() {
    printf "${RED}✖ %s${NC}\n" "$1" >&2
}

warning_msg() {
    printf "${YELLOW}⚠ %s${NC}\n" "$1"
}

info_msg() {
    printf "${CYAN}➤ %s${NC}\n" "$1"
}

metric_msg() {
    printf "${MAGENTA}📊 %s${NC}\n" "$1"
}

human_size() {
    echo "$1" | numfmt --to=iec --suffix=B --padding=7
}

safe_dir_size() {
    sudo du -s "$1" 2>/dev/null | cut -f1 || echo 0
}

check_flatpak() {
    if command -v flatpak &> /dev/null; then
        return 0
    else
        warning_msg "Flatpak não está instalado. Pulando atualizações de flatpak."
        return 1
    fi
}

try_step() {
    local STEP_DESC=$1
    local MAX_RETRIES=${2:-1}
    local RETRY_DELAY=${3:-5}
    shift 3

    status_msg "${STEP_DESC}..."
    
    for ((i=1; i<=$MAX_RETRIES; i++)); do
        if sudo "$@"; then  # Adicionado sudo aqui para garantir permissões
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
    exit 1
}

# Cabeçalho inicial
clear
printf "${BLUE}===============================================${NC}\n"
printf "${GREEN}  INICIANDO ATUALIZAÇÃO COMPLETA DO SISTEMA${NC}\n"
printf "${BLUE}===============================================${NC}\n"

START_TIME=$(date +%s)

# Atualizações do sistema
try_step "Atualizando lista de pacotes" 1 5 apt update -q
try_step "Recarregando unidades systemd" 1 2 systemctl daemon-reload

APT_CACHE_DIR="/var/cache/apt/archives"
APT_BEFORE_SIZE=$(safe_dir_size "$APT_CACHE_DIR")

try_step "Realizando upgrade de pacotes" 1 5 apt upgrade -y -q
try_step "Realizando dist-upgrade" 1 5 apt dist-upgrade -y -q

APT_AFTER_SIZE=$(safe_dir_size "$APT_CACHE_DIR")
APT_DOWNLOADED=$((APT_AFTER_SIZE - APT_BEFORE_SIZE))
TOTAL_DOWNLOADED=$((TOTAL_DOWNLOADED + APT_DOWNLOADED))

# Atualizações Flatpak
if check_flatpak; then
    FLATPAK_DIR="/var/lib/flatpak/repo/objects"
    [ -d "$FLATPAK_DIR" ] || FLATPAK_DIR="$HOME/.local/share/flatpak/repo/objects"
    
    FLATPAK_BEFORE_SIZE=$(safe_dir_size "$FLATPAK_DIR")
    
    try_step "Atualizando aplicativos Flatpak" 3 10 flatpak update -y
    
    FLATPAK_AFTER_SIZE=$(safe_dir_size "$FLATPAK_DIR")
    FLATPAK_DOWNLOADED=$((FLATPAK_AFTER_SIZE - FLATPAK_BEFORE_SIZE))
    TOTAL_DOWNLOADED=$((TOTAL_DOWNLOADED + FLATPAK_DOWNLOADED))
    
    try_step "Limpando flatpaks não usados" 2 5 flatpak uninstall --unused -y
fi

# Limpeza final
CLEAN_BEFORE_SIZE=$(sudo df --output=avail / | tail -1 | tr -d ' ')
try_step "Removendo pacotes não necessários" 1 5 apt autoremove -y -q
try_step "Limpando cache de pacotes" 1 5 apt clean -q
CLEAN_AFTER_SIZE=$(sudo df --output=avail / | tail -1 | tr -d ' ')
TOTAL_REMOVED=$((CLEAN_AFTER_SIZE - CLEAN_BEFORE_SIZE))

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

printf "\n${BLUE}===============================================${NC}\n"
success_msg "Todas as operações foram concluídas com sucesso!"

printf "\n${MAGENTA}📊 Estatísticas da atualização:${NC}\n"
printf "%-25s ${GREEN}%s${NC}\n" "Tempo total:" "$(date -u -d @${TOTAL_TIME} +'%Hh %Mm %Ss')"
printf "%-25s ${CYAN}%s${NC}\n" "Dados baixados:" "+$(human_size $((TOTAL_DOWNLOADED * 1024)))"
printf "%-25s ${YELLOW}%s${NC}\n" "Espaço liberado:" "-$(human_size $((TOTAL_REMOVED * 1024)))"

if [ -f /var/run/reboot-required ]; then
    printf "\n${YELLOW}⚠ ATENÇÃO: O sistema precisa ser reiniciado!${NC}\n"
    printf "${BLUE}➤ Execute: sudo reboot${NC}\n\n"
else
    printf "\n${GREEN}✅ Sistema atualizado sem necessidade de reinício${NC}\n\n"
fi
