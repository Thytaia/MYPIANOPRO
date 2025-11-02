#!/bin/bash

# ==============================================================================
# SCRIPT DE GERENCIAMENTO DE FLUXO E VALIDAÇÃO DE PROJETO GIT
#
# Este script verifica o estado do projeto (local vs. remoto) e oferece um
# menu condicional de ações baseadas na fase atual (Inicialização, Push Inicial,
# ou Desenvolvimento Contínuo).
# ==============================================================================

# Variáveis e Utilitários
DEFAULT_BRANCH="main"
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função de Log
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Função de Saída em Caso de Falha
fail_exit() {
    echo -e "${RED}🚨 ERRO: $1${NC}"
    exit 1
}

# Função principal para determinar o status do projeto
get_project_status() {
    # 1. Verifica se já é um repositório Git
    if ! git rev-parse --is-inside-work-tree &> /dev/null
    then
        echo "PHASE_INIT_LOCAL" # Repositório local não iniciado
        return
    fi

    # 2. Verifica a existência do remoto (origin)
    local REPO_URL=$(git config --get remote.origin.url)
    if [ -z "$REPO_URL" ]; then
        echo "PHASE_CONFIG_REMOTE" # Repositório local, mas sem URL remota
        return
    fi

    # 3. Verifica se há um branch remoto rastreado (indicando o primeiro push)
    if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &> /dev/null; then
        # Se não houver upstream (branch remoto rastreado), estamos na fase de PUSH INICIAL
        echo "PHASE_INITIAL_PUSH"
        return
    fi

    # 4. Se houver remoto, verifica o estado de sincronização
    # Tenta buscar (fetch) as alterações do remoto silenciosamente
    git fetch origin > /dev/null 2>&1

    local LOCAL=$(git rev-parse @)
    local REMOTE=$(git rev-parse @{u})
    local BASE=$(git merge-base @ @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then
        # Local e remoto estão iguais
        echo "PHASE_ORGANIZED"
    elif [ "$LOCAL" != "$REMOTE" ] && [ "$BASE" = "$LOCAL" ]; then
        # O remoto está à frente (precisa de PULL)
        echo "PHASE_PULL_NEEDED"
    elif [ "$LOCAL" != "$REMOTE" ] && [ "$BASE" = "$REMOTE" ]; then
        # O local está à frente (precisa de PUSH)
        echo "PHASE_DEVELOPMENT"
    else
        # Branches divergiram
        echo "PHASE_DIVERGED"
    fi
}

# Função para iniciar o repositório local
init_local_repo() {
    log "Inicializando um novo repositório Git local..."
    git init || fail_exit "Falha ao inicializar o repositório Git."
    git checkout -b "$DEFAULT_BRANCH" > /dev/null 2>&1 || git branch -M "$DEFAULT_BRANCH" # Cria ou renomeia para a branch padrão
    log "Repositório Git local criado com sucesso na branch '$DEFAULT_BRANCH'."
    echo ""
    log "PRÓXIMO PASSO CRÍTICO: Crie seus arquivos iniciais (README.md, .gitignore, etc.) e configure o remoto."
    sleep 2
}

# Função para configuração remota
config_remote() {
    echo ""
    echo -e "${YELLOW}========================================================================${NC}"
    echo -e "${YELLOW}        PASSO 1/2: CONFIGURAR O REPOSITÓRIO REMOTO (ONLINE)             ${NC}"
    echo -e "${YELLOW}========================================================================${NC}"
    read -p "Por favor, insira a URL do seu repositório remoto (ex: git@github.com:user/repo.git): " REPO_URL

    # Adiciona o remoto e verifica se deu certo
    git remote add origin "$REPO_URL" 2> /dev/null || git remote set-url origin "$REPO_URL"
    if [ $? -ne 0 ]; then
        fail_exit "URL remota inválida ou falha ao configurar o 'origin'. Verifique a URL fornecida."
    fi

    log "URL remota 'origin' configurada para: $REPO_URL"
    echo ""
    log "PRÓXIMO PASSO: Faça o PUSH INICIAL dos seus arquivos de documentação."
    sleep 2
}

# Função para o primeiro push (criação do remoto)
initial_push() {
    echo ""
    echo -e "${YELLOW}========================================================================${NC}"
    echo -e "${YELLOW}        PASSO 2/2: PUSH INICIAL (DOCUMENTAÇÃO E ARQUIVOS BASE)          ${NC}"
    echo -e "${YELLOW}========================================================================${NC}"

    # Validação de arquivos iniciais (Ex: README.md)
    if [ ! -f "README.md" ]; then
        log "AVISO: O arquivo README.md não foi encontrado. Criando um placeholder."
        echo "# Nome do Projeto" > README.md
        echo "## Status: Em Desenvolvimento Inicial" >> README.md
    fi

    log "Adicionando todos os arquivos ao stage..."
    git add . || fail_exit "Falha ao adicionar arquivos ao stage."

    log "Criando Commit Inicial..."
    local COMMIT_MSG="[INIT] Setup inicial do projeto e documentação base."
    git commit -m "$COMMIT_MSG" || log "AVISO: Não há nada para commitar, pulando commit." # Permite continuar mesmo sem alterações

    log "Executando Push Inicial para a branch '$DEFAULT_BRANCH' e configurando upstream..."
    # A flag -u (ou --set-upstream) é crucial para esta fase
    git push -u origin "$DEFAULT_BRANCH" || fail_exit "Falha catastrófica ao executar o PUSH INICIAL. Verifique suas credenciais Git/SSH e permissões."

    log "🎉 PROJETO INICIALIZADO! A pasta local está sincronizada com o remoto."
    echo ""
    log "Agora você pode prosseguir com o desenvolvimento. Rodando o script novamente..."
    sleep 3
    # Chama a função principal novamente para reavaliar o status
    main_menu
}


# Função para o menu principal em fases posteriores
show_main_menu() {
    local STATUS="$1"
    
    echo ""
    echo -e "${YELLOW}========================================================================${NC}"
    echo -e "${YELLOW}        FLUXO DE PROJETO: [${STATUS}]                                   ${NC}"
    echo -e "${YELLOW}========================================================================${NC}"
    echo "O projeto se encontra na fase: ${YELLOW}${STATUS}${NC}"
    echo "O que você gostaria de fazer agora?"
    echo ""
    
    # Menu Condicional
    case "$STATUS" in
        PHASE_PULL_NEEDED)
            echo "1) 📥 PULL: Baixar e integrar as alterações mais recentes do repositório remoto."
            echo "2) ⚙️ STATUS: Mostrar o status detalhado do Git."
            echo "x) SAIR."
            read -p "Opção (1/2/x): " choice
            case "$choice" in
                1) git pull origin "$DEFAULT_BRANCH" || fail_exit "Falha ao executar PULL. Resolva conflitos e tente novamente.";;
                2) git status;;
                x) exit 0;;
                *) echo "Opção inválida.";;
            esac
            ;;

        PHASE_DEVELOPMENT | PHASE_DIVERGED)
            echo "1) ➕ COMMIT & PUSH: Adicionar, commitar e enviar alterações locais para o remoto."
            echo "2) ⚙️ STATUS: Mostrar o status detalhado do Git."
            echo "3) 🔄 PULL: Baixar (apenas se for DIVERGED ou se souber que o remoto está na frente)."
            echo "x) SAIR."
            read -p "Opção (1/2/3/x): " choice
            case "$choice" in
                1) 
                    read -p "Mensagem de Commit (Ex: feat: Implementa feature X): " COMMIT_MSG
                    git add . || fail_exit "Falha ao adicionar arquivos ao stage."
                    git commit -m "$COMMIT_MSG" || log "AVISO: Não há alterações para commitar."
                    git push origin "$DEFAULT_BRANCH" || fail_exit "Falha ao executar PUSH. Verifique se precisa de PULL primeiro."
                    log "PUSH concluído. Sincronizado."
                    ;;
                2) git status;;
                3) git pull origin "$DEFAULT_BRANCH" || fail_exit "Falha ao executar PULL. Resolva conflitos e tente novamente.";;
                x) exit 0;;
                *) echo "Opção inválida.";;
            esac
            ;;

        PHASE_ORGANIZED)
            echo "✅ Repositório Sincronizado (Local e Remoto estão iguais)."
            echo "O projeto está pronto para o próximo ciclo de desenvolvimento (POC Estável)."
            echo "1) ⚙️ STATUS: Mostrar o status detalhado do Git."
            echo "2) 🚀 INICIAR POC: Comando de build/teste (Simulação)."
            echo "x) SAIR."
            read -p "Opção (1/2/x): " choice
            case "$choice" in
                1) git status;;
                2) log "Simulando comando de INICIAR POC (Ex: docker build ou npm run dev)...";;
                x) exit 0;;
                *) echo "Opção inválida.";;
            esac
            ;;
        *)
            echo "Opções padrão:"
            echo "1) ⚙️ STATUS: Mostrar o status detalhado do Git."
            echo "x) SAIR."
            read -p "Opção (1/x): " choice
            case "$choice" in
                1) git status;;
                x) exit 0;;
                *) echo "Opção inválida.";;
            esac
            ;;
    esac
}


# Função principal de controle
main_menu() {
    # 1. Verifica se o Git está instalado
    if ! command -v git &> /dev/null
    then
        fail_exit "Git não está instalado. Por favor, instale o Git para continuar."
    fi

    local PROJECT_STATUS=$(get_project_status)

    case "$PROJECT_STATUS" in
        PHASE_INIT_LOCAL)
            init_local_repo
            # O status é recalculado após a inicialização local
            PROJECT_STATUS=$(get_project_status) 
            # Continua para a próxima verificação (PHASE_CONFIG_REMOTE)
            ;& # Fallthrough para o próximo case
        
        PHASE_CONFIG_REMOTE)
            config_remote
            # O status é recalculado após a configuração remota
            PROJECT_STATUS=$(get_project_status) 
            # Continua para a próxima verificação (PHASE_INITIAL_PUSH)
            ;& # Fallthrough para o próximo case

        PHASE_INITIAL_PUSH)
            initial_push
            # Retorna aqui após o push inicial ser feito com sucesso
            ;;

        PHASE_PULL_NEEDED | PHASE_DEVELOPMENT | PHASE_ORGANIZED | PHASE_DIVERGED)
            show_main_menu "$PROJECT_STATUS"
            ;;
        
        REMOTE_UNREACHABLE)
            fail_exit "O repositório remoto está inacessível. Verifique sua conexão ou a URL remota."
            ;;
        
        *)
            fail_exit "Status desconhecido: $PROJECT_STATUS. Reinicie o script ou investigue o estado do Git."
            ;;
    esac

    # Após uma ação, mostra o menu novamente se o estado final não for 'SAIR'
    if [ "$choice" != "x" ]; then
        echo ""
        log "Ação concluída. Reavaliando o estado do projeto..."
        sleep 2
        main_menu
    fi
}

# Executa o script
main_menu
