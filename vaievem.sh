#!/usr/bin/env bash
#
# vaievem.sh - Modulo de Operacoes de Sincronizacao
# Responsavel por operacoes de download/upload via rsync, sftp e ssh
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 09/03/2026-00
#
#---------- CONFIGURACOES DE CONEXAO ----------#
#
# Variaveis globais esperadas
acessossh="${acessossh:-s}"                    # Acesso via SSH (s/n)
arquivo_enviar="${arquivo_enviar:-}"           # Arquivo a ser enviado (pode conter wildcard)
dir_origem="${dir_origem:-.}"                  # Diretorio de origem para upload
destino_remoto="${destino_remoto:-}"           # Destino remoto para upload (ex: /caminho/destino/)
destino_biblioteca="${destino_biblioteca:-}"   # Diretorio de destino da biblioteca no servidor
destino_server="${destino_server:-}"           # Diretorio do servidor de atualizacao
arquivos_encontrados=()                        # Array para armazenar arquivos encontrados para envio

#---------- FUNCOES AUXILIARES (BAIXO NIVEL) ----------#

# Download via SFTP com chave SSH configurada
# Parametros: $1=arquivo_remoto $2=destino_local(opcional, padrao=.)
_download_sftp_ssh() {
    local arquivo_remoto="$1"
    local destino_local="${2:-.}"

    if [[ -z "$arquivo_remoto" ]]; then
        _log_erro "Erro: Arquivo remoto nao especificado para SFTP SSH"
        return 1
    fi

    _log "Iniciando download SFTP com chave SSH: ${arquivo_remoto}"

    sftp sav_servidor <<EOF
get "${arquivo_remoto}" "${destino_local}"
quit
EOF

    local status=$?
    if (( status == 0 )); then
        _log_sucesso "Download SFTP SSH concluido: ${arquivo_remoto}"
    else
        _log_erro "Falha no download SFTP SSH: ${arquivo_remoto}"
    fi

    return $status
}

# Download via SCP com chave SSH configurada
# Parametros: $1=arquivo_remoto $2=destino_local(opcional) $3=servidor $4=porta $5=usuario
_download_scp() {
    local arquivo_remoto="$1"
    local destino_local="${2:-.}"
    local servidor="${3:-$ipserver}"
    local porta="${4:-$SERVER_PORTA}"
    local rem_user="${5:-$USUARIO}"

    if [[ -z "$arquivo_remoto" ]]; then
        _log_erro "Erro: Arquivo remoto nao especificado para SCP"
        return 1
    fi

    _log "Iniciando download SCP: ${arquivo_remoto}"

    if scp -P "$porta" "${rem_user}@${servidor}:${arquivo_remoto}" "$destino_local"; then
        _log_sucesso "Download SCP concluido: ${arquivo_remoto}"
        return 0
    else
        _log_erro "Falha no download SCP: ${arquivo_remoto}"
        return 1
    fi
}

# Upload via RSYNC
# Parametros: $1=arquivo_local $2=destino_remoto $3=servidor $4=porta $5=usuario
_upload_rsync() {
    local arquivo_local="$1"
    local destino_remoto="$2"
    local servidor="${3:-$ipserver}"
    local porta="${4:-$SERVER_PORTA}"
    local rem_user="${5:-$USUARIO}"

    if [[ -z "$arquivo_local" || -z "$destino_remoto" ]]; then
        _log_erro "Erro: Parametros obrigatorios nao informados para upload RSYNC"
        return 1
    fi

    if [[ ! -f "$arquivo_local" ]]; then
        _mensagec "${RED}" "Erro: Arquivo local nao encontrado: ${arquivo_local}"
        return 1
    fi

    _log "Iniciando upload RSYNC: ${arquivo_local}"

    local destino_completo="${rem_user}@${servidor}:${destino_remoto}"

    if rsync -avzP -e "ssh -p ${porta}" "$arquivo_local" "$destino_completo"; then
        _log_sucesso "Upload RSYNC concluido: ${arquivo_local}"
        return 0
    else
        _log_erro "Falha no upload RSYNC: ${arquivo_local}"
        return 1
    fi
}

#---------- FUNCOES DE DOWNLOAD (ALTO NIVEL) ----------#

# Download da biblioteca via SFTP/SCP (funcao principal)
_baixar_biblioteca_sincroniza() {
    _log "Iniciando download da biblioteca: ${SAVATU}${VERSAO}"

    # Criar diretorio de recebimento se nao existir
    if [[ ! -d "${RECEBE}" ]]; then
        if ! mkdir -p "${RECEBE}"; then
            _log_erro "Falha ao criar diretorio: ${RECEBE}"
            return 1
        fi
    fi

    # Usar subshell para nao alterar o diretorio do chamador
    (
        cd "${RECEBE}" || return 1

        if [[ "${acessossh}" == "s" ]]; then
            local src="${USUARIO}@${ipserver}:${destino_biblioteca}${SAVATU}${VERSAO}.zip"

            if sftp -P "$SERVER_PORTA" "${src}" "."; then
                _log_sucesso "Download da biblioteca concluido: ${SAVATU}${VERSAO}.zip"
                return 0
            else
                _log_erro "Falha no download da biblioteca: ${SAVATU}${VERSAO}.zip"
                return 1
            fi
        else
            _definir_variaveis_biblioteca

            local arquivos_update
            read -ra arquivos_update <<< "$(_obter_arquivos_atualizacao)"

            if [[ ${#arquivos_update[@]} -eq 0 ]]; then
                _mensagec "${RED}" "Erro: Nenhum arquivo de atualizacao encontrado"
                return 1
            fi

            for arquivo in "${arquivos_update[@]}"; do
                local src="${USUARIO}@${ipserver}:${destino_biblioteca}${arquivo}"

                if scp -P "$SERVER_PORTA" "${src}" "."; then
                    _log_sucesso "Download concluido: ${arquivo}"
                else
                    _log_erro "Falha no download: ${arquivo}"
                    return 1
                fi
            done

            return 0
        fi
    )
}

# Baixar programas via SFTP/SCP
_baixar_programas_vaievem() {
    # Criar diretorio RECEBE se nao existir
    if [[ ! -d "${RECEBE}" ]]; then
        if ! mkdir -p "${RECEBE}"; then
            _log_erro "Falha ao criar diretorio: ${RECEBE}"
            return 1
        fi
    fi

    if (( ${#ARQUIVOS_PROGRAMA[@]} == 0 )); then
        return 1
    fi

    _linha
    _mensagec "${YELLOW}" "Realizando sincronizacao dos arquivos..."

    # Usar subshell para nao alterar o diretorio do chamador
    (
        cd "${RECEBE}" || return 1

        for arquivo in "${ARQUIVOS_PROGRAMA[@]}"; do
            _linha
            _mensagec "${GREEN}" "Transferindo: $arquivo"
            _linha

            if [[ "${acessossh}" == "s" ]]; then
                _mensagec "${YELLOW}" "Informe a senha para o usuario remoto:"

                if ! _download_sftp_ssh "${destino_server}${arquivo}" "."; then
                    _mensagec "${RED}" "Falha no download: $arquivo"
                    continue
                fi
            else
                if ! _download_scp "${destino_server}${arquivo}" "."; then
                    _mensagec "${RED}" "Falha no download: $arquivo"
                    continue
                fi
            fi

            _linha

            # Verificar se arquivo foi baixado
            if [[ ! -f "$arquivo" || ! -s "$arquivo" ]]; then
                _mensagec "${RED}" "ERRO: Falha ao baixar '$arquivo'"
                _read_sleep 2
                continue
            fi

            if ! unzip -t "$arquivo" >/dev/null 2>&1; then
                _mensagec "${RED}" "ERRO: Arquivo corrompido: $arquivo"
                rm -f "$arquivo"
                _read_sleep 2
                continue
            fi

            _mensagec "${GREEN}" "Download concluido: $arquivo"
        done
    )
}

#---------- FUNCOES DE UPLOAD/ENVIO (ALTO NIVEL) ----------#

# Enviar arquivo(s) via RSYNC. Pode lidar com arquivos unicos ou multiplos usando wildcard.
_enviar_arquivo_multi() {
    # Validar variaveis globais necessarias
    if [[ -z "$arquivo_enviar" ]]; then
        _mensagec "${RED}" "Erro: Nenhum arquivo especificado para envio"
        _read_sleep 2
        return 1
    fi

    if [[ -z "${destino_remoto:-}" ]]; then
        _mensagec "${RED}" "Erro: Destino remoto nao especificado"
        _read_sleep 2
        return 1
    fi

    # Verificar se esta enviando multiplos arquivos ou apenas um
    if [[ "$arquivo_enviar" == *"*"* ]]; then
        # Enviar multiplos arquivos usando _upload_rsync
        local falhas_envio=0
        for arquivo_item in "${arquivos_encontrados[@]}"; do
            if ! _upload_rsync "$arquivo_item" "${destino_remoto}/"; then
                ((falhas_envio++))
            fi
        done
        if (( falhas_envio == 0 )); then
            _mensagec "${YELLOW}" "Arquivo(s) enviado(s) para \"${destino_remoto}\""
            _linha
            _read_sleep 3
        else
            _mensagec "${RED}" "Erro no envio de ${falhas_envio} arquivo(s)"
            _press
        fi
    else
        # Enviar arquivo unico usando _upload_rsync
        if _upload_rsync "${dir_origem}/${arquivo_enviar}" "${destino_remoto}"; then
            _mensagec "${YELLOW}" "Arquivo enviado para \"${destino_remoto}\""
            _linha
            _read_sleep 3
        else
            _mensagec "${RED}" "Erro no envio do arquivo"
            _press
        fi
    fi
}
