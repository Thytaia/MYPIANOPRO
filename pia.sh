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
