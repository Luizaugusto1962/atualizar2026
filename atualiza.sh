#!/usr/bin/env bash
#
# Atualiza.sh - Script de Atualizacao Modular do SISTEMA SAV
# Versao: 20/02/2026-00
# Autor: Luiz Augusto
# Os programas usados por este script devem estar na pasts /libs.

set -euo pipefail # Configuracao de seguranca para o script
export LC_ALL=C

# Verificacoes basicas
if [[ ! -t 0 && ! -p /dev/stdin ]]; then
    printf "%s\n" "Este script deve ser executado interativamente" >&2
    exit 1
fi
TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Diretorio do script atual

# Diretorio do script TOOLS_DIR
PLIBS_DIR="${TOOLS_DIR}/libs" # Diretorio das bibliotecas
readonly PLIBS_DIR TOOLS_DIR  # Define variaveis como somente leitura

# Verifica se o diretorio libs existe
if [[ ! -d "${PLIBS_DIR}" ]]; then
    printf "%s\n" "ERRO: Diretorio ${PLIBS_DIR} nao encontrado."
    exit 1
fi

# Verifica se o arquivo principal.sh existe
if [[ -f "${PLIBS_DIR}/principal.sh" ]]; then
    printf "%s\n" "Carregando utilitario..."
    # Carrega o script principal
    cd "${PLIBS_DIR}" || exit 1
    "./principal.sh"
else
    printf "%s\n" "ERRO: Arquivo ${PLIBS_DIR}/principal.sh nao encontrado."
fi