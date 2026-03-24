#!/usr/bin/env bash
#
# backup.sh - Modulo do Sistema de Backup
# Responsavel por backup completo, incremental e restauracao
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 24/03/2026-01
# Autor: Luiz Augusto
#
# Variaveis globais esperadas
base="${base:-}"           # Caminho do diretorio da segunda base de dados.
Offline="${Offline:-}"     # Indicador de ambiente offline (s/n)
raiz="${raiz:-}"           # Caminho raiz do sistema.
empresa="${empresa:-}"     # Nome da empresa (usado para nomear backups)
ipserver="${ipserver:-}"   # Endereco IP do servidor de atualizacao 

#---------- FUNCOES PRINCIPAIS DE backup ----------#

# Executa backup do sistema
_executar_backup() {
    local base_trabalho
    local ano_agora
    ano_agora=$(date +%Y)

    # Validar comando de compactacao
    if [[ -z "$cmd_zip" ]]; then
        _mensagec "${RED}" "Erro: Comando de compactacao nao configurado"
        _read_sleep 3
        return 1
    fi

    if ! command -v "$cmd_zip" &>/dev/null; then
        _mensagec "${RED}" "Erro: Comando '$cmd_zip' nao encontrado no sistema"
        _read_sleep 3
        return 1
    fi

    # Escolher base se necessario
    if [[ -n "${base2}" ]]; then
        _menu_escolha_base || return 1
        # Verificar se base_trabalho foi realmente definida pelo menu
        if [[ -z "${base_trabalho}" ]]; then
            _mensagec "${RED}" "Erro: Base de trabalho nao foi selecionada"
            _read_sleep 3
            return 1
        fi
    else
        base_trabalho="${raiz}${base}"
    fi

    # Validar se o diretorio base existe
    if [[ ! -d "$base_trabalho" ]]; then
        _mensagec "${RED}" "Erro: Diretorio base '$base_trabalho' nao existe"
        _read_sleep 3
        return 1
    fi

    # Exportar para uso em subfuncoes
    export BASE_TRABALHO="$base_trabalho"

    # Verificar se o diretorio de backup existe
    if [[ ! -d "$BACKUP" ]]; then
        _mensagec "$YELLOW" "Diretorio de backups em $BACKUP, nao encontrado ..."
        _read_sleep 3
        return 1
    fi

    # Verificar espaco em disco
    if ! _verificar_espaco_disco "$BACKUP"; then
        _mensagec "$RED" "Espaco em disco insuficiente em $BACKUP"
        _read_sleep 3
        return 1
    fi

    # Escolher tipo de backup
    _menu_tipo_backup
    if [[ -z "$tipo_backup" ]]; then
        return 1
    fi

    # Variavel para armazenar PID do processo em background
    local backup_pid
    local nome_backup
    local caminho_backup

    # Verificar backups recentes
    if _verificar_backups_recentes; then
        if ! _confirmar "Ja existe backup recente. Deseja continuar?" "N"; then
            _mensagec "$RED" "Operacao cancelada"
            _read_sleep 3
            return 1
        fi
        _linha
        _mensagec "$YELLOW" "Sera criado backup adicional"
    fi

    # Mudar para diretorio base
    if ! _diretorio_trabalho; then
        _mensagec "${RED}" "Erro ao acessar diretorio de trabalho"
        _read_sleep 3
        return 1
    fi

    _linha
    _mensagec "$YELLOW" "Criando Backup da pasta: ${base_trabalho}..."

    # === LOGICA ESPECIAL PARA backup INCREMENTAL: PEDIR ENTRADA ANTES DO & ===
    if [[ "$tipo_backup" == "incremental" ]]; then
        local mes ano data_referencia

        _linha
        _mensagec "$YELLOW" "Digite o mes (01-12) e ano (Ex: $ano_agora) para o backup incremental:"
        _linha

        read -rp "${YELLOW}Mes (MM): ${NORM}" mes
        _linha
        read -rp "${YELLOW}Ano (AAAA): ${NORM}" ano
        _linha

        # Validar entrada
        if ! [[ "$mes" =~ ^(0[1-9]|1[0-2])$ ]] || ! [[ "$ano" =~ ^[0-9]{4}$ ]]; then
            _mensagec "$RED" "Mes ou ano invalido. Use formato MM (01-12) e YYYY."
            _read_sleep 2
            return 1
        fi

        # Validar ano nao seja muito antigo ou futuro
        if (( ano < 1990 || ano > ano_agora )); then
            _mensagec "$RED" "Ano fora do intervalo valido (1990-$ano_agora)"
            _read_sleep 2
            return 1
        fi

        data_referencia="${ano}-${mes}-01"
        local data_atual
        data_atual=$(date +%Y%m%d)
        local data_input
        data_input=$(date -d "$data_referencia" +%Y%m%d 2>/dev/null) || {
            _mensagec "$RED" "Data invalida."
            _read_sleep 2
            return 1
        }

        if [[ "$data_input" -gt "$data_atual" ]]; then
            _mensagec "$RED" "A data nao pode ser futura."
            _read_sleep 2
            return 1
        fi

        # Gerar nome do arquivo incremental incluindo o periodo de referencia
        # Formato: empresa_incremental_refAAAAMM_YYYYMMDDHHmm.zip
        nome_backup="${empresa}_${tipo_backup}_ref${ano}${mes}_$(date +%Y%m%d%H%M).zip"
        caminho_backup="${BACKUP}/${nome_backup}"

        # Executar o backup incremental em background
        _executar_backup_incremental "$caminho_backup" "$data_referencia" &
        backup_pid=$!

    else
        # Gerar nome do arquivo para backup completo
        nome_backup="${empresa}_${tipo_backup}_$(date +%Y%m%d%H%M).zip"
        caminho_backup="${BACKUP}/${nome_backup}"

        # Backup completo: executa diretamente em background
        _executar_backup_completo "$caminho_backup" &
        backup_pid=$!
    fi

    # Mostrar barra de progresso
    _mostrar_progresso_backup "$backup_pid"

    # Verificar resultado - aguardar processo terminar
    local resultado=0
    wait "$backup_pid" 2>/dev/null || resultado=$?

    if [[ $resultado -eq 0 ]] && [[ -f "$caminho_backup" ]]; then
        _finalizar_backup_sucesso "$nome_backup"
        
        # Limpeza automática de backups antigos
        _limpar_backups_antigos
    else
        _mensagec "$RED" "Erro ao criar backup"
        _read_sleep 3
        return 1
    fi

    # Perguntar sobre envio
    if _confirmar "Deseja enviar backup para servidor?" "N"; then
        _enviar_backup_servidor "$nome_backup"
    fi
}

# Restaura backup do sistema
_restaurar_backup() {
    # Seleciona o backup usando a rotina unica
    if ! _selecionar_backup; then
        return 1
    fi

    # Prossegue com a lógica de restauracao (completa ou parcial)
    if _confirmar "Deseja restaurar TODOS os arquivos do backup?" "N"; then
        _restaurar_backup_completo "$backup_selecionado"
    else
        _restaurar_arquivo_especifico "$backup_selecionado"
    fi
}


_enviar_backup_avulso() {
    # Seleciona o backup usando a rotina unica
    if ! _selecionar_backup; then
        return 1
    fi

    if [[ "${Offline}" == "s" ]]; then
        _mover_backup_offline "$nome_backup"
        return
    fi

    if _confirmar "Enviar backup via rede?" "S"; then
        _enviar_backup_rede "$nome_backup"
    fi
}

#---------- FUNCOES DE EXECUCAO DE BACKUP ----------#

# Executa backup completo
_executar_backup_completo() {
    local arquivo_destino="$1"
    
    if ! _diretorio_trabalho; then
        return 1
    fi
    
    if ! "$cmd_zip" "$arquivo_destino" ./*.* -x ./*.zip ./*.tar ./*.gz ./*.log ./*.tmp ./*.old >>"${LOG_ATU}" 2>&1; then
        _mensagec "${RED}" "Erro ao criar backup completo"
        [[ -f "$arquivo_destino" ]] && rm -f "$arquivo_destino"
        return 1
    fi
    
    # Verificar se o backup foi criado
    if [[ ! -f "$arquivo_destino" ]]; then
        _mensagec "${RED}" "Erro: Backup nao foi criado"
        _read_sleep 3
        return 1
    fi

    # SEGURANCA: Validar integridade imediatamente apos criacao
    if ! _validar_integridade_backup "$arquivo_destino"; then
        _mensagec "${RED}" "ERRO CRITICO: Backup criado mas invalido (corrompido)"
        rm -f "$arquivo_destino"
        return 1
    fi
    
    return 0
}

# Executa backup incremental (recebe data como parametro)
_executar_backup_incremental() {
    local arquivo_destino="$1"
    local data_referencia="$2"
    local arquivos_temp
    local resultado

    # Validar data antes de usar
    if ! date -d "$data_referencia" >/dev/null 2>&1; then
        _mensagec "${RED}" "Data invalida: $data_referencia"
        return 1
    fi

    if ! _diretorio_trabalho; then
        return 1
    fi

    # Criar arquivo temporario para lista de arquivos
    arquivos_temp=$(mktemp) || {
        _mensagec "${RED}" "Erro ao criar arquivo temporario"
        _read_sleep 3
        return 1
    }

    # Buscar arquivos modificados
    find . -type f -newermt "$data_referencia" \
         ! -name "*.zip" ! -name "*.tar" ! -name "*.log" ! -name "*.tmp" ! -name "*.gz" ! -name "*.old" -print0 > "$arquivos_temp"

    # Verificar se encontrou arquivos
    if [[ ! -s "$arquivos_temp" ]]; then
        _mensagec "${YELLOW}" "Nenhum arquivo modificado desde $data_referencia"
        rm -f "$arquivos_temp"
        return 1
    fi

    # Executar compactacao
    if ! xargs -0 "$cmd_zip" "$arquivo_destino" < "$arquivos_temp" >>"${LOG_ATU}" 2>&1; then
        _mensagec "${RED}" "Erro ao criar backup incremental"
        rm -f "$arquivos_temp" "$arquivo_destino"
        return 1
    fi
    
    # Limpar arquivo temporario
    rm -f "$arquivos_temp"

    # Verificar se o backup foi criado
    if [[ ! -f "$arquivo_destino" ]]; then
        _mensagec "${RED}" "Erro: Backup nao foi criado"
        _read_sleep 3
        return 1
    fi

    # SEGURANCA: Validar integridade imediatamente apos criacao
    if ! _validar_integridade_backup "$arquivo_destino"; then
        _mensagec "${RED}" "ERRO CRITICO: Backup criado mas invalido (corrompido)"
        rm -f "$arquivo_destino"
        return 1
    fi
    
    return 0

}
# Muda para o diretorio de trabalho
_diretorio_trabalho() {
    local base_trabalho="${BASE_TRABALHO:-${raiz}${base}}"
    
    if [[ ! -d "$base_trabalho" ]]; then
        _mensagec "${RED}" "Erro: Diretorio ${base_trabalho} nao encontrado"
        _read_sleep 3
        return 1
    fi
    
    cd "$base_trabalho" || {
        _mensagec "${RED}" "Erro: Nao foi possivel acessar ${base_trabalho}"
        _read_sleep 3
        return 1
    }
    
    return 0
}

#---------- ROTINA UNICA DE SELECAO DE BACKUP ----------#
# Função centralizada para listar e selecionar backups
# Define as variaveis globais: backup_selecionado e nome_backup
_selecionar_backup() {
    local arquivos_backup=()

    # Carrega todos os .zip disponiveis
    shopt -s nullglob
    arquivos_backup=("${BACKUP}/${empresa}"_*.zip)

    if ((${#arquivos_backup[@]} == 0)); then
        _mensagec "${RED}" "Nenhum backup (${empresa}_*.zip) encontrado"
        _press
        return 1
    fi

    # Ordenar o array em ordem reversa para corresponder à exibicao
    mapfile -t arquivos_backup < <(printf '%s\n' "${arquivos_backup[@]}" | sort -r)

    _linha
    _mensagec "${CYAN}" "Backups disponiveis (${#arquivos_backup[@]}):"
    _linha

    # Mostra lista numerada
    printf '%s\n' "${arquivos_backup[@]}" | nl -w2 -s') '
    _linha

    if ((${#arquivos_backup[@]} == 1)); then
        local nome_unico
        nome_unico=$(basename "${arquivos_backup[0]}")
        if _confirmar "Usar o unico backup encontrado? ${CYAN}${nome_unico}${YELLOW}" "S"; then
            backup_selecionado="${arquivos_backup[0]}"
        else
            _mensagec "${YELLOW}" "Operacao cancelada."
            return 1
        fi
    else
        # Escolha interativa com cancelar explicito (0)
        echo -e "${CYAN}Escolha o numero do backup (ou 0 para cancelar):${NORM}"
        echo -e "${YELLOW}0) Cancelar${NORM}"
        echo ""

        while true; do
            read -rp "${YELLOW}Opcao -> ${NORM}" REPLY
            echo ""

            if [[ "$REPLY" == "0" || -z "$REPLY" ]]; then
                _mensagec "${YELLOW}" "Operacao cancelada."
                return 1
            fi

            if [[ ! "$REPLY" =~ ^[0-9]+$ ]]; then
                _mensagec "${RED}" "Digite apenas o numero."
                continue
            fi

            # Agora o indice corresponde corretamente à lista exibida
            local idx=$((REPLY - 1))
            if (( idx >= 0 && idx < ${#arquivos_backup[@]} )); then
                backup_selecionado="${arquivos_backup[$idx]}"
                break
            else
                _mensagec "${RED}" "Numero invalido. Use 1 a ${#arquivos_backup[@]} ou 0 para cancelar."
            fi
        done
    fi

    # Define o nome do backup selecionado (variavel global)
    nome_backup=$(basename "$backup_selecionado")
    _mensagec "${GREEN}" "Selecionado: $nome_backup"
    _linha

    return 0
}

#---------- FUNCOES DE RESTAURACAO ----------#

# Restaura backup completo
_restaurar_backup_completo() {
    local arquivo_backup="$1"
    local base_trabalho="${raiz}${base}"
    
    if [[ ! -f "$arquivo_backup" ]]; then
        _mensagec "${RED}" "Erro: Arquivo de backup nao encontrado"
        _auditar_restauracao "$arquivo_backup" "completa" "erro_arquivo_nao_existe"
        _press
        return 1
    fi
    
    # SEGURANCA: Validar integridade ANTES de restaurar
    if ! _validar_integridade_backup "$arquivo_backup"; then
        _auditar_restauracao "$arquivo_backup" "completa" "erro_integridade"
        _mensagec "${RED}" "OPERACAO ABORTADA: Backup invalido ou corrompido"
        _press
        return 1
    fi
    
    _linha
    _mensagec "${YELLOW}" "Restaurando todos os arquivos..."
    _linha
    
    if ! "${cmd_unzip:-unzip}" -o "$arquivo_backup" -d "${base_trabalho}" >>"${LOG_ATU}" 2>&1; then
        _mensagec "${RED}" "Erro na restauracao completa"
        _auditar_restauracao "$arquivo_backup" "completa" "erro_descompactacao"
        _press
        return 1
    fi
    
    _mensagec "${GREEN}" "Restauracao completa concluida"
    _auditar_restauracao "$arquivo_backup" "completa" "sucesso"
    _press
}

# Restaura(s) arquivo(s) especifico(s)
_restaurar_arquivo_especifico() {
    local arquivo_backup="$1"
    local nome_arquivo
    local base_trabalho="${raiz}${base}"
    local continuar
   
    if [[ ! -f "$arquivo_backup" ]]; then
        _mensagec "${RED}" "Erro: Arquivo de backup nao encontrado"
        _auditar_restauracao "$arquivo_backup" "parcial" "erro_arquivo_nao_existe"
        _press
        return 1
    fi

    # SEGURANCA: Validar integridade ANTES de restaurar
    if ! _validar_integridade_backup "$arquivo_backup"; then
        _auditar_restauracao "$arquivo_backup" "parcial" "erro_integridade"
        _mensagec "${RED}" "OPERACAO ABORTADA: Backup invalido ou corrompido"
        _press
        return 1
    fi
   
    while true; do
        read -rp "${YELLOW}Nome do arquivo (maiusculo, sem extensao): ${NORM}" nome_arquivo
       
        if [[ -z "$nome_arquivo" ]]; then
            _mensagec "${RED}" "Nome nao informado"
            _press
            _linha
            # Pergunta se deseja continuar mesmo após erro
            read -rp "${YELLOW}Deseja restaurar mais arquivos? (S/N): ${NORM}" continuar
            if [[ ! "$continuar" =~ ^[Ss]$ ]]; then
                return 0  # Sai da funcao se ncao quiser continuar
            fi
            continue  # Volta ao loop para novo nome
        fi
       
        if [[ ! "$nome_arquivo" =~ ^[A-Z0-9]+$ ]]; then
            _mensagec "${RED}" "Nome de arquivo invalido"
            _press
            _linha
            # Pergunta se deseja continuar mesmo após erro
            read -rp "${YELLOW}Deseja restaurar mais arquivos? (S/N): ${NORM}" continuar
            if [[ ! "$continuar" =~ ^[Ss]$ ]]; then
                return 0  # Sai da funcao se nao quiser continuar
            fi
            continue  # Volta ao loop para novo nome
        fi
       
        _linha
        _mensagec "${YELLOW}" "Restaurando ${nome_arquivo}..."
        _linha
       
        if ! "${cmd_unzip:-unzip}" -o "$arquivo_backup" "${nome_arquivo}*.*" -d "${base_trabalho}" >>"${LOG_ATU}" 2>&1; then
            _mensagec "${RED}" "Erro ao extrair ${nome_arquivo}"
            _auditar_restauracao "${arquivo_backup}:${nome_arquivo}" "parcial" "erro_descompactacao"
            _press
        else
            if ls "${base_trabalho}/${nome_arquivo}"*.* >/dev/null 2>&1; then
                _mensagec "${GREEN}" "Arquivo ${nome_arquivo} restaurado com sucesso"
                _auditar_restauracao "${arquivo_backup}:${nome_arquivo}" "parcial" "sucesso"
            else
                _mensagec "${YELLOW}" "Arquivo ${nome_arquivo} nao encontrado apos restauracao"
                _auditar_restauracao "${arquivo_backup}:${nome_arquivo}" "parcial" "arquivo_nao_existe_no_backup"
            fi
            _press
        fi
        _linha
        # Pergunta se deseja continuar (apenas após uma tentativa de restauracao)
        read -rp "${YELLOW}Deseja restaurar mais arquivos? (S/N): ${NORM}" continuar
        if [[ ! "$continuar" =~ ^[Ss]$ ]]; then
            _mensagec "${GREEN}" "Restauracoes finalizadas."
            return 0  # Sai da funcao com sucesso
        fi
    done
}


#---------- FUNCOES DE ENVIO ----------#

# Envia backup para servidor
_enviar_backup_servidor() {
    local nome_backup="$1"
    local destino_remoto

    # Validar se arquivo existe
    if [[ ! -f "${BACKUP}/${nome_backup}" ]]; then
        _mensagec "${RED}" "Erro: Arquivo de backup nao encontrado"
        _read_sleep 3
        return 1
    fi

    # SEGURANCA: Validar integridade ANTES de enviar
    if ! _validar_integridade_backup "${BACKUP}/${nome_backup}"; then
        _mensagec "${RED}" "OPERACAO ABORTADA: Backup invalido para envio"
        _read_sleep 3
        return 1
    fi

    # Determinar destino
    if [[ -n "${enviabackup}" ]]; then
        destino_remoto="${enviabackup}"
    else
        read -rp "${YELLOW}Diretorio de destino no servidor: ${NORM}" destino_remoto
        while [[ -z "$destino_remoto" ]]; do
            _mensagec "$RED" "Diretorio nao pode estar vazio"
            read -rp "${YELLOW}Diretorio de destino: ${NORM}" destino_remoto
        done
    fi

    _linha
    _mensagec "${YELLOW}" "Enviando backup para ${destino_remoto}..."
    _linha
    
    if _upload_rsync "${BACKUP}/${nome_backup}" "/${destino_remoto}"; then
        _linha
        _mensagec "${GREEN}" "Backup enviado com sucesso para \"${destino_remoto}\""
        _linha
        _auditar_restauracao "${nome_backup}" "envio_servidor" "sucesso"
        
        # Perguntar sobre manter backup local
        if _confirmar "Manter backup local?" "S"; then
            _mensagec "${YELLOW}" "Backup local mantido"
            _read_sleep 2
        else
            if rm -f "${BACKUP}/${nome_backup}"; then
                _mensagec "${YELLOW}" "Backup local excluido"
                _read_sleep 2
            else
                _mensagec "${RED}" "Erro ao excluir backup local"
                _read_sleep 2
            fi
        fi
    else
        _linha
        _mensagec "${RED}" "Erro ao enviar backup"
        _auditar_restauracao "${nome_backup}" "envio_servidor" "erro"
        _read_sleep 3
        return 1
    fi
}

# Move backup para diretorio offline
_mover_backup_offline() {
    local nome_backup="$1"
    
    # Validar se arquivo existe
    if [[ ! -f "${BACKUP}/${nome_backup}" ]]; then
        _mensagec "${RED}" "Erro: Arquivo de backup nao encontrado"
        _auditar_restauracao "${nome_backup}" "mover_offline" "erro_arquivo_nao_existe"
        _press
        return 1
    fi

    # SEGURANCA: Validar integridade ANTES de mover
    if ! _validar_integridade_backup "${BACKUP}/${nome_backup}"; then
        _mensagec "${RED}" "OPERACAO ABORTADA: Backup invalido para mover"
        _auditar_restauracao "${nome_backup}" "mover_offline" "erro_integridade"
        _press
        return 1
    fi
    
    _linha
    _mensagec "${YELLOW}" "Movendo backup para diretorio offline..."
    _linha
    
    if [[ -z "${down_dir}" ]]; then
        _mensagec "${RED}" "Diretorio offline nao configurado"
        _auditar_restauracao "${nome_backup}" "mover_offline" "erro_diretorio_nao_config"
        _press
        return 1
    fi

    # Criar diretorio offline se nao existir
    if [[ ! -d "${down_dir}" ]]; then
        if ! mkdir -p "${down_dir}"; then
            _mensagec "${RED}" "Erro ao criar diretorio offline"
            _auditar_restauracao "${nome_backup}" "mover_offline" "erro_criar_diretorio"
            _press
            return 1
        fi
    fi
    
    if mv -f "${BACKUP}/${nome_backup}" "$down_dir"; then
        _mensagec "${GREEN}" "Backup movido para: ${down_dir}"
        _auditar_restauracao "${nome_backup}" "mover_offline" "sucesso"
        _press
    else
        _mensagec "${RED}" "Erro ao mover backup"
        _auditar_restauracao "${nome_backup}" "mover_offline" "erro_mover"
        _press
        return 1
    fi
}

# Envia backup via rede
_enviar_backup_rede() {
    local nome_backup="$1"
    local destino_remoto
    
    # Validar se arquivo existe
    if [[ ! -f "${BACKUP}/${nome_backup}" ]]; then
        _mensagec "${RED}" "Erro: Arquivo de backup nao encontrado"
        _press
        return 1
    fi
    
    if [[ -n "${enviabackup}" ]]; then
        destino_remoto="${enviabackup}"
    else
        read -rp "${YELLOW}Diretorio remoto: ${NORM}" destino_remoto
        while [[ -z "$destino_remoto" ]]; do
            _mensagec "$RED" "Diretorio nao informado"
            read -rp "${YELLOW}Diretorio remoto: ${NORM}" destino_remoto
        done
    fi

    _linha
    _mensagec "${YELLOW}" "Enviando backup para ${destino_remoto}..."
    _linha
    
    if _upload_rsync "${BACKUP}/${nome_backup}" "/${destino_remoto}"; then
        _linha
        _mensagec "${GREEN}" "Backup enviado para \"${destino_remoto}\" no servidor ${ipserver}"
        _read_sleep 3
    else
        _linha
        _mensagec "${RED}" "Erro ao enviar backup via vaievem"
        _press
        return 1
    fi
}

#---------- FUNCOES AUXILIARES ----------#

# Valida integridade de arquivo de backup
_validar_integridade_backup() {
    local arquivo_backup="$1"

    # Verificar se arquivo existe
    if [[ ! -f "${arquivo_backup}" ]]; then
        _mensagec "${RED}" "ERRO: Arquivo de backup nao encontrado: ${arquivo_backup}"
        return 1
    fi

    # Verificar tamanho minimo (arquivo zip deve ter pelo menos 22 bytes)
    local tamanho
    tamanho=$(stat -c%s "${arquivo_backup}" 2>/dev/null)
    if (( tamanho < 22 )); then
        _mensagec "${RED}" "ERRO: Arquivo de backup corrompido (tamanho: ${tamanho} bytes): ${arquivo_backup}"
        return 1
    fi

    # Testar integridade do arquivo zip
    if ! "${cmd_unzip:-unzip}" -t "${arquivo_backup}" >/dev/null 2>&1; then
        _mensagec "${RED}" "ERRO: Arquivo de backup invalido ou corrompido: ${arquivo_backup}"
        return 1
    fi

    return 0
}

# Registra auditoria de restauracao
_auditar_restauracao() {
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local usuario="${LOGNAME:-usuario_desconhecido}"
#    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local arquivo="$1"
    local tipo="$2"  # completa ou parcial
    local resultado="$3"  # sucesso ou erro
    local log_auditoria="${LOG_ATU%.log}_audit.log"

    printf "[%s] Usuario: %s | Tipo: %s | Resultado: %s | Arquivo: %s\n" \
        "${timestamp}" "${usuario}" "${tipo}" "${resultado}" "${arquivo}" >> "${log_auditoria}"
}

# Verifica espaco em disco
_verificar_espaco_disco() {
    local diretorio="$1"
    local espaco_minimo=1048576  # 1GB em KB
    local espaco_disponivel
    
    espaco_disponivel=$(df -k "$diretorio" 2>/dev/null | awk 'NR==2 {print $4}')
    
    if [[ -z "$espaco_disponivel" ]] || (( espaco_disponivel < espaco_minimo )); then
        return 1
    fi
    
    return 0
}

# Verifica backups recentes (ultimos 2 dias)
_verificar_backups_recentes() {
    if find "${BACKUP}" -maxdepth 1 -ctime -2 -name "${empresa}_*.zip" -print -quit | grep -q .; then
        _linha
        _mensagec "$CYAN" "Ja existe backup recente em $BACKUP:"
        _linha
        ls -ltrh "${BACKUP}/${empresa}"_*.zip 2>/dev/null
        _linha
        return 0
    fi
    return 1
}

# Limpa backups antigos (mantém últimos 10)
_limpar_backups_antigos() {
    local max_backups=10
    local backups_para_limpar
    
    if [[ ! -d "${BACKUP}" ]]; then
        return 0
    fi
    
    # Contar backups existentes
    local total_backups
    total_backups=$(find "${BACKUP}" -maxdepth 1 -name "${empresa}_*.zip" -type f | wc -l)
    
    if (( total_backups <= max_backups )); then
        return 0
    fi
    
    # Remover backups antigos, mantendo apenas os últimos max_backups
    backups_para_limpar=$(find "${BACKUP}" -maxdepth 1 -name "${empresa}_*.zip" -type f -printf '%T+ %p\n' | \
        sort -r | tail -n +$((max_backups + 1)) | cut -d' ' -f2-)
    
    while IFS= read -r arquivo; do
        [[ -z "$arquivo" ]] && continue
        
        if rm -f "$arquivo"; then
            _mensagec "${YELLOW}" "Backup antigo removido: $(basename "$arquivo")"
        else
            _mensagec "${RED}" "Erro ao remover backup antigo: $(basename "$arquivo")"
        fi
    done <<< "$backups_para_limpar"
}

# Finaliza backup com sucesso
_finalizar_backup_sucesso() {
    local nome_backup="$1"
    local tamanho_backup
    
    if [[ -f "${BACKUP}/${nome_backup}" ]]; then
        tamanho_backup=$(du -h "${BACKUP}/${nome_backup}" | cut -f1)
        _linha
        _mensagec "$GREEN" "Backup Concluido!"
        _linha
        _mensagec "$YELLOW" "Arquivo: $nome_backup"
        _mensagec "$YELLOW" "Local: ${BACKUP}"
        _mensagec "$YELLOW" "Tamanho: ${tamanho_backup}"
        _linha
    else
        _mensagec "$YELLOW" "O backup $nome_backup foi criado em ${BACKUP}"
        _linha
        _mensagec "$YELLOW" "Backup Concluido!"
        _linha
    fi
}
