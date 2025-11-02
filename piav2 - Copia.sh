#!/bin/bash

# ==============================================================================
# SCRIPT DE INICIALIZAÇÃO E SINCRONIZAÇÃO GIT
#
# Este script verifica o ambiente Git, valida o projeto, e agora
# também configura o 'remote origin' e faz o primeiro push, se necessário.
# ==============================================================================

# Variáveis
DEFAULT_BRANCH="main"
PROJECT_STATUS="INDEFINIDO"
REPO_URL=""
MAIN_BRANCH=""

# Funções de Log e Erro
log() {
    echo "✅ PIA: $1"
}

log_warning() {
    echo "⚠️ AVISO DO PIA: $1"
}

fail_exit() {
    echo "❌ ERRO DO PIA: $1"
    echo "✅ PIA: =================================================="
    echo "✅ PIA: PROJETO FALHOU. STATUS FINAL: FALHA_EXECUCAO"
    echo "✅ PIA: =================================================="
    exit 1
}

# --- 1. VERIFICAÇÃO DO AMBIENTE ---
log "1. Verificando ambiente..."

if ! command -v git &> /dev/null
then
    echo "🚨 ERRO: Git não está instalado. Por favor, instale o Git para continuar."
    exit 1
fi

log "   - Git verificado e funcional."

# --- 2. VERIFICA SE JÁ É UM REPOSITÓRIO GIT ---
log "2. Verificando status do repositório..."

if git rev-parse --is-inside-work-tree &> /dev/null
then
    # Repositório Existente
    PROJECT_ROOT=$(git rev-parse --show-toplevel)
    MAIN_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    
    log "   - Você está DENTRO de um repositório Git."
    log "   - Raiz do Projeto (Validação da Pasta): $PROJECT_ROOT"
    log "   - Branch Atual: $MAIN_BRANCH"

    # 3. VERIFICA URL REMOTA
    log "3. Verificando URL remota (origin)..."
    REPO_URL=$(git config --get remote.origin.url)

    if [ -z "$REPO_URL" ]; then
        PROJECT_STATUS="NAO_CONECTADO"
        log_warning "Repositório Git não tem um 'remote origin' configurado."
    else
        PROJECT_STATUS="CONECTADO"
        log "   - URL Remota: $REPO_URL"
    fi

else
    # Inicializa Novo Repositório Local
    log "   - Repositório não encontrado. Inicializando novo repositório local..."
    git init -b "$DEFAULT_BRANCH" || fail_exit "Falha ao inicializar o Git localmente."
    MAIN_BRANCH="$DEFAULT_BRANCH"
    PROJECT_STATUS="NAO_CONECTADO"
    log "   - Repositório local inicializado com sucesso na branch '$MAIN_BRANCH'."
    log_warning "Repositório Git não tem um 'remote origin' configurado. Inicialização remota será necessária."
fi

# --- 4. TRATAMENTO DO STATUS: NAO_CONECTADO ---
if [ "$PROJECT_STATUS" = "NAO_CONECTADO" ]; then
    log "4. Inicializando conexão com repositório online..."

    # Pede a URL remota ao usuário
    echo "=================================================="
    echo "ATENÇÃO: É necessário configurar o repositório online (Remote Origin)."
    read -r -p "Por favor, cole a URL Git (HTTPS ou SSH) do seu repositório online (Ex: git@github.com:user/repo.git): " REMOTE_URL
    echo "=================================================="

    if [ -z "$REMOTE_URL" ]; then
        fail_exit "URL remota não fornecida. Impossível configurar a conexão."
    fi

    log "   - Configurando 'remote origin' para: $REMOTE_URL"
    git remote add origin "$REMOTE_URL" || fail_exit "Falha ao adicionar o remote origin."
    
    # Realiza o primeiro commit (se houver arquivos) e push
    log "   - Preparando primeiro commit e push inicial..."
    
    # Adiciona todos os arquivos
    git add . || fail_exit "Falha ao adicionar arquivos ao stage."
    
    # Verifica se há algo para commitar (evita erro)
    if git diff --cached --exit-code --quiet; then
        log "AVISO: Nenhum arquivo novo ou modificado para o commit inicial."
    else
        COMMIT_MSG="[INIT] Setup inicial do projeto via pia.sh em $(date '+%Y-%m-%d %H:%M:%S')."
        git commit -m "$COMMIT_MSG" || fail_exit "Falha ao criar o commit inicial."
        log "   - Commit inicial criado."
    fi

    log "   - Enviando (push) inicial para $MAIN_BRANCH e definindo rastreamento (upstream)..."
    # O comando -u (ou --set-upstream) é crucial no primeiro push
    git push -u origin "$MAIN_BRANCH" || fail_exit "Falha no PUSH inicial. Verifique suas credenciais e a URL remota."

    PROJECT_STATUS="CONECTADO"
    log "✅ Conexão remota e push inicial concluídos com sucesso!"
fi


# --- 5. VALIDAÇÃO INTERNA (BUILD/TEST) ---
log "5. Executando validação interna do projeto (Build/Test)..."

# --- SIMULAÇÃO DE BUILD/TEST (Substituir) ---
echo "Simulando processo de build/teste... [Substitua esta linha pelo seu comando real de build/validação]"
# if [ $? -ne 0 ]; then
#     fail_exit "Falha na validação do projeto (Build/Test)."
# # fi

log "Validação interna concluída com sucesso."

# --- 6. EXECUÇÃO DA SINCRONIZAÇÃO (PUSH) - Apenas se CONECTADO ---
log "6. Executando sincronização de alterações locais (PUSH)..."

if [ "$PROJECT_STATUS" = "CONECTADO" ]; then
    # Checa se há modificações locais pendentes (tracked files)
    if ! git diff --exit-code --quiet || ! git diff --cached --exit-code --quiet; then
        log "   - Alterações locais detectadas. Preparando commit e push..."

        # Adiciona todos os arquivos modificados e novos (incluindo untracked)
        git add . || fail_exit "Falha ao adicionar arquivos ao stage."
        
        # Cria a mensagem de commit
        COMMIT_MSG="[SYNC] Sincronização automática em $(date '+%Y-%m-%d %H:%M:%S')."

        # Tenta commitar. Se não houver mudanças após o 'git add', o commit falhará, mas não deve ser considerado um erro fatal.
        git commit -m "$COMMIT_MSG" 
        
        if [ $? -ne 0 ]; then
             log "AVISO: Nada para commitar após o 'git add'. (Pode ser apenas arquivos untracked que já foram adicionados antes)."
        else
            log "   - Commit criado."
        fi

        log "   - Enviando (push) alterações para o repositório remoto..."
        git push origin "$MAIN_BRANCH" || fail_exit "Falha ao enviar (push) as alterações para o repositório remoto."

        log "✅ Sincronização (PUSH) concluída com sucesso."
    else
        log "   - Repositório local está limpo. Nenhuma sincronização (PUSH) necessária."
    fi
else
    log_warning "Status '$PROJECT_STATUS' não permite PUSH automático nesta etapa."
fi


# --- FIM DO PROCESSAMENTO ---
log "=================================================="
log "PROJETO CONCLUÍDO. STATUS FINAL: $PROJECT_STATUS"
log "=================================================="
