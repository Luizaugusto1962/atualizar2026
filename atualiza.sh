#!/usr/bin/env bash
#
# Atualiza.sh - Script de Atualizacao Modular do SISTEMA SAV
# Versao: 05/04/2026-01
# Autor: Luiz Augusto
# Os programas usados por este script devem estar na pasts /libs.

set -euo pipefail # Configuracao de seguranca para o script
export LC_ALL=C

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
   printf "%s\n" "Aviso: Nao esta executando como root"
   printf "%s\n" "Alguns recursos podem exigir privilegios elevados"
   printf "\n"
fi

# Verificacoes basicas
if [[ ! -t 0 && ! -p /dev/stdin ]]; then
    printf "%s\n" "Este script deve ser executado interativamente" >&2
    exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Diretorio do script atual

# Diretorio do script SCRIPT_DIR
PLIBS_DIR="${SCRIPT_DIR}/libs" # Diretorio das bibliotecas
export PLIBS_DIR SCRIPT_DIR  # Define variaveis como somente leitura

# Garante que SCRIPT_DIR e PLIBS_DIR existam e tenham permissao 0777
if [[ ! -d "${SCRIPT_DIR}" ]]; then
    mkdir -p "${SCRIPT_DIR}" || {
        printf "%s\n" "ERRO: Nao foi possivel criar o diretorio ${SCRIPT_DIR}."
        exit 1
    }
fi

chmod -R 0777 "${SCRIPT_DIR}" 2>/dev/null || {
    printf "%s\n" "AVISO: Nao foi possivel ajustar permissao em ${SCRIPT_DIR}."
}

if [[ ! -d "${PLIBS_DIR}" ]]; then
    mkdir -p "${PLIBS_DIR}" || {
        printf "%s\n" "ERRO: Nao foi possivel criar o diretorio ${PLIBS_DIR}."
        exit 1
    }
fi

chmod 0777 "${PLIBS_DIR}" 2>/dev/null || {
    printf "%s\n" "AVISO: Nao foi possivel ajustar permissao em ${PLIBS_DIR}."
}

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
    exit 1
fi