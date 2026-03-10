#!/usr/bin/env bash
#
# utils.sh - Modulo de Utilitarios e Funcoes Auxiliares  
# Funcoes basicas para formatacao, mensagens, validacao e controle de fluxo
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 09/03/2026-00

#---------- FUNCOES DE FORMATACAO DE TELA ----------#
# Variaveis globais esperadas
raiz="${raiz:-}"              # Diretorio raiz do sistema.

# Limpa a tela e posiciona cursor no centro
_meiodatela() {
    printf "\033c\033[10;10H\n"
}

# Exibe mensagem centralizada colorida
_mensagec() {
    local color="${1}"      # Cor da mensagem
    local message="${2}"    # Mensagem a ser exibida
    printf "%s%*s%s\n" "${color}" $(((${#message} + $(tput cols)) / 2)) "${message}" "${NORM}"
}

# Exibe mensagem alinhada à direita
# Parametros: $1=cor $2=mensagem  
_mensaged() {
    local color="${1}"
    local mensagem="${2}"
    local largura_terminal
    local largura_mensagem
    local posicao_inicio
    
    largura_terminal=$(tput cols)
    largura_mensagem=${#mensagem}
    posicao_inicio=$((largura_terminal - largura_mensagem))
    
    printf "%s%*s%s${NORM}\n" "${color}" "${posicao_inicio}" "" "$mensagem"
}

# Cria linha horizontal com caractere especificado
# Parametros: $1=caractere (opcional, padrao='-') $2=cor (opcional)
_linha() {
    local Traco="${1:--}"
    local CCC="${2:-}"
    local Espacos
    local linhas
    
    printf -v Espacos "%$(tput cols)s" ""
    linhas=${Espacos// /$Traco}
    printf "%s" "${CCC}"
    printf "%*s\n" $(((${#linhas} + COLUMNS) / 2)) "$linhas"
    printf "%s" "${NORM}"
}
# Cria meia linha horizontal com caractere especificado
# Parametros: $1=caractere (opcional, padrao='-') $2=cor (opcional)
_meia_linha() {
    local Traco="${1:--}"
    local CCC="${2:-}"
    local Espacos
    local linhas
    local largura=45
    local cols
    cols=$(tput cols)
    
    printf -v Espacos "%${largura}s" ""
    linhas=${Espacos// /$Traco}
    printf "%s" "${CCC}"
    printf "%*s\n" $(((cols + largura) / 2)) "$linhas"
    printf "%s" "${NORM}"
}
#---------- FUNcoES DE CONTROLE DE FLUXO ----------#

# Pausa a execucao por tempo especificado
# Parametros: $1=tempo_em_segundos
_read_sleep() {
    if [[ -z "${1}" ]]; then
        printf "Erro: Nenhum argumento passado para _read_sleep.\n"
        return 1
    fi

    if ! [[ "${1}" =~ ^[0-9.]+$ ]]; then
        printf "Erro: Argumento invalido para _read_sleep: %s\n" "${1}"
        return 1
    fi

    read -rt "${1}" <> <(:) || :
}

# Aguarda pressionar qualquer tecla com timeout
_press() {
    printf "%s" "${YELLOW}"
    printf "%*s\n" $(((36 + COLUMNS) / 2)) "<< ... Pressione qualquer tecla para continuar ... >>"
    printf "%s" "${NORM}"
    read -rt 15 || :
    tput sgr0
}

# Exibe mensagem de opcao invalida
_opinvalida() {
    _linha
    _mensagec "${RED}" "Opcao Invalida"
    _linha
}

#---------- FUNcoES DE VALIDAcaO ----------#

# Valida nome de programa (letras maiúsculas e números)
# Parametros: $1=nome_programa
# Retorna: 0=valido 1=invalido
_validar_nome_programa() {
    local programa="$1"
    [[ -n "$programa" && "$programa" =~ ^[A-Z0-9]+$ ]]
}

# Valida se diretorio existe e e acessivel
# Parametros: $1=caminho_diretorio
# Retorna: 0=valido 1=invalido
_validar_diretorio() {
    local dir="$1"
    [[ -n "$dir" && -d "$dir" && -r "$dir" ]]
}



# Solicita confirmacao S/N
# Parametros: $1=mensagem $2=padrao(S/N)
# Retorna: 0=sim 1=nao
_confirmar() {
    local mensagem="$1"
    local padrao="${2:-N}"
    local opcoes
    local resposta
    local tentativas=0
    local max_tentativas=3
    
    case "$padrao" in
        [Ss]) opcoes="[S/n]" ;;
        [Nn]) opcoes="[N/s]" ;;
        *) opcoes="[S/N]" ;;
    esac
    
    while (( tentativas < max_tentativas )); do
        read -rp "${YELLOW}${mensagem} ${opcoes}: ${NORM}" resposta
        
        # Se resposta vazia, usar padrao
        if [[ -z "$resposta" ]]; then
            resposta="$padrao"
        fi
        
        case "${resposta,,}" in
            s|sim) return 0 ;;
            n|nao) return 1 ;;
            *)
                _mensagec "${RED}" "Resposta invalida"
                ((tentativas++))
                ;;
        esac
    done

    _mensagec "${RED}" "Maximo de tentativas excedido"
    return 1
}

#---------- FUNcoES DE PROGRESSO ----------#

# Mostra progresso do backup com spinner animado e tempo decorrido
_mostrar_progresso_backup() {
    local pid="$1"
    local delay=0.2
    local spin=( "|" "/" "-" "\\" )
    local i=0
    local elapsed=0
    local msg="Processo em andamento"

    # Verifica se o processo ainda esta ativo
    if ! kill -0 "$pid" 2>/dev/null; then
        _mensagec "$YELLOW" "Iniciando..."
        sleep 1
        return
    fi

    # Oculta o cursor
    tput civis

    # Salva posicao do cursor
    tput sc
    printf "${YELLOW}%s... [${NORM}" "$msg"

    # Loop de animacao
    while kill -0 "$pid" 2>/dev/null; do
        tput rc  # Restaura posicao
        printf "${YELLOW}%s... [%3ds] ${NORM}${GREEN}%s${NORM}" \
            "$msg" "$elapsed" "${spin[i]}"
        ((i = (i + 1) % ${#spin[@]}))
        ((elapsed += 1))
        sleep "$delay"
    done

    # Mostra o cursor novamente
    tput cnorm

    # Mensagem final
    if wait "$pid" 2>/dev/null; then
        printf "\r${GREEN}%s... [Concluido] ${NORM}\n" "$msg"
    else
        printf "\r${RED}%s... [Falhou] ${NORM}\n" "$msg"
    fi
}

#---------- FUNcoES DE LOG ----------#

# Registra mensagem no log com timestamp
# Parametros: $1=mensagem $2=arquivo_log(opcional)
_log() {
    local mensagem="$1"
    local arquivo_log="${2:-$LOG_ATU}"
    local timestamp
    local user="${usuario:-SISTEMA}"
    
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "[%s] [%s] %s\n" "$timestamp" "$user" "$mensagem" >> "$arquivo_log" 2>/dev/null
}

# Registra erro no log
# Parametros: $1=mensagem_erro $2=arquivo_log(opcional)
_log_erro() {
    local erro="$1"
    local arquivo_log="${2:-$LOG_ATU}"
    
    _log "ERRO: $erro" "$arquivo_log"
}

# Registra sucesso no log  
# Parametros: $1=mensagem_sucesso $2=arquivo_log(opcional)
_log_sucesso() {
    local sucesso="$1"
    local arquivo_log="${2:-$LOG_ATU}"
    
    _log "SUCESSO: $sucesso" "$arquivo_log"
}

#---------- FUNCOES DE ARQUIVO ----------#

# Remove arquivos antigos de um diretorio
# Parametros: $1=diretorio $2=dias $3=padrao(opcional)
_limpar_arquivos_antigos() {
    local diretorio="$1"
    local dias="$2"
    local padrao="${3:-*}"
    local count
    
    if [[ ! -d "$diretorio" ]]; then
        _log_erro "Diretorio nao encontrado: $diretorio"
        return 1
    fi
    
    count=$(find "$diretorio" -name "$padrao" -type f -mtime +"$dias" -print | wc -l)
    
    if (( count > 0 )); then
        _log "Removendo $count arquivos antigos de $diretorio"
        find "$diretorio" -name "$padrao" -type f -mtime +"$dias" -delete
        return 0
    else
        _log "Nenhum arquivo antigo encontrado em $diretorio"
        return 0
    fi
}

#---------- FUNCOES DE INICIALIZACAO ----------#

# Executa limpeza automatica diaria
_executar_expurgador_diario() {
    local flag_file
    local savlog="${raiz}/portalsav/log"
    local err_isc="${raiz}/err_isc"
    local viewvix="${raiz}/savisc/viewvix/tmp"

    flag_file="${LOGS}/.expurgador_$(date +%Y%m%d)"
    
    # Se ja foi executado hoje, pular
    if [[ -f "$flag_file" ]]; then
        return 0
    fi
    
    # Remover flags antigas (mais de 3 dias)
    find "${LOGS}" -name ".expurgador_*" -mtime +3 -delete 2>/dev/null || true
    
    # Executar limpeza basica
    _limpar_arquivos_antigos "${LOGS}" 30 "*.log"
    _limpar_arquivos_antigos "${BACKUP}" 30 "*.*"
    _limpar_arquivos_antigos "${OLDS}" 30 "*.*"
    _limpar_arquivos_antigos "${savlog}" 30 "*.*"
    _limpar_arquivos_antigos "${err_isc}" 30 "*.*"
    _limpar_arquivos_antigos "${viewvix}" 30 "*.*"
    
    # Criar flag para hoje
    touch "$flag_file"
    
    _log "Limpeza automatica diaria executada"
    return 0
}

# Funcao para checar se o zip esta instalado
# Checa se os programas necessarios para o atualiza.sh estao instalados no sistema.
# Se o programa nao for encontrado, exibe uma mensagem de erro e sai do programa.
_check_instalado() {
    local app
    local missing=()
    # Mensagem de erro principal
    Z1="ERRO: Programa nao encontrado"  # Definir a mensagem

    for app in zip unzip rsync wget; do
        if ! command -v "$app" >/dev/null 2>&1; then
            missing+=("$app")

            # Mensagem de erro principal
            printf "\n"
            printf "%s" "${RED}"
            printf "%*s\n" $(((${#Z1} + COLUMNS) / 2)) "${Z1}"
            printf "%s" "${NORM}"

            printf "${YELLOW} O programa nao foi encontrado ->> ${NORM}%s\n" "$app"

            # Sugestao específica
            case "$app" in
                zip|unzip)
                    printf "  ${YELLOW}Sugestao:${NORM} Instale o zip e unzip.%s\n"
                    ;;
                rsync)
                    printf "  ${YELLOW}Sugestao:${NORM} Instale o rsync.%s\n"
                    ;;
                wget)
                    printf "  ${YELLOW}Sugestao:${NORM} Instale o wget.%s\n"
                    ;;
            esac
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        # Lista os programas ausentes sem espaço inicial indesejado
        printf -v missing_list "%s" "${missing[*]}"

        printf "${YELLOW}Instale os programas ausentes (%s) e tente novamente.${NORM}\n" "$missing_list"
        exit 1
    fi
}