#!/usr/bin/env bash
#
# cadastro.sh - Programa de Cadastro de Usuario
# Permite cadastrar usuarios e senhas para o sistema SAV
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 09/03/2026-01
# Autor: Luiz Augusto
#
#
# Variaveis globais esperadas
cfg_dir="${cfg_dir:-}"                 # Diretorio de configuracao
lib_dir="${lib_dir:-}"                 # Diretorio de modulos de biblioteca

# Diretorio do script principal
TOOLS_DIR="${TOOLS_DIR:-$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")}"

# Diretorios dos modulos e configuracoes
lib_dir="${lib_dir:-${TOOLS_DIR}/libs}"       # Diretorio dos modulos de biblioteca
cfg_dir="${cfg_dir:-${TOOLS_DIR}/cfg}"  

# Carregar modulos necessarios
"." "${lib_dir}/utils.sh" 2>/dev/null || { echo "Erro: utils.sh nao encontrado."; exit 1; }
"." "${lib_dir}/auth.sh" 2>/dev/null || { echo "Erro: auth.sh nao encontrado."; exit 1; }

# Cores para o menu
        RED=$(tput bold)$(tput setaf 1)          # Vermelho
        GREEN=$(tput bold)$(tput setaf 2)        # Verde
        YELLOW=$(tput bold)$(tput setaf 3)       # Amarelo
# Funcao principal
main() {
    while true; do
        tput clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Cadastro de Usuario - Sistema SAV"
        _linha "=" "${GREEN}"
        printf "\n"
        _mensagec "${YELLOW} 1. Cadastrar novo usuario"
        _mensagec "${YELLOW} 2. Alterar senha de usuario"
        _mensagec "${YELLOW} 0. Voltar"
        _linha "=" "${GREEN}"
        _mensagec "${GREEN}" "Digite o numero da opcao desejada e pressione ENTER." 
        read -rp "Escolha uma opcao: " opcao

        case "$opcao" in
            1)
                printf "\n"
                _cadastrar_usuario
                printf "\n"
                read -rp "Pressione ENTER para continuar..." -t 5
                ;;
            2)
                printf "\n"
                _alterar_senha
                printf "\n"
                read -rp "Pressione ENTER para continuar..." -t 5
                ;;
            0)
                clear
                exit 0
                ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

# Executar
main "$@"