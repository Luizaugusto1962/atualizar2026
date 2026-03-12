#!/usr/bin/env bash
#
# SISTEMA SAV - Script de Atualizacao Modular
# lembrete.sh - Modulo de Lembretes e Notas
# Versao: 10/03/2026-00
# Autor: Luiz Augusto
# utils.sh - Modulo de Utilitarios e Funcoes Auxiliares  
# Funcoes basicas para formatacao, mensagens, validacao e controle de fluxo
#
#---------- FUNcoES DE LEMBRETES ----------#
# Variaveis globais esperadas
cfg_dir="${cfg_dir:-}"          # Caminho do diretorio de configuracao do programa.

# Mostra menu de lembretes
# Escreve nova nota
_escrever_nova_nota() {
    clear
    _linha
    _mensagec "${YELLOW}" "Digite sua nota (pressione Ctrl+D para finalizar):"
    _linha

    local arquivo_notas="${cfg_dir}/lembrete"
    if cat >> "$arquivo_notas"; then
        _linha
        _mensagec "${YELLOW}" "Nota gravada com sucesso!"
        _read_sleep 2
    else
        _mensagec "${RED}" "Erro ao gravar nota"
        _read_sleep 2
    fi
}

# Mostra notas iniciais se existirem
_mostrar_notas_iniciais() {
    local nota_inicial="${cfg_dir}/lembrete"
    
    if [[ -f "$nota_inicial" && -s "$nota_inicial" ]]; then
        _visualizar_notas_arquivo "$nota_inicial"
    fi
}

# ---------- MENSAGEM DE ENTRADA ----------
# Gera ou edita a mensagem que sera exibida ao iniciar o programa
_gerar_aviso_entrada() {
    clear
    _linha
    _mensagec "${YELLOW}" "Digite a mensagem de entrada (Ctrl+D para finalizar):"
    _linha

    local arquivo_msg="${cfg_dir}/avisos"
    # sobrescreve o arquivo existente
    if cat > "$arquivo_msg"; then
        _linha
        _mensagec "${GREEN}" "Mensagem gravada com sucesso!"
        _read_sleep 2
    else
        _mensagec "${RED}" "Erro ao gravar mensagem"
        _read_sleep 2
    fi
}

# Edita nota existente
_editar_aviso_existente() {
    local arquivo_avisos="${cfg_dir}/avisos"
    
    clear
    if [[ -f "$arquivo_avisos" ]]; then
        if ! ${EDITOR:-nano} "$arquivo_avisos"; then
            _mensagec "${RED}" "Erro ao abrir editor!"
            _read_sleep 2
        fi
    else
        _mensagec "${YELLOW}" "Nenhuma mensagem de aviso encontrada para editar!"
        _read_sleep 2
    fi
}

# Exibe a mensagem de entrada e oferece opcao para excluir apos leitura
_mostrar_aviso() {
    local arquivo_msg="${cfg_dir}/avisos"
    if [[ -f "$arquivo_msg" && -s "$arquivo_msg" ]]; then
        clear
        _linha "=" "${CYAN}"
        _mensagec "${YELLOW}" "MENSAGEM DE ENTRADA"
        _linha "=" "${CYAN}"
        printf "\n"
        # exibicao simples, respeitando largura do terminal
        local cols
        cols=$(tput cols 2>/dev/null || echo 80)
        fold -s -w "$cols" < "$arquivo_msg"
        printf "\n"
        _linha
        if _confirmar "Excluir mensagem de entrada?" "N"; then
            rm -f "$arquivo_msg"
            _mensagec "${GREEN}" "Mensagem removida"
            _read_sleep 1
        fi
    fi
}

# Apaga manualmente a mensagem de entrada
_apagar_aviso_entrada() {
    local arquivo_msg="${cfg_dir}/avisos"
    if [[ ! -f "$arquivo_msg" ]]; then
        _mensagec "${YELLOW}" "Nenhuma mensagem de entrada encontrada!"
        _read_sleep 2
        return
    fi

    if _confirmar "Tem certeza que deseja apagar a mensagem de entrada?" "N"; then
        if rm -f "$arquivo_msg"; then
            _mensagec "${RED}" "Mensagem excluida com sucesso!"
        else
            _mensagec "${RED}" "Erro ao excluir mensagem"
        fi
        _read__read_sleep 2
    fi
}

# Visualiza arquivo de notas formatado
# Parametros: $1=arquivo_de_notas
_visualizar_notas_arquivo() {
    local arquivo="$1"
    local llinha

    # Largura dinamica do terminal (fallback 80)
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)

    # Ajuste para o prefixo "* - " e identacao
    local largura=$(( cols - 6 ))
    (( largura < 40 )) && largura=40

    if [[ ! -f "$arquivo" || ! -r "$arquivo" ]]; then
        _mensagec "${RED}" "Arquivo de notas nao encontrado ou ilegivel: $arquivo"
        _press
        return 1
    fi

    clear
    _linha "=" "${CYAN}"
    _mensagec "${YELLOW}" "LEMBRETES E NOTAS"
    _linha "=" "${CYAN}"
    printf "\n"

    while IFS= read -r llinha || [[ -n "$llinha" ]]; do
        # Ignora linhas vazias ou apenas com espacos
        [[ -z "${llinha//[[:space:]]/}" ]] && continue

        echo "$llinha" | fold -s -w "$largura" | {
            read -r primeira
            printf "* - %s\n" "$primeira"

            while IFS= read -r resto; do
                printf "    %s\n" "$resto"
            done
        }
    done < "$arquivo"

    printf "\n"
    _linha
    _press
}

# Edita nota existente
_editar_nota_existente() {
    local arquivo_notas="${cfg_dir}/lembrete"
    
    clear
    if [[ -f "$arquivo_notas" ]]; then
        if ! ${EDITOR:-nano} "$arquivo_notas"; then
            _mensagec "${RED}" "Erro ao abrir editor!"
            _read_sleep 2
        fi
    else
        _mensagec "${YELLOW}" "Nenhuma nota encontrada para editar!"
        _read_sleep 2
    fi
}

# Apaga nota existente
_apagar_nota_existente() {
    local arquivo_notas="${cfg_dir}/lembrete"
    
    if [[ ! -f "$arquivo_notas" ]]; then
        _mensagec "${YELLOW}" "Nenhuma nota encontrada para excluir!"
        _read_sleep 2
        return
    fi

    if _confirmar "Tem certeza que deseja apagar todas as notas?" "N"; then
        if rm -f "$arquivo_notas"; then
            _mensagec "${RED}" "Notas excluidas com sucesso!"
        else
            _mensagec "${RED}" "Erro ao excluir notas"
        fi
        _read_sleep 2
    fi
}