#!/usr/bin/env bash
#
# auth.sh - Modulo de Autenticacao
# Responsavel pela autenticacao de usuarios
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 09/03/2026-01
# Autor: Luiz Augusto
#
#
# Variaveis globais esperadas
cfg_dir="${cfg_dir:-}"                 # Diretorio de configuracao

# Arquivo de senhas oculto
SENHA_FILE="${cfg_dir}/.senhas"

# Variavel global para armazenar o nome do usuario autenticado
declare -u usuario           # Variavel global para armazenar o nome do usuario autenticado

# Funcao para hash da senha
_hash_senha() {
    local senha="$1"
    echo -n "$senha" | sha256sum | cut -d' ' -f1
}

# Funcao para cadastrar usuario
_cadastrar_usuario() {
    local usuario senha senha_confirm hash_senha

    _mensagec "${RED}" "Cadastro de Usuario"
    _meia_linha "=" "${RED}"

    read -rp "${YELLOW}Digite o nome do usuario: ${NORM}" usuario
    usuario=$(echo "$usuario" | tr '[:lower:]' '[:upper:]')
    if [[ -z "$usuario" ]]; then
        _mensagec "${RED}" "Usuario nao pode ser vazio."
        return 1
    fi

    # Verificar se usuario ja existe
    if grep -q "^${usuario}:" "$SENHA_FILE" 2>/dev/null; then
        _mensagec "${RED}" "Usuario ja existe."
        return 1
    fi

    read -rsp "${YELLOW}Digite a senha: ${NORM}" senha
    printf "\n"
    read -rsp "${YELLOW}Confirme a senha: ${NORM}" senha_confirm
    printf "\n"

    if [[ "$senha" != "$senha_confirm" ]]; then
        _mensagec "${RED}" "Senhas nao coincidem."
        return 1
    fi

    if [[ -z "$senha" ]]; then
        _mensagec "${RED}" "Senha nao pode ser vazia."
        return 1
    fi

    hash_senha=$(_hash_senha "$senha")
    echo "${usuario}:${hash_senha}" >> "$SENHA_FILE"
    _mensagec "${GREEN}" "Usuario cadastrado com sucesso."
}

# Funcao para login
_login() {
    local senha hash_senha stored_hash
    # usuario is made global to be used in logging

    _mensagec "${RED}" "Login no Sistema"
    _linha "=" "${GREEN}"

    read -rp "${YELLOW}Usuario: ${NORM}" usuario
    usuario=$(echo "$usuario" | tr '[:lower:]' '[:upper:]')
    read -rsp "${YELLOW}Senha: ${NORM}" senha
    printf "\n"

    if [[ ! -f "$SENHA_FILE" ]]; then
        _mensagec "${RED}" "Nenhum usuario cadastrado. Execute o programa de cadastro primeiro."
        return 1
    fi

    # Verificar se o arquivo de senhas esta vazio
    if [[ ! -s "$SENHA_FILE" ]]; then
        _mensagec "${RED}" "ALERTA: Arquivo de senhas esta vazio. Nenhum usuario cadastrado no sistema."
        _mensagec "${YELLOW}" "Execute o programa de cadastro primeiro."
        _linha "-" "${RED}"

        return 1
    fi

    stored_hash=$(grep "^${usuario}:" "$SENHA_FILE" | cut -d':' -f2)
    if [[ -z "$stored_hash" ]]; then
        _mensagec "${RED}" "Usuario nao encontrado."
        _linha "-" "${RED}"
        return 1
    fi

    hash_senha=$(_hash_senha "$senha")
    if [[ "$hash_senha" == "$stored_hash" ]]; then
        _mensagec "${GREEN}" "Login bem-sucedido."
        export usuario
        return 0
    else
        _mensagec "${RED}" "Senha incorreta."
        _linha "-" "${RED}"
        printf "\n"
        # Clear usuario on failure
        unset usuario
        return 1
    fi
}    

# Funcao para alterar senha
_alterar_senha() {
    local senha_atual nova_senha confirm_senha hash_atual hash_nova stored_hash
    read -rp "Usuario: " usuario
    usuario=$(echo "$usuario" | tr '[:lower:]' '[:upper:]')
    if [[ -z "$usuario" ]]; then
        _mensagec "${RED}" "Voce precisa estar logado para alterar a senha."
        return 1
    fi

    _mensagec "${RED}" "Alteracao de Senha"
    _linha "=" "${RED}"

    read -rsp "${YELLOW}Digite a senha atual: ${NORM}" senha_atual
    printf "\n"

    # Verificar senha atual
    stored_hash=$(grep "^${usuario}:" "$SENHA_FILE" | cut -d':' -f2)
    if [[ -z "$stored_hash" ]]; then
        _mensagec "${RED}" "Usuario nao encontrado."
        _linha "-" "${RED}"
        return 1
    fi

    hash_atual=$(_hash_senha "$senha_atual")
    if [[ "$hash_atual" != "$stored_hash" ]]; then
        _mensagec "${RED}" "Senha atual incorreta."
        _linha "-" "${RED}"
        return 1
    fi

    read -rsp "${YELLOW}Digite a nova senha: ${NORM}" nova_senha
    printf "\n"
    read -rsp "${YELLOW}Confirme a nova senha: ${NORM}" confirm_senha
    printf "\n"

    if [[ "$nova_senha" != "$confirm_senha" ]]; then
        _mensagec "${RED}" "Novas senhas nao coincidem."
        return 1
    fi

    if [[ -z "$nova_senha" ]]; then
        _mensagec "${RED}" "Nova senha nao pode ser vazia."
        return 1
    fi

    hash_nova=$(_hash_senha "$nova_senha")
    # Atualizar a linha no arquivo
    sed -i "s/^${usuario}:.*/${usuario}:${hash_nova}/" "$SENHA_FILE"
    _mensagec "${GREEN}" "Senha alterada com sucesso."
}
