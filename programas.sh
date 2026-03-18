#!/usr/bin/env bash
#
# programas.sh - Modulo de Gestao de Programas
# Responsavel pela atualizacao, instalacao e reversao de programas
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 18/03/2026-00
#
# Variaveis globais esperadas
sistema="${sistema:-}"      # Nome do sistema (iscobol, savatu, transpc).
cmd_zip="${cmd_zip:-}"      # Comando de compactacao (zip)
cmd_unzip="${cmd_unzip:-}"  # Comando de descompactacao (unzip)
Offline="${Offline:-}"      # Modo offline (s/n)
down_dir="${down_dir:-}"    # Diretorio de download de arquivos
class="${class:-}"          # Sufixo para arquivos de classe
mclass="${mclass:-}"        # Sufixo para arquivos de classe de depuracao

#---------- VARIaVEIS GLOBAIS DO MODULO ----------#
# Arrays para armazenar programas e arquivos
declare -a PROGRAMAS_SELECIONADOS=()
declare -a ARQUIVOS_PROGRAMA=()


#---------- FUNCOES DE ATUALIZACAO ONLINE ----------#

# Atualizacao de programas via conexao online
_atualizar_programa_online() {
    if [[ "${Offline}" == "s" ]]; then
        _linha
        _mensagec "${YELLOW}" "Parametro do servidor OFF ativo"
        _linha
        _press
        return 1
    fi
    
    # Solicitar programas a serem atualizados
    _solicitar_programas_atualizacao
    
    if (( ${#ARQUIVOS_PROGRAMA[@]} == 0 )); then
        _mensagec "${YELLOW}" "Nenhum programa selecionado"
        _linha
        _press
        return 1
    fi
    
    # Baixar programas via vaievem
    _baixar_programas_vaievem
    
    # Atualizar programas baixados
    _processar_atualizacao_programas
    _linha
    _press
}

# Atualizacao de programas via arquivos offline
_atualizar_programa_offline() {

    # Solicitar programas a serem atualizados
    _solicitar_programas_atualizacao
    

    if (( ${#ARQUIVOS_PROGRAMA[@]} == 0 )); then
        _mensagec "${YELLOW}" "Nenhum programa selecionado"
        _linha
        _press
        return 1
    fi
    
    _linha
    _mensagec "${YELLOW}" "Os programas devem estar no diretorio ${WHITE}${down_dir}"
    _linha
    _read_sleep 1
    
    # Mover arquivos do servidor offline se configurado
    _mover_arquivos_offline
    
    # Atualizar programas
    _processar_atualizacao_programas
    _linha
    _press
}

# Atualizacao de programas em pacotes
_atualizar_programa_pacote() {
        _solicitar_pacotes_atualizacao
    if [[ "${Offline}" == "s" ]]; then
        _linha
        _mensagec "${YELLOW}" "Parametro do servidor OFF ativo"
        _mover_arquivos_offline
    else 
        _baixar_pacotes_vaievem
    fi
        _processar_atualizacao_pacotes
        _linha
        _press
}

#---------- FUNCOES DE REVERSaO ----------#

# Seleciona programas disponiveis para reversao (backups *-anterior.zip)
# Popula as variaveis globais PROGRAMAS_SELECIONADOS e ARQUIVOS_PROGRAMA
_selecionar_programas_reversao() {
    PROGRAMAS_SELECIONADOS=()
    ARQUIVOS_PROGRAMA=()

    if [[ ! -d "${OLDS}" ]]; then
        _mensagec "${RED}" "Diretorio de backups nao encontrado: ${OLDS}"
        _press
        return 1
    fi

    shopt -s nullglob
    local backups=("${OLDS}"/*-anterior.zip)
    shopt -u nullglob

    if (( ${#backups[@]} == 0 )); then
        _mensagec "${YELLOW}" "Nenhum backup de programa encontrado em ${OLDS}"
        _press
        return 1
    fi

    local programas=()
    for arquivo in "${backups[@]}"; do
        programas+=("$(basename "${arquivo}" "-anterior.zip")")
    done

    _linha
    _mensagec "${CYAN}" "Backups disponiveis para reversao:"
    _linha

    local idx=1
    for programa in "${programas[@]}"; do
        _mensagec "${GREEN}" "${idx}) ${programa}"
        ((idx++))
    done

    _linha
    _mensagec "${YELLOW}" "Digite o(s) numero(s) do(s) programa(s) a reverter (ex: 1 2 3) ou 0 para sair:"

    local escolha
    while true; do
        read -rp "${YELLOW}Opcao -> ${NORM}" escolha
        _linha

        # Tratar cancelamento
        if [[ -z "${escolha}" || "${escolha}" == "0" ]]; then
            _mensagec "${YELLOW}" "Operacao cancelada."
            return 1
        fi

        # Permitir lista separada por espacos e virgulas
        escolha="${escolha//,/ }"

        local -a indices=()
        local invalido=0
        for token in ${escolha}; do
            if ! [[ "${token}" =~ ^[0-9]+$ ]]; then
                invalido=1
                break
            fi
            if (( token < 1 || token > ${#programas[@]} )); then
                invalido=1
                break
            fi
            indices+=("${token}")
        done

        if (( invalido )); then
            _mensagec "${RED}" "Opcao invalida. Informe numero(s) entre 1 e ${#programas[@]}."
            continue
        fi

        # Remover duplicatas mantendo a ordem
        declare -A seen=()
        for token in "${indices[@]}"; do
            if [[ -n "${seen[$token]:-}" ]]; then
                continue
            fi
            seen[$token]=1
            local programa_selecionado="${programas[$((token-1))]}"
            PROGRAMAS_SELECIONADOS+=("${programa_selecionado}")
            ARQUIVOS_PROGRAMA+=("${programa_selecionado}${class}.zip")
        done

        break
    done

    return 0
}

# Reverter programas para versao anterior
_reverter_programa() {
    if _selecionar_programas_reversao; then
        _processar_reversao_programas
        _mensagem_conclusao_reversao
    else
        _mensagec "${RED}" "Nenhum programa foi selecionado para reversao"
        _linha
        _press
    fi
}

#---------- FUNCOES DE SOLICITACAO DE DADOS ----------#

# Solicita tipo de compilacao e define o nome do artefato selecionado
_resolver_arquivo_compilado() {
    local nome_item="$1"
    local tipo_compilacao

    _mensagec "${RED}" "Informe o tipo de compilacao (1 - Normal, 2 - Depuracao):"
    _linha

    read -rp "${YELLOW}Tipo de compilacao: ${NORM}" -n1 tipo_compilacao
    printf "\n"

    case "$tipo_compilacao" in
        1) ARQUIVO_COMPILADO_ATUAL="${nome_item}${class}.zip" ;;
        2) ARQUIVO_COMPILADO_ATUAL="${nome_item}${mclass}.zip" ;;
        *) return 1 ;;
    esac
}

_coletar_artefatos_atualizacao() {
    local rotulo_item="$1"
    local mensagem_item="$2"
    local mensagem_final="$3"
    local mensagem_lista="$4"
    local max_repeticoes=6
    local contador=0
    local item
    local arquivo_compilado

    PROGRAMAS_SELECIONADOS=()
    ARQUIVOS_PROGRAMA=()

    for ((contador = 1; contador <= max_repeticoes; contador++)); do
        _meiodatela
        _mensagec "${RED}" "$mensagem_item"
        _linha

        read -rp "${YELLOW}Nome do ${rotulo_item} (ENTER para finalizar): ${NORM}" item
        _linha

        if [[ -z "${item}" ]]; then
            _mensagec "${YELLOW}" "$mensagem_final"
            _linha
            break
        fi

        if ! _validar_nome_programa "$item"; then
            _mensagec "${RED}" "Erro: Nome invalido. Use apenas letras maiusculas e numeros."
            continue
        fi

        if ! _resolver_arquivo_compilado "$item"; then
            _mensagec "${RED}" "Erro: Opcao invalida. Digite 1 ou 2."
            continue
        fi

        arquivo_compilado="${ARQUIVO_COMPILADO_ATUAL}"
        PROGRAMAS_SELECIONADOS+=("$item")
        ARQUIVOS_PROGRAMA+=("$arquivo_compilado")

        _linha
        _mensagec "${GREEN}" "${rotulo_item^} adicionado: ${arquivo_compilado}"
        _linha

        if [[ -n "$mensagem_lista" ]]; then
            _mensagec "${YELLOW}" "$mensagem_lista"
            for arquivo in "${ARQUIVOS_PROGRAMA[@]}"; do
                _mensagec "${GREEN}" "  - $arquivo"
            done
        fi
    done
}

# Solicita programas para atualizacao
_solicitar_programas_atualizacao() {
    _coletar_artefatos_atualizacao \
        "programa" \
        "Informe o nome do programa a ser atualizado:" \
        "Finalizando selecao de programas..." \
        "Programas selecionados:"
}

# Solicita pacotes para atualizacao
_solicitar_pacotes_atualizacao() {
    _coletar_artefatos_atualizacao \
        "pacote" \
        "Informe o nome do pacote:" \
        "Finalizando selecao de pacotes..." \
        "Pacotes selecionados:"
}

#---------- FUNCOES DE DOWNLOAD ----------#


# Baixa pacotes para diretorio especifico
_baixar_pacotes_vaievem() {
    _configurar_acessos

    cd "${down_dir}" || {
        _mensagec "${RED}" "Erro: Diretorio $down_dir nao encontrado"
        _read_sleep 2
        return 1
    }

    _baixar_programas_vaievem
}

#---------- FUNCOES DE PROCESSAMENTO ----------#

# Move arquivos do servidor offline
_mover_arquivos_offline() {
    _configurar_acessos

#    cd "${down_dir}" || return 1
#    if [[ "${Offline}" == "s" ]]; then
        for arquivo in "${ARQUIVOS_PROGRAMA[@]}"; do
            if [[ -f "${down_dir}/${arquivo}" ]]; then
                _mensagec "${GREEN}" "Arquivo encontrado: ${arquivo}"
            else
                _mensagec "${RED}" "Arquivo nao encontrado: ${arquivo}"
            fi
            _linha
        done
#    fi
}

# Processa atualizacao dos programas
_processar_atualizacao_programas() {
    # Ir para o diretório RECEBE onde estão os arquivos baixados
    cd "${down_dir}" || return 1

    local arquivo         # Nome do arquivo
    local extensao        # Extensao do arquivo
    local backup_file     # Nome do arquivo de backup
    local programa_idx=0  # indice do programa no array

    # Verificar se arquivos existem
    for arquivo in "${ARQUIVOS_PROGRAMA[@]}"; do
        if [[ ! -f "${arquivo}" ]]; then
            _mensagec "${RED}" "Arquivo nao encontrado: ${arquivo}"
            return 1
        fi
    done

    # Criar backup dos programas antigos
    for programa_idx in "${!PROGRAMAS_SELECIONADOS[@]}"; do
        local programa="${PROGRAMAS_SELECIONADOS[$programa_idx]}"
        local arquivo_backup="${OLDS}/${programa}-anterior.zip"
        
        # Verificar se ja existe backup
        if [[ -f "$arquivo_backup" ]]; then
            mv -f "$arquivo_backup" "${OLDS}/${UMADATA}-${programa}-anterior.zip"
        fi
        
        _mensagec "${YELLOW}" "Salvando programa antigo: ${programa}"
        
        # Backup de arquivos .class
        if [[ -f "${E_EXEC}/${programa}.class" ]]; then
            "${cmd_zip}" -j "$arquivo_backup" "${E_EXEC}/${programa}"*.class
        fi
        
        # Backup de arquivos .int
        if [[ -f "${E_EXEC}/${programa}.int" ]]; then
            "${cmd_zip}" -j "$arquivo_backup" "${E_EXEC}/${programa}.int"
        fi
        
        # Backup de arquivos .TEL
        if [[ -f "${T_TELAS}/${programa}.TEL" ]]; then
            "${cmd_zip}" -j "$arquivo_backup" "${T_TELAS}/${programa}.TEL"
        fi
    done

    _linha
    _mensagec "${YELLOW}" "Backup dos programas efetuado"
    _linha
    _read_sleep 1

    # Descompactar e atualizar programas
    for arquivo in "${ARQUIVOS_PROGRAMA[@]}"; do
        if ! "${cmd_unzip}" -o "${arquivo}" >>"${LOG_ATU}"; then
            _mensagec "${RED}" "Erro ao descompactar ${arquivo}"
            continue
        fi
    done

# Mover arquivos para diretorios corretos
for extensao in ".class" ".int" ".TEL"; do
    if compgen -G "*${extensao}" >/dev/null; then
        for arquivo in *"${extensao}"; do
            if [[ "${extensao}" == ".TEL" ]]; then
                mv -f "${arquivo}" "${T_TELAS}/" >>"${LOG_ATU}" 2>&1
            else
                mv -f "${arquivo}" "${E_EXEC}/" >>"${LOG_ATU}" 2>&1
                # Verificar se o arquivo foi movido com sucesso
                if [[ ! -f "${E_EXEC}/${arquivo}" ]]; then
                    echo "ERRO: Falha ao mover ${arquivo} para ${E_EXEC}/" | tee -a "${LOG_ATU}"
                    echo "ERRO: Arquivo ${arquivo} nao encontrado no diretorio de destino" >&2
                    _mensagec "${RED}" "Arquivo ${arquivo} nao encontrado no diretorio de destino"
                    _mensagec "${YELLOW}" "Verifique o log de atualizacao em ${LOG_ATU} para mais detalhes."
                    _mensagec "${YELLOW}" "Use a opcao 4 de reversao para restaurar o programa anterior."
                else
                    echo "Arquivo ${arquivo} movido com sucesso para ${E_EXEC}/" >>"${LOG_ATU}"
                    _mensagec "${GREEN}" "Arquivo ${arquivo} movido com sucesso para ${E_EXEC}/"
                    _obter_data_arquivo "${arquivo}"
                fi
            fi
        done
    fi
done
    _linha
    _mensagec "${GREEN}" "Atualizando o(s) programa(s)..."
    _linha

    # Mover arquivos .zip para .bkp
    for arquivo in "${ARQUIVOS_PROGRAMA[@]}"; do
        if [[ -f "${arquivo}" ]]; then
            backup_file="${arquivo%.zip}.bkp"
            mv -f "${arquivo}" "${PROGS}/${backup_file}"
        fi
    done

    _mensagec "${GREEN}" "Alterando extensao da atualizacao"
    _linha
    _mensagec "${YELLOW}" "Atualizacao concluida com sucesso!"
}

# Processa atualizacao de pacotes
_processar_atualizacao_pacotes() {
    # Ir para o diretório onde estão os pacotes baixados
    cd "${down_dir}" || return 1
    
    _configurar_acessos
    # Descompactar pacotes
    for arquivo in "${ARQUIVOS_PROGRAMA[@]}"; do
        if [[ ! -f "${arquivo}" ]]; then
            _mensagec "${RED}" "Arquivo nao encontrado: ${arquivo}"
            _read_sleep 2
            continue
        fi

        if ! "${cmd_unzip}" -o "${arquivo}" >>"${LOG_ATU}"; then
            _mensagec "${RED}" "Erro ao descompactar ${arquivo}"
            _read_sleep 2
            continue
        fi
    done

    # Mover arquivos .zip para .bkp
    for arquivo in "${ARQUIVOS_PROGRAMA[@]}"; do
        if [[ -f "${arquivo}" ]]; then
            local backup_file="${arquivo%.zip}.bkp"
            mv -f "${arquivo}" "${PROGS}/${backup_file}"
        fi
    done

    # Processar arquivos .class encontrados
    find . -type f -name "*.class" | while read -r classfile; do
        local progname="${classfile##*/}" # Extrair nome do arquivo
        progname="${progname%%.class}"    # Remover extensao

        # Backup dos arquivos antigos
        if [[ "${sistema}" == "iscobol" ]]; then
            find "${E_EXEC}" -name "${progname}*.class" -exec "${cmd_zip}" -j "${OLDS}/${progname}-anterior.zip" {} + 2>/dev/null
        else
            find "${E_EXEC}" -name "${progname}*.int" -exec "${cmd_zip}" -j "${OLDS}/${progname}-anterior.zip" {} + 2>/dev/null
        fi

        # Backup de arquivos .TEL se existirem
        if [[ -f "${progname}.TEL" ]]; then
            find "${T_TELAS}" -name "${progname}*.TEL" -exec "${cmd_zip}" -j "${OLDS}/${progname}-anterior.zip" {} + 2>/dev/null
        fi

        # Mover novos arquivos
        mv -f "${progname}"*.class "${E_EXEC}/" >>"${LOG_ATU}" 2>&1
        if [[ -f "${progname}.TEL" ]]; then
            mv -f "${progname}"*.TEL "${T_TELAS}/" >>"${LOG_ATU}" 2>&1
        fi
    done
}

# Processa reversao de programas
_processar_reversao_programas() {
    # Criar diretório RECEBE se não existir
    [[ ! -d "${down_dir}" ]] && mkdir -p "${down_dir}"
    
    for programa_idx in "${!PROGRAMAS_SELECIONADOS[@]}"; do
        local programa="${PROGRAMAS_SELECIONADOS[$programa_idx]}"
        local arquivo_anterior="${OLDS}/${programa}-anterior.zip"
        
        if [[ -f "$arquivo_anterior" ]]; then
            mv -f "$arquivo_anterior" "${down_dir}/${programa}${class}.zip"
            _mensagec "${GREEN}" "Programa revertido: ${programa}"
        else
            _mensagec "${RED}" "Backup nao encontrado para: ${programa}"
        fi
    done

    # Processar atualizacao com os arquivos revertidos
    _processar_atualizacao_programas
}

#---------- FUNCOES AUXILIARES ----------#

# Obtem data de modificacao do arquivo
_obter_data_arquivo() {
    local arquivo="$1" # Nome do arquivo
    if [[ -f "${E_EXEC}/${arquivo}" ]]; then
        local data_modificacao
        data_modificacao=$(stat -c %y "${E_EXEC}/${arquivo}" 2>/dev/null)
        if [[ -n "$data_modificacao" ]]; then
            local data_formatada
            data_formatada=$(date -d "$data_modificacao" +"%d/%m/%Y %H:%M:%S" 2>/dev/null)
            _mensagec "${GREEN}" "Nome do programa: ${arquivo}"
            _mensagec "${YELLOW}" "Data do programa: ${data_formatada}"
        fi
    fi
}

# Mensagem de conclusao da reversao
_mensagem_conclusao_reversao() {
    _linha
    _mensagec "${YELLOW}" "Volta do(s) Programa(s) Concluida(s)"
    _linha
    _press
    _linha
    # Perguntar se deseja reverter mais programas
    printf "\n"
    if _confirmar "Deseja reverter mais algum programa?" "N"; then
        _reverter_programa
    fi
}
