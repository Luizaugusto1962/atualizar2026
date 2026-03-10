#!/usr/bin/env bash
#
# help.sh - Sistema de Ajuda e Manual do Usuario
# Fornece documentacao completa e help contextual para o sistema
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 05/03/2026-01
#
# Variaveis globais esperadas
cfg_dir="${cfg_dir:-}"     # Diretorio de configuracoes

#---------- CONFIGURACOES DO SISTEMA DE AJUDA ----------#

# Arquivo de manual principal
MANUAL_FILE="${cfg_dir}/manual.txt"

# Exibe conteúdo com paginaçao automática
# Parâmetros: 
#   $1 = conteúdo para exibir
#   $2 = linhas por página (opcional, padrao: 25)
_exibir_paginado() {
    local conteudo="$1"
    local linhas_por_pagina="${2:-25}"
    local linha_atual=1
    local total_linhas
    
    # Se conteúdo vazio, lê do stdin
    if [[ -z "$conteudo" ]]; then
        conteudo=$(cat)
    fi
    
    total_linhas=$(echo "$conteudo" | wc -l)
    
    # Se conteúdo cabe em uma página, exibe direto
    if [[ $total_linhas -le $linhas_por_pagina ]]; then
        echo "$conteudo"
        return 0
    fi
    
    # Loop de paginaçao
    while [[ $linha_atual -le $total_linhas ]]; do
        # Exibe página atual
        echo "$conteudo" | sed -n "${linha_atual},$((linha_atual + linhas_por_pagina - 1))p"
        
        linha_atual=$((linha_atual + linhas_por_pagina))
        
        # Se ainda há mais conteúdo, solicita continuaçao
        if [[ $linha_atual -le $total_linhas ]]; then
            printf "\n"
            _linha "=" "${CYAN}"
            printf "%s" "${YELLOW}Pressione ENTER para continuar, 'q' para sair, 'a' para ver tudo: ${NORM}"
            read -rsn1 resposta
            
            case "${resposta,,}" in
                q)
                    echo ""
                    echo "${GREEN}Exibicao interrompida${NORM}"
                    return 0
                    ;;
                a)
                    # Exibe todo o resto sem pausa
                    echo ""
                    echo "$conteudo" | sed -n "${linha_atual},\$p"
                    return 0
                    ;;
                *)
                    # ENTER ou qualquer outra tecla continua
                    clear
                    ;;
            esac
        fi
    done
    
    return 0
}

#---------- FUNCAO PARA LER SECAO DO MANUAL ----------#

# Lê uma seçao específica do arquivo manual.txt
# Parâmetro: $1 = nome da seçao (ex: MENU_PRINCIPAL, MENU_PROGRAMAS)
_ler_secao_manual() {
    local secao="$1"
    local conteudo=""
    local linha_inicio
    local linha_fim
    
    if [[ ! -f "$MANUAL_FILE" ]]; then
        _mensagec "${RED}" "Arquivo manual.txt nao encontrado!"
        return 1
    fi
    
    # Encontra linha de início da seçao
    linha_inicio=$(grep -n "^\[${secao}\]$" "$MANUAL_FILE" | cut -d: -f1)
    
    if [[ -z "$linha_inicio" ]]; then
        _mensagec "${YELLOW}" "Seçao [$secao] nao encontrada no manual."
        return 1
    fi
    
    # Incrementa para pular a linha do marcador
    linha_inicio=$((linha_inicio + 1))
    
    # Encontra a proxima seçao apos a linha de início
    linha_fim=$(tail -n +${linha_inicio} "$MANUAL_FILE" | grep -n "^\[.*\]$" | head -1 | cut -d: -f1)
    
    if [[ -n "$linha_fim" ]]; then
        # Há outra seçao depois, lê até ela
        linha_fim=$((linha_inicio + linha_fim - 2))
        conteudo=$(sed -n "${linha_inicio},${linha_fim}p" "$MANUAL_FILE")
    else
        # É a última seçao, lê até o final
        conteudo=$(tail -n +${linha_inicio} "$MANUAL_FILE")
    fi
    
    echo "$conteudo"
    return 0
}

#---------- FUNCOES DE NAVEGACAO DO MANUAL ----------#

# Exibe o manual completo
_exibir_manual_completo() {
    if [[ ! -f "$MANUAL_FILE" ]]; then
        _mensagec "${RED}" "Arquivo manual.txt nao encontrado em: $MANUAL_FILE"
        _mensagec "${YELLOW}" "Crie o arquivo manual.txt no diretorio cfg/"
        _press
        return 1
    fi
    
    clear
    
    local linhas_por_pagina=25
    local total_linhas
    total_linhas=$(wc -l < "$MANUAL_FILE")
    local linha_atual=1
    
    while [[ $linha_atual -le $total_linhas ]]; do
        clear
        sed -n "${linha_atual},$((linha_atual + linhas_por_pagina - 1))p" "$MANUAL_FILE"
        
        linha_atual=$((linha_atual + linhas_por_pagina))
        
        if [[ $linha_atual -le $total_linhas ]]; then
            printf "\n"
            printf "%s\n" "--- Pressione ENTER para continuar ou 'q' para sair ---"
            read -r resposta
            
            case "${resposta,,}" in
                q)
                    break
                    ;;
                a)
                    clear
                    sed -n "${linha_atual},\$p" "$MANUAL_FILE"
                    break
                    ;;
                *)
                    # Continua
                    ;;
            esac  
        fi
    done
    return 0
}

# Exibe ajuda contextual baseada no menu atual
# Parametros: $1=contexto (principal, programas, biblioteca, etc)
_exibir_ajuda_contextual() {
    local contexto="${1:-principal}"
    local secao_nome=""
    local conteudo=""
    
    # Mapeia contexto para nome da seçao no manual.txt
    case "$contexto" in
        principal)
            secao_nome="MENU_PRINCIPAL"
            ;;
        programas)
            secao_nome="MENU_PROGRAMAS"
            ;;
        biblioteca)
            secao_nome="MENU_BIBLIOTECA"
            ;;
        arquivos)
            secao_nome="MENU_ARQUIVOS"
            ;;            
        ferramentas)
            secao_nome="MENU_FERRAMENTAS"
            ;;
        temporarios)
            secao_nome="MENU_TEMPORARIOS"
            ;;
        recuperacao)
            secao_nome="MENU_RECUPERACAO"
            ;;
        backup)
            secao_nome="MENU_BACKUP"
            ;;
        transferencia)
            secao_nome="MENU_TRANSFERENCIA"
            ;;
        setups)
            secao_nome="MENU_SETUPS"
            ;;
        lembretes)
            secao_nome="MENU_LEMBRETES"
            ;;
        aviso)
            secao_nome="MENU_AVISO"
            ;;  
        logs)
            secao_nome="MENU_LOGS"
            ;;
        *)
            secao_nome="MENU_PRINCIPAL"
            ;;
    esac
    
    clear
    _linha "=" "${CYAN}"
    _mensagec "${CYAN}" "AJUDA - ${contexto^^}"
    _linha "=" "${CYAN}"
    printf "\n"
    
    # Lê e exibe a seçao do manual
    if conteudo=$(_ler_secao_manual "$secao_nome"); then
        _exibir_paginado "$conteudo" 25
    else
        _mensagec "${YELLOW}" "Ajuda para '$contexto' nao disponível no momento."
        _mensagec "${YELLOW}" "Use 'M' para ver o manual completo."
    fi
    
    printf "\n"
    _linha "-" "${GREEN}"
    _mensagec "${YELLOW}" "Pressione qualquer tecla para voltar ou 'M' para manual completo"
    _linha "-" "${GREEN}"
    
    read -rsn1 resposta
    if [[ "${resposta,,}" == "m" ]]; then
        _exibir_manual_completo
    fi
}

#---------- CRIACAO DO MANUAL PADRAO ----------#

# Verifica se manual.txt existe, se nao, avisa o usuário
_verificar_manual() {
    if [[ ! -f "$MANUAL_FILE" ]]; then
        _linha "=" "${YELLOW}"
        _mensagec "${YELLOW}" "  AVISO: Arquivo manual.txt nao encontrado!"
        _linha "=" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "O arquivo manual.txt deve estar em: ${CYAN}$MANUAL_FILE${NORM}"
        printf "\n"
        _mensagec "${WHITE}" "Por favor, crie o arquivo manual.txt com o conteúdo"
        _mensagec "${WHITE}" "completo da documentaçao do sistema."
        printf "\n"
        _linha "=" "${YELLOW}"
        return 1
    fi
    return 0
}

#---------- ATALHO RAPIDO DE AJUDA ----------#

# Exibe menu rápido de ajuda
_ajuda_rapida() {
    local contexto="${1:-ajuda}"
    local secao_nome=""
    local conteudo=""
    
    # Mapeia contexto para nome da seçao no manual.txt
    case "$contexto" in
        ajuda)
            secao_nome="AJUDA_RAPIDA"
            ;;
        *)
            secao_nome="MENU_PRINCIPAL"
            ;;
    esac
    
    clear
    _linha "=" "${CYAN}"
    _mensagec "${CYAN}" "AJUDA - ${contexto^^}"
    _linha "=" "${CYAN}"
    printf "\n"
    
    # Lê e exibe a seçao do manual
    if conteudo=$(_ler_secao_manual "$secao_nome"); then
        _exibir_paginado "$conteudo" 25
    else
        _mensagec "${YELLOW}" "Ajuda para '$contexto' nao disponivel no momento."
        _mensagec "${YELLOW}" "Use 'M' para ver o manual completo."
    fi
    
    printf "\n"
    _linha "-" "${GREEN}"
    _mensagec "${YELLOW}" "Pressione qualquer tecla para voltar ou 'M' para manual completo"
    _linha "-" "${GREEN}"
    
    read -rsn1 resposta
    if [[ "${resposta,,}" == "m" ]]; then
        _exibir_manual_completo
    fi
}

_ajuda_no_geral() {
    local contexto="${1:-ajuda_no_geral}"
    local secao_nome=""
    local conteudo=""
    
    # Mapeia contexto para nome da seçao no manual.txt
    case "$contexto" in
        ajuda_no_geral)
            secao_nome="AJUDA_NO_GERAL"
            ;;
        *)
            secao_nome="MENU_PRINCIPAL"
            ;;
    esac
    
    clear
    _linha "=" "${CYAN}"
    _mensagec "${CYAN}" "AJUDA - ${contexto^^}"
    _linha "=" "${CYAN}"
    printf "\n"
    
    # Lê e exibe a seçao do manual
    if conteudo=$(_ler_secao_manual "$secao_nome"); then
        _exibir_paginado "$conteudo" 25
    else
        _mensagec "${YELLOW}" "Ajuda para '$contexto' nao disponivel no momento."
        _mensagec "${YELLOW}" "Use 'M' para ver o manual completo."
    fi
    
    printf "\n"
    _linha "-" "${GREEN}"
    _mensagec "${YELLOW}" "Pressione qualquer tecla para voltar ou 'M' para manual completo"
    _linha "-" "${GREEN}"
    
    read -rsn1 resposta
    if [[ "${resposta,,}" == "m" ]]; then
        _exibir_manual_completo
    fi
}

#---------- BUSCA NO MANUAL ----------#

# Busca termo no manual
_buscar_manual() {
    local termo=""
    
    if ! _verificar_manual; then
        _press
        return 1
    fi
    
    read -rp "${YELLOW}Termo para buscar: ${NORM}" termo
    
    if [[ -z "$termo" ]]; then
        _mensagec "${RED}" "Nenhum termo informado"
        return 1
    fi
    
    clear
    _linha "=" "${CYAN}"
    _mensagec "${CYAN}" "RESULTADOS DA BUSCA: $termo"
    _linha "=" "${CYAN}"
    printf "\n"
    
    # Buscar e destacar resultados
    if grep -in --color=always "$termo" "$MANUAL_FILE"; then
        printf "\n"
        _mensagec "${GREEN}" "Busca concluída"
    else
        _mensagec "${YELLOW}" "Nenhum resultado encontrado para: $termo"
    fi
    
    printf "\n"
    _press
}

#---------- EXPORTAR MANUAL ----------#

# Exporta manual para arquivo externo
_exportar_manual() {
    local destino="${1:-$TOOLS_DIR/manual_sav.txt}"
    
    if ! _verificar_manual; then
        _press
        return 1
    fi
    
    if cp "$MANUAL_FILE" "$destino"; then
        _mensagec "${GREEN}" "Manual exportado para: $destino"
    else
        _mensagec "${RED}" "Erro ao exportar manual"
        return 1
    fi
    
    _press
}


# Menu para selecionar contexto de ajuda
_menu_selecao_contexto() {
    clear
    _linha "=" "${CYAN}"
    _mensagec "${CYAN}" "SELECIONE O CONTEXTO"
    _linha "=" "${CYAN}"

    printf "\n"
    printf "%s\n" "${GREEN}1${NORM}  - Menu Principal"
    printf "%s\n" "${GREEN}2${NORM}  - Programas"
    printf "%s\n" "${GREEN}3${NORM}  - Biblioteca"
    printf "%s\n" "${GREEN}4${NORM}  - Ferramentas"
    printf "%s\n" "${GREEN}5${NORM}  - Temporários"
    printf "%s\n" "${GREEN}6${NORM}  - Recuperaçao"
    printf "%s\n" "${GREEN}7${NORM}  - Backup"
    printf "%s\n" "${GREEN}8${NORM}  - Transferência"
    printf "%s\n" "${GREEN}9${NORM}  - Setups"
    printf "%s\n" "${GREEN}10${NORM} - Lembretes"
    printf "\n"
    _linha "=" "${CYAN}"
    
    local opcao
    read -rp "${YELLOW}Opçao: ${NORM}" opcao
    
    case "$opcao" in
        1) _exibir_ajuda_contextual "principal" ;;
        2) _exibir_ajuda_contextual "programas" ;;
        3) _exibir_ajuda_contextual "biblioteca" ;;
        4) _exibir_ajuda_contextual "ferramentas" ;;
        5) _exibir_ajuda_contextual "temporarios" ;;
        6) _exibir_ajuda_contextual "recuperacao" ;;
        7) _exibir_ajuda_contextual "backup" ;;
        8) _exibir_ajuda_contextual "transferencia" ;;
        9) _exibir_ajuda_contextual "setups" ;;
        10) _exibir_ajuda_contextual "lembretes" ;;
        *) 
            _mensagec "${RED}" "Opcao invalida" 
            sleep 1 
            ;;
    esac
}
