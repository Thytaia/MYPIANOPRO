#!/bin/bash

# ==============================================================================
# SCRIPT DE INICIALIZAÇÃO E VALIDAÇÃO DE PROJETO GIT
#
# Este script verifica o ambiente Git e inicializa um novo repositório, se
# necessário, garantindo que o usuário esteja sempre validado dentro da pasta
# do projeto.
# ==============================================================================

# Variável para a branch padrão (pode ser alterada para 'master' se necessário)
DEFAULT_BRANCH="main"

# 1. VERIFICA SE O GIT ESTÁ INSTALADO
if ! command -v git &> /dev/null
then
    echo "🚨 ERRO: Git não está instalado. Por favor, instale o Git para continuar."
    exit 1
fi

# 2. VERIFICA SE JÁ É UM REPOSITÓRIO GIT
if git rev-parse --is-inside-work-tree &> /dev/null
then
    # --- Repositório Existente (VALIDAÇÃO) ---
    PROJECT_ROOT=$(git rev-parse --show-toplevel)
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    
    echo "✅ VALIDAÇÃO BEM-SUCEDIDA:"
    echo "   - Status: Você está DENTRO de um repositório Git."
    echo "   - Raiz do Projeto (Validação da Pasta): $PROJECT_ROOT"
    
    if [ "$CURRENT_BRANCH" == "$DEFAULT_BRANCH" ]
    then
        echo "   - Branch Atual (Validação da Branch): $CURRENT_BRANCH (Branch principal)"
    else
        echo "   - Branch Atual (Validação da Branch): $CURRENT_BRANCH (⚠️ Não é a branch principal '$DEFAULT_BRANCH')"
    fi
    
    echo "--------------------------------------------------------"
    echo "Status de trabalho:"
    git status -s
    
else
    # --- Repositório Inexistente (INICIALIZAÇÃO) ---
    
    echo "🟡 Status: Não é um repositório Git. Iniciando novo projeto..."
    
    # Inicializa o repositório Git na pasta atual
    git init
    
    # Define a branch principal como 'main' (ou 'master', se preferir)
    git branch -M "$DEFAULT_BRANCH"
    
    # Cria o arquivo README.md para o commit inicial
    echo "# Projeto $DEFAULT_BRANCH Inicializado" > README.md
    
    # Adiciona e faz o commit inicial
    git add .
    git commit -m "Commit inicial: Estrutura base e README."
    
    echo "🎉 SUCESSO! O repositório Git foi INICIALIZADO."
    echo "   - Raiz do Projeto: $(pwd)"
    echo "   - Branch Ativa: $DEFAULT_BRANCH"
    echo "--------------------------------------------------------"
    echo "Lembre-se de adicionar um remote: git remote add origin <URL>"
fi

exit 0

#!/bin/bash

# ==============================================================================
# SCRIPT DE VALIDAÇÃO E SINCRONIZAÇÃO DO PROJETO MYPIANOPRO
# ==============================================================================

# Variáveis de Configuração
REPO_URL="https://github.com/Thytaia/MYPIANOPRO"
# O branch principal do seu projeto. Ajuste se for 'master' ou outro.
MAIN_BRANCH="main"
# Diretório onde o repositório está clonado (use . para o diretório atual)
PROJECT_DIR="."

# --- Funções de Ajuda e Logging ---

# Função para imprimir mensagens de status
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Função para sair em caso de erro fatal
fail_exit() {
    log "ERRO FATAL: $1"
    exit 1
}

# --- 1. CONFIGURAÇÃO E VERIFICAÇÃO INICIAL ---
log "Iniciando processo de validação e sincronização do projeto..."

cd "$PROJECT_DIR" || fail_exit "Não foi possível entrar no diretório do projeto: $PROJECT_DIR"

# Verifica se é um repositório Git
if [ ! -d ".git" ]; then
    fail_exit "O diretório não é um repositório Git válido. Clone o projeto primeiro: git clone $REPO_URL"
fi

# Verifica o status atual do branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$MAIN_BRANCH" ]; then
    log "AVISO: Não está no branch principal ($MAIN_BRANCH). Trocando..."
    git checkout "$MAIN_BRANCH" || fail_exit "Não foi possível trocar para o branch $MAIN_BRANCH"
fi

# --- 2. SINCRONIZAÇÃO DE STATUS (PULL) ---
log "2. Sincronizando com o repositório remoto..."

# Puxa as alterações mais recentes do GitHub
git pull origin "$MAIN_BRANCH" || fail_exit "Falha ao puxar (pull) as alterações do $MAIN_BRANCH remoto."

log "Sincronização remota concluída com sucesso. Versão local atualizada."

# --- 3. VALIDAÇÃO E VERIFICAÇÃO DO ANDAMENTO DO PROJETO ---
log "3. Executando validações e verificações do projeto..."

# Verifica se há arquivos modificados ou não rastreados localmente.
# O 'in_progress_status' é definido se houver algo para commitar.
IN_PROGRESS_STATUS=$(git status --porcelain)

if [ -z "$IN_PROGRESS_STATUS" ]; then
    log "STATUS: Projeto CONCLUÍDO (sem alterações pendentes). OK."
    PROJECT_STATUS="CONCLUIDO"
else
    log "STATUS: Projeto EM ANDAMENTO (encontradas alterações locais)."
    PROJECT_STATUS="EM_ANDAMENTO"
fi

# Executa o passo de BUILD/TEST (Substitua esta linha pelo seu comando real!)
log "Executando comando de validação/build (ex: npm install/npm test/jekyll build)..."
# Exemplo: npm install && npm run build
echo "Simulando processo de build/teste... [Substitua esta linha pelo seu comando real de build/validação]"
# if [ $? -ne 0 ]; then
#     fail_exit "Falha na validação do projeto (Build/Test)."
# # fi

log "Validação interna concluída com sucesso."

# --- 4. EXECUÇÃO DA PARTE NECESSÁRIA (PUSH) ---
log "4. Executando sincronização necessária (PUSH)..."

# Se o projeto estiver "EM ANDAMENTO" (e houver alterações locais), faça o commit e push.
if [ "$PROJECT_STATUS" = "EM_ANDAMENTO" ]; then
    log "Preparando commit das alterações..."

    # Adiciona todos os arquivos modificados e novos
    git add . || fail_exit "Falha ao adicionar arquivos ao stage."

    # Cria a mensagem de commit
    COMMIT_MSG="[SYNC] Sincronização automática em $(date '+%Y-%m-%d %H:%M:%S')."

    # Cria o commit (o --allow-empty é opcional, mas garante que a rotina rode)
    git commit -m "$COMMIT_MSG" || log "AVISO: Não há nada para commitar após o 'git add'."

    log "Enviando (push) alterações para $REPO_URL..."

    # Envia as alterações para o branch remoto
    git push origin "$MAIN_BRANCH" || fail_exit "Falha ao enviar (push) as alterações para o repositório remoto."

    log "Sincronização (PUSH) concluída! O projeto está sincronizado com o GitHub."
else
    log "Nenhuma alteração local detectada. Nenhuma ação de PUSH é necessária."
fi

log "Processo de sincronização finalizado."
# ==============================================================================
