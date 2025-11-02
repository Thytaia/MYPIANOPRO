#!/bin/bash

# =============================================================================
# SCRIPT DE GESTÃO DE PROJETO (PIA ROBUSTO)
#
# Este script automatiza o ciclo completo de vida do projeto:
# 1. Validação de ambiente (Git).
# 2. Inicialização de Repositório (se necessário).
# 3. Verificação de status remoto e execução de PULL.
# 4. Validação/Build interno.
# 5. Commit e PUSH de alterações locais.
# =============================================================================

# Variáveis globais
DEFAULT_BRANCH="main"
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

PROJECT_STATUS="INDEFINIDO" # Pode ser: EM_DIA, EM_ANDAMENTO, AGUARDANDO_PULL, CONFLITO
MAIN_BRANCH=""
REPO_URL=""

# =============================================================================
# FUNÇÕES DE UTILIDADE
# =============================================================================

# Função para logar mensagens coloridas
log() {
    echo -e "${GREEN}✅ PIA:${NC} $1"
}

# Função para sair em caso de falha grave
fail_exit() {
    echo -e "🚨 ${RED}ERRO FATAL DO PIA:${NC} $1" >&2
    exit 1
}

# Função para logar avisos
warn() {
    echo -e "${YELLOW}⚠️ AVISO DO PIA:${NC} $1"
}

# Função para inicializar um novo repositório
initialize_repo() {
    log "2. Repositório NÃO encontrado. Inicializando novo repositório Git..."
    git init -b "$DEFAULT_BRANCH" || fail_exit "Falha ao inicializar o Git."
    
    # Cria um README.md básico
    echo "# Projeto $DEFAULT_BRANCH" > README.md
    echo "" >> README.md
    echo "Inicializado por $0 em $(date '+%Y-%m-%d %H:%M:%S')." >> README.md
    
    git add . || fail_exit "Falha ao adicionar README inicial."
    git commit -m "[INIT] Repositório inicializado com sucesso." || fail_exit "Falha ao criar commit inicial."
    
    log "Novo repositório criado. Adicione um remoto (git remote add origin <URL>) e execute novamente."
    PROJECT_STATUS="NAO_CONECTADO"
    return 0
}

# Função principal de verificação e sincronização
sync_and_validate() {
    log "3. Verificando status e URL remota..."
    MAIN_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    REPO_URL=$(git config --get remote.origin.url)

    if [ -z "$REPO_URL" ]; then
        warn "Repositório Git não tem um 'remote origin' configurado. Apenas validação local será executada."
        PROJECT_STATUS="NAO_CONECTADO"
    else
        log "   - Branch Atual: $MAIN_BRANCH"
        log "   - Repositório Remoto: $REPO_URL"

        # Tenta buscar o status mais recente do remoto (silencioso)
        git fetch origin 2>/dev/null || warn "Falha ao buscar o repositório remoto. Verifique a conexão/permissões."

        # Verifica o status da branch em relação ao remoto
        UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
        if [ $? -ne 0 ]; then
            PROJECT_STATUS="SEM_UPSTREAM"
            warn "Branch local '$MAIN_BRANCH' não tem rastreamento remoto configurado (upstream)."
        elif [ $(git rev-list --count HEAD..$UPSTREAM) -gt 0 ]; then
            PROJECT_STATUS="AGUARDANDO_PULL"
            log "   - Status: ${YELLOW}AGUARDANDO_PULL${NC}. Remoto está à frente! Puxando alterações..."
            
            # --- EXECUTA O PULL/MERGE/REBASE antes de qualquer outra coisa ---
            log "4. Executando PULL (Rebase) para integrar alterações remotas..."
            git pull --rebase origin "$MAIN_BRANCH" || fail_exit "Falha ao executar PULL/REBASE. Pode haver conflitos manuais a resolver."
            log "PULL/REBASE concluído com sucesso."
        fi
        
        # Reavalia o status de alterações locais após o possível pull
        if [ $(git status --porcelain | wc -l) -gt 0 ]; then
            PROJECT_STATUS="EM_ANDAMENTO"
            log "   - Status: ${YELLOW}EM_ANDAMENTO${NC}. Há alterações locais a serem salvas."
        elif [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u} 2>/dev/null)" ]; then
             PROJECT_STATUS="AGUARDANDO_PUSH"
             log "   - Status: ${YELLOW}AGUARDANDO_PUSH${NC}. Local está à frente, pronto para enviar."
        else
            PROJECT_STATUS="EM_DIA"
            log "   - Status: ${GREEN}EM_DIA${NC}. Repositório local e remoto estão sincronizados."
        fi
    fi

    # --- 5. VALIDAÇÃO INTERNA DO PROJETO (BUILD/TEST) ---
    log "5. Executando validação interna do projeto (Build/Test)..."
    
    # Substitua a linha abaixo pelo seu comando real de build/teste (Ex: npm test, make all, etc.)
    echo "Simulando processo de build/teste... [Substitua esta linha pelo seu comando real de build/validação]"
    
    # ATENÇÃO: É VITAL verificar o status de saída do seu comando de build/teste!
    # if [ $? -ne 0 ]; then
    #     fail_exit "Falha na validação do projeto (Build/Test). Processamento interrompido."
    # fi
    
    log "Validação interna concluída com sucesso."

    # --- 6. EXECUÇÃO DA PARTE NECESSÁRIA (COMMIT & PUSH) ---
    log "6. Executando sincronização de alterações locais (PUSH)..."

    # Faz o commit e push apenas se houver trabalho local ou se estiver pronto para push
    if [ "$PROJECT_STATUS" = "EM_ANDAMENTO" ] || [ "$PROJECT_STATUS" = "AGUARDANDO_PUSH" ]; then
        log "Preparando commit das alterações..."

        # Adiciona todos os arquivos modificados e novos
        git add . || fail_exit "Falha ao adicionar arquivos ao stage."

        # Cria a mensagem de commit (apenas commita se houver algo novo para commitar)
        COMMIT_MSG="[SYNC] Sincronização automática em $(date '+%Y-%m-%d %H:%M:%S')."
        git commit -m "$COMMIT_MSG" 

        if [ $? -eq 0 ] || [ "$PROJECT_STATUS" = "AGUARDANDO_PUSH" ]; then
            log "Enviando (push) alterações para $REPO_URL..."

            # Envia as alterações para o branch remoto
            git push origin "$MAIN_BRANCH" || fail_exit "Falha ao enviar (push) as alterações. Verifique se o branch remoto existe ou se há conflitos."

            log "Sincronização (PUSH) concluída com sucesso!"
            PROJECT_STATUS="EM_DIA"
        else
            log "Nenhuma alteração detectada para commit após o 'git add'. PULO o PUSH."
            PROJECT_STATUS="EM_DIA"
        fi
    elif [ "$PROJECT_STATUS" = "EM_DIA" ]; then
        log "Não há alterações locais ou remotas pendentes. O projeto já está EM DIA."
    else
        warn "Status '$PROJECT_STATUS' não requer PUSH automático. Fim do processamento."
    fi
}


# =============================================================================
# INÍCIO DO FLUXO PRINCIPAL
# =============================================================================

# 1. VERIFICA SE O GIT ESTÁ INSTALADO
log "1. Verificando ambiente..."
if ! command -v git &> /dev/null
then
    fail_exit "Git não está instalado. Por favor, instale-o para continuar."
fi
log "   - Git verificado e funcional."

# 2. VERIFICA SE JÁ É UM REPOSITÓRIO GIT
if git rev-parse --is-inside-work-tree &> /dev/null
then
    # Repositório Existente: Inicia a validação e sincronização
    sync_and_validate
else
    # Repositório Não Existente: Inicializa
    initialize_repo
fi

log "=================================================="
log "PROJETO CONCLUÍDO. STATUS FINAL: $PROJECT_STATUS"
log "=================================================="

exit 0
