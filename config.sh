#!/usr/bin/env bash
#
# config.sh - Modulo de Configuracoes e Validacoes
# Responsavel por carregar configuracoes, validar sistema e definir variaveis globais
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 05/04/2026-01

#---------- VARIaVEIS GLOBAIS ----------#

# Arrays para organizacao das variaveis
declare -a cores=(RED GREEN YELLOW BLUE PURPLE CYAN NORM)
declare -a atualizac=(sistema verclass dbmaker base base2 base3 acessossh ipserver Offline enviabackup empresa VERSAOANT)
declare -a caminhos_base=(BASE1 BASE2 BASE3 SCRIPT_DIR raiz base base2 base3 backup bases_backup logs olds cfg libs envia recebe)
declare -a caminhos_base2=(INI UMADATA acessoff E_EXEC T_TELAS X_XML)
declare -a biblioteca=(SAVATU SAVATU1 SAVATU2 SAVATU3 SAVATU4)
declare -a comandos=(cmd_unzip cmd_zip cmd_find cmd_who DEFAULT_UNZIP DEFAULT_ZIP DEFAULT_FIND DEFAULT_WHO jut JUTIL ISCCLIENT ISCCLIENTT)
declare -a outros=(SERVER_PORTA USUARIO VERSAO SAVISC DEFAULT_VERSAO DEFAULT_ARQUIVO DEFAULT_PEDARQ DEFAULT_PROG DEFAULT_PORTA DEFAULT_USUARIO DEFAULT_ipserver UPDATE SAVISCC JUTIL ISCCLIENT Offline base_trabalho)
declare -a logis=(LOG LOG_ATU LOG_LIMPA LOG_TMP)

#-VARIAVEIS do sistema ----------------------------------------------------------------------------#
#-Variaveis de configuracao do sistema ---------------------------------------------------------#
# Variaveis de configuracao do sistema que podem ser definidas pelo usuario.
# As variaveis com o prefixo "destino" sao usadas para definir o caminho
# dos diretorios que serao usados pelo programa.

raiz="${raiz:-}"                                 # Caminho do diretorio raiz do programa.
cfg_dir="${cfg_dir:-}"                           # Caminho do diretorio de configuracao do programa.

if [[ -n "${cfg_dir}" ]]; then
    if [[ ! -d "${cfg_dir}" ]]; then
        mkdir -p "${cfg_dir}" || {
            printf '%s\n' "ERRO: Nao foi possivel criar o diretorio de configuracao '${cfg_dir}'."
            exit 1
        }
    fi
    chmod 0777 "${cfg_dir}" 2>/dev/null || {
        printf '%s\n' "AVISO: Nao foi possivel ajustar permissao em '${cfg_dir}'."
    }
fi

lib_dir="${lib_dir:-}"                           # Caminho do diretorio de bibliotecas do programa.
base="${base:-}"                                 # Caminho do diretorio da base de dados.
base2="${base2:-}"                               # Caminho do diretorio da segunda base de dados.
base3="${base3:-}"                               # Caminho do diretorio da terceira base de dados.
progs="${progs:-}"                               # Caminho do diretorio dos programas.  
envia="${envia:-}"                               # Caminho do diretorio de envio.   
recebe="${recebe:-}"                             # Caminho do diretorio de recebimento.     
backup="${backup:-}"                             # Caminho do diretorio de backup.      
bkbase="${bkbase:-}"                             # Caminho do diretorio de backup da base.          
logs="${logs:-}"                                 # Caminho do diretorio dos arquivos de log.
olds="${olds:-}"                                 # Caminho do diretorio dos arquivos de backup.
libs="${libs:-}"                                 # Caminho do diretorio das bibliotecas.
sistema="${sistema:-}"                           # Tipo de sistema que esta sendo usado (iscobol ou isam).
SAVATU="${SAVATU:-}"                             # Caminho do diretorio da biblioteca do servidor da SAV.
SAVATU1="${SAVATU1:-}"                           # Caminho do diretorio da biblioteca do servidor da SAV.
SAVATU2="${SAVATU2:-}"                           # Caminho do diretorio da biblioteca do servidor da SAV.
SAVATU3="${SAVATU3:-}"                           # Caminho do diretorio da biblioteca do servidor da SAV.
SAVATU4="${SAVATU4:-}"                           # Caminho do diretorio da biblioteca do servidor da SAV.
verclass="${verclass:-}"                         # Ano da versao
dbmaker="${dbmaker:-}"                           # Variavel que define o tipo de banco de dados usado pelo sistema.
enviabackup="${enviabackup:-}"                   # Variavel que define o caminho para onde sera enviado o backup.
VERSAO="${VERSAO:-}"                             # Variavel que define a versao do programa.
INI="${INI:-}"                                   # Variavel que define o caminho do arquivo de configuracao do sistema.
Offline="${Offline:-}"                           # Variavel que define se o sistema esta em modo offline.
down_dir="${down_dir:-}"                         # Variavel que define o caminho do diretorio do servidor off.  
acesssoff="${acesssoff:-}"                       # Variavel que define o caminho do diretorio do servidor off.
acessossh="${acessossh:-}"                       # Variavel que define o caminho do diretorio do servidor off.
VERSAOANT="${VERSAOANT:-}"                       # Variavel que define a versao do programa anterior.
cmd_unzip="${cmd_unzip:-}"                       # Comando para descompactar arquivos.
cmd_zip="${cmd_zip:-}"                           # Comando para compactar arquivos.
cmd_find="${cmd_find:-}"                         # Comando para buscar arquivos.
cmd_who="${cmd_who:-}"                           # Comando para saber quem esta logado no sistema.
SERVER_PORTA="${SERVER_PORTA:-}"                 # Variavel que define a porta a ser usada para.
USUARIO="${USUARIO:-}"                           # Variavel que define o usuario a ser usado.
ipserver="${ipserver:-}"                         # Variavel que define o ip do servidor da SAV.
destino_biblioteca="${destino_biblioteca:-}"     # Variavel que define o caminho do diretorio da biblioteca do servidor da SAV.
RED="${RED:-}"                                   # Cor vermelha
GREEN="${GREEN:-}"                               # Cor verde
YELLOW="${YELLOW:-}"                             # Cor amarela
BLUE="${BLUE:-}"                                 # Cor azul
PURPLE="${PURPLE:-}"                             # Cor roxa
CYAN="${CYAN:-}"                                 # Cor ciano
NORM="${NORM:-}"                                 # Cor normal
COLUMNS="${COLUMNS:-}"                           # Numero de colunas do terminal
LOG="${LOG:-}"                                   # Variavel que define o caminho do arquivo de log.
LOG_ATU="${LOG_ATU:-}"                           # Variavel que define o caminho do arquivo de log de atualizacao.
LOG_LIMPA="${LOG_LIMPA:-}"                       # Variavel que define o caminho do arquivo de log de limpeza.
LOG_TMP="${LOG_TMP:-}"                           # Variavel que define o caminho do arquivo de log temporario.
UMADATA="${UMADATA:-}"                           # Variavel que define o caminho do arquivo de dados da UMA.
ISCCLIENT="${ISCCLIENT:-}"                       # Variavel que define o caminho do cliente ISC.
base_trabalho="${base_trabalho:-}"               # Variavel que define o caminho do diretorio de trabalho.

# Configuracoes padrao
DEFAULT_UNZIP="${DEFAULT_UNZIP:-unzip}"          # Comando padrao para descompactar
DEFAULT_ZIP="${DEFAULT_ZIP:-zip}"                # Comando padrao para compactar
DEFAULT_FIND="${DEFAULT_FIND:-find}"             # Comando padrao para buscar arquivos
DEFAULT_WHO="${DEFAULT_WHO:-who}"                # Comando padrao para verificar usuarios
DEFAULT_PORTA="${DEFAULT_PORTA:-41122}"          # Porta padrao
DEFAULT_USUARIO="${DEFAULT_USUARIO:-atualiza}"   # Usuario padrao


# Funcao para definir cores do terminal
_definir_cores() {
    # Verificar se o terminal suporta cores
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        RED=$(tput bold)$(tput setaf 1)          # Vermelho
        GREEN=$(tput bold)$(tput setaf 2)        # Verde
        YELLOW=$(tput bold)$(tput setaf 3)       # Amarelo
        BLUE=$(tput bold)$(tput setaf 4)         # Azul
        PURPLE=$(tput bold)$(tput setaf 5)       # Roxo
        CYAN=$(tput bold)$(tput setaf 6)         # Ciano
        WHITE=$(tput bold)$(tput setaf 7)        # Branco
        NORM=$(tput sgr0)                        # Normal
        COLUMNS=$(tput cols)                     # Numero de colunas do terminal

        # Limpar tela inicial
        tput clear                               # Limpa a tela
        tput bold                                # Ativa o negrito
        tput setaf 7                             # Define a cor branca para o texto
    else
        # Terminal sem suporte a cores
        RED=""                                   # Limpar variavel Vermelho
        GREEN=""                                 # Limpar variavel Verde
        YELLOW=""                                # Limpar variavel Amarelo
        BLUE=""                                  # Limpar variavel Azul
        PURPLE=""                                # Limpar variavel Roxo
        CYAN=""                                  # Limpar variavel Ciano
        WHITE=""                                 # Limpar variavel Branco
        NORM=""                                  # Limpar variavel Normal
        COLUMNS=80                               # Definir colunas padrao
    fi
export RED GREEN YELLOW BLUE PURPLE CYAN WHITE NORM COLUMNS 
}

# Configurar comandos do sistema
_configurar_comandos() {
    # Comando para descompactar
    if [[ -z "${cmd_unzip}" ]]; then
        cmd_unzip="${DEFAULT_UNZIP}"
    fi
    
    # Comando para compactar
    if [[ -z "${cmd_zip}" ]]; then
        cmd_zip="${DEFAULT_ZIP}"
    fi
    
    # Comando para localizar arquivos
    if [[ -z "${cmd_find}" ]]; then
        cmd_find="${DEFAULT_FIND}"
    fi
    
    # Comando para verificar usuarios
    if [[ -z "${cmd_who}" ]]; then
        cmd_who="${DEFAULT_WHO}"
    fi
    
    # Validar se os comandos existem
    for cmd in "$cmd_unzip" "$cmd_zip" "$cmd_find" "$cmd_who"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf "Erro: Comando %s nao encontrado.\n" "$cmd"
            _read_sleep 2
            exit 1
        fi
    done
}
# Configurar diretorios de trabalho e variaveis globais.
_configurar_diretorios() {
    
    # Verificar diretorio principal
    if [[ -z "${SCRIPT_DIR}" ]] || [[ ! -d "${SCRIPT_DIR}" ]]; then
        _mensagec "${CYAN}" "Diretorio principal nao encontrado: ${SCRIPT_DIR}"
        exit 1
    fi

    # Definir diretorio de configuracao
    raiz="${SCRIPT_DIR%/*}"

    # Criar diretorio de configuracao se nao existir
    if [[ ! -d "${cfg_dir}" ]]; then
        mkdir -p "${cfg_dir}" || {
            printf "Erro ao criar diretorio de configuracao %s\n" "${cfg_dir}"
            _read_sleep 2
            return 1
        }
        chmod 0777 "${cfg_dir}"
    fi

    # Diretorios de destino para diferentes tipos de biblioteca
    destino_server="${destino_server:-/u/varejo/man/}"                          # Diretorio do servidor de atualizacao
    destino_biblioteca="${destino_biblioteca:-/u/varejo/trans_pc/}"             # Diretorio de transporte PC
    export destino_server destino_biblioteca 
   

    # Definir diretorios de trabalho
    OLDS="${OLDS:-${SCRIPT_DIR}/olds}"                         # Diretorio de arquivos antigos
    PROGS="${PROGS:-${SCRIPT_DIR}/progs}"                      # Diretorio de programas
    LOGS="${LOGS:-${SCRIPT_DIR}/logs}"                         # Diretorio de logs
    ENVIA="${ENVIA:-${SCRIPT_DIR}/envia}"                      # Diretorio de envio
    RECEBE="${RECEBE:-${SCRIPT_DIR}/recebe}"                   # Diretorio de recebimento
    LIBS="${LIBS:-${SCRIPT_DIR}/libs}"                         # Diretorio de bibliotecas
    BACKUP="${BACKUP:-${SCRIPT_DIR}/backup}"                   # Diretorio de backup
    BASEBACKUP="${BASEBACKUP:-${SCRIPT_DIR}/bkbase}"           # Diretorio de backup de base
    # Exportar variaveis de diretorio para uso global
    export OLDS PROGS LOGS ENVIA RECEBE LIBS BACKUP BASEBACKUP

    # Criar diretorios se nao existirem
    local dirs=("${BASEBACKUP}" "${OLDS}" "${PROGS}" "${LOGS}" "${ENVIA}" "${RECEBE}" "${LIBS}" "${BACKUP}")
    for dir in "${dirs[@]}"; do
        if [[ ! -d "${dir}" ]]; then
            mkdir -p "${dir}" || {
                printf "Erro ao criar diretorio %s\n" "${dir}"
                _read_sleep 2
                return 1
            }
            chmod 0777 "${dir}"       
        fi
    done
}

# Configurar variaveis do sistema
_configurar_variaveis_sistema() {
        acessoff="${acessoff:-${raiz}/portalsav/Atualiza}"                                 # Diretorio do servidor offline
    
    if [[ "${sistema}" == "iscobol" ]]; then
   
        # Caminhos dos executaveis e dados
        E_EXEC="${E_EXEC:-${raiz}/classes}"      # Diretorio de executaveis para Iscobol
        T_TELAS="${T_TELAS:-${raiz}/tel_isc}"    # Diretorio de telas para Iscobol 
        X_XML="${X_XML:-${raiz}/xml}"            # Diretorio de telas para Iscobol
        BASE1="${BASE1:-${raiz}${base}}"         # Base de dados principal para Iscobol
        BASE2="${BASE2:-${raiz}${base2}}"        # Segunda base de dados para Iscobol
        BASE3="${BASE3:-${raiz}${base3}}"        # Terceira base de dados para Iscobol
        export E_EXEC T_TELAS X_XML BASE1 BASE2 BASE3 acessoff
    else
        E_EXEC="${E_EXEC:-${raiz}/int}"
        T_TELAS="${T_TELAS:-${raiz}/tel}"
        BASE1="${BASE1:-${raiz}${base}}"
        BASE2="${BASE2:-${raiz}${base2}}"
        BASE3="${BASE3:-${raiz}${base3}}"
        export E_EXEC T_TELAS BASE1 BASE2 BASE3 acessoff
    fi
    # Configuracao do SAVISC
    SAVISCC="${SAVISCC:-${raiz}/savisc/iscobol/bin/}"
    SAVISC="${SAVISCC}"

    # Utilitarios
    JUTIL="${JUTIL:-jutil}"
    ISCCLIENT="${ISCCLIENT:-iscclient}"
    
    # Caminho completo do jutil
    jut="${SAVISC}${JUTIL}"
    export SAVISCC SAVISC JUTIL ISCCLIENT jut
    
    # Configurar porta e acesso
    if [[ -z "${SERVER_PORTA}" ]]; then
        SERVER_PORTA="${DEFAULT_PORTA}"
    fi
    
    if [[ -z "${USUARIO}" ]]; then
        USUARIO="${DEFAULT_USUARIO}"
    fi
    
    # Configurar logs
    LOG_ATU="${LOG_ATU:-${LOGS}/atualiza.$(date +"%Y-%m-%d").log}"
    LOG_LIMPA="${LOG_LIMPA:-${LOGS}/limpando.$(date +"%Y-%m-%d").log}"
    LOG_TMP="${LOG_TMP:-${LOGS}/}"
    
    # Data atual formatada
    UMADATA=${UMADATA:-$(date +"%d-%m-%Y_%H%M%S")}
    
    # Arquivo de backup padrao
    INI=${INI:-"backup-${VERSAO}.zip"}

    # Gerar sufixos de arquivos com base no tipo de compilacao.
    if [[ "${sistema}" = "iscobol" ]]; then
        verclass_sufixo="${verclass: -2}"
        class="-class${verclass_sufixo}"
        mclass="-mclass${verclass_sufixo}"
#   Bibliotecas Iscobol 
        local classA="IS${verclass}_classA_"
        local classB="IS${verclass}_classB_"
        local classC="IS${verclass}_tel_isc_"
        local classD="IS${verclass}_xml_"
        local classX="IS${verclass}_*_"
        SAVATU1="tempSAV_${classA}"
        SAVATU2="tempSAV_${classB}"
        SAVATU3="tempSAV_${classC}"
        SAVATU4="tempSAV_${classD}"
        SAVATU="tempSAV_${classX}"
    else
        class="-${class:-6}"
        mclass="-${mclass:-m6}"    
#   Bibliotecas Isam
        SAVATU1="tempSAVintA_"
        SAVATU2="tempSAVintB_"
        SAVATU3="tempSAVtel_"
        SAVATU="tempSAV????_"
    fi
    export SAVATU1 SAVATU2 SAVATU3 SAVATU4 SAVATU
}

# Carregar arquivo de configuracao da empresa
_carregar_config_empresa() {
    local config_file="${cfg_dir}/.config"

# Verificar se o arquivo de configuracao existe e tem permissao de leitura 
    if [[ ! -e "${config_file}" ]]; then
        printf "ERRO: Arquivo de configuracao nao existe no diretorio.\n" 
        printf "ATENCAO: Use o programa .setup.sh que esta na pasta /libs para criar as configuracoes.\n" 
        _read_sleep 2
        exit 1
    fi
    
    if [[ ! -r "${config_file}" ]]; then
        printf "ERRO: Arquivo %s sem permissao de leitura.\n" "${config_file}"
        _read_sleep 2
        exit 1
    fi
    
    # Carregar configuracoes
    "." "${config_file}"
}

# Configurar acesso offline se necessario
_configurar_acessos() {
    if [[ "${Offline}" == "s" ]]; then
            down_dir="${acessoff}"    #"acessoff=/sav/portalsav/Atualiza"
        if [[ ! -d "${down_dir}" ]]; then
            mkdir -p "${down_dir}" || {
                printf "Erro ao criar diretorio offline %s\n" "${down_dir}"
                _read_sleep 2
                exit 1
            }
        fi
    else
        down_dir="${RECEBE}"       
    fi
}

# Funcao principal de carregamento de configuracoes
_carregar_configuracoes() {
    # Mudar para diretorio do script
    cd "${SCRIPT_DIR}" || exit 1
    
    # Definir cores
    _definir_cores
    
    # Carregar arquivos de configuracao
    _carregar_config_empresa

    # Configurar comandos
    _configurar_comandos

    # Configurar diretorios
    _configurar_diretorios
    
    # Configurar variaveis do sistema
    _configurar_variaveis_sistema
    
    # Configurar acesso offline
    _configurar_acessos
}

# Funcao para validar diretorios essenciais
_validar_diretorios() {
    # Funcao auxiliar para verificar diretorio
    _verifica_diretorio() {
        local caminho="$1"
#        local mensagem_erro="$2"
        
        if [[ ! -n "${caminho}" ]] || [[ ! -d "${caminho}" ]]; then
            _mensagec "${CYAN}" "Diretorio nao encontrado: ${caminho}"
            exit 1
        fi
    }
    
    # Verificar diretorios essenciais
    _verifica_diretorio "${E_EXEC}" "Diretorio de executaveis nao encontrado"
    _verifica_diretorio "${T_TELAS}" "Diretorio de telas nao encontrado"
    _verifica_diretorio "${BASE1}" "Base principal nao encontrada"
    
    # Verificar XML apenas se for IsCOBOL
    if [[ "${sistema}" == "iscobol" ]]; then
        _verifica_diretorio "${X_XML}" "Diretorio XML nao encontrado"
    fi
    
    # Verificar bases adicionais se configuradas
    if [[ -n "${BASE2}" ]]; then
        _verifica_diretorio "${BASE2}" "Segunda base nao encontrada"
    fi
    
    if [[ -n "${BASE3}" ]]; then
        _verifica_diretorio "${BASE3}" "Terceira base nao encontrada"
    fi
}

# Configurar ambiente final
_configurar_ambiente() {
    # Verificar se o jutil existe para sistemas IsCOBOL
    if [[ "${sistema}" == "iscobol" ]] && [[ ! -x "${jut}" ]]; then
        _mensagec "${YELLOW}" "Aviso: jutil nao encontrado em ${jut}"
    fi 
}

# Funcao para validar a configuracao atual do sistema
_validar_configuracao() {
    _limpa_tela
    _linha "=" "${GREEN}"
    _mensagec "${RED}" "Validacao de Configuracao"
    _linha
    
    local erros=0
    local warnings=0
    
    # Verificar arquivos de configuracao
    if [[ ! -f "${cfg_dir}/.config" ]]; then
        _mensagec "${RED}" "ERRO: Arquivo .config nao encontrado!"
        ((erros++))
    else
        _mensagec "${GREEN}" "OK: Arquivo .config encontrado"
    fi

    # Verificar variaveis essenciais
    if [[ -z "${sistema}" ]]; then
        _mensagec "${RED}" "ERRO: Variavel 'sistema' nao definida!"
        ((erros++))
    elif [[ "${sistema}" != "iscobol" && "${sistema}" != "cobol" ]]; then
        _mensagec "${YELLOW}" "Alerta: Valor desconhecido para 'sistema': ${sistema}"
        ((warnings++))
    else
        _mensagec "${GREEN}" "OK: Sistema definido como ${sistema}"
    fi
    
    if [[ -z "${raiz}" ]]; then
        _mensagec "${RED}" "ERRO: Variavel 'raiz' nao definida!"
        ((erros++))
    else
        _mensagec "${GREEN}" "OK: Diretorio raiz definido"
    fi
    
    if [[ -z "${dbmaker}" ]]; then
        _mensagec "${YELLOW}" "Alerta: Variavel 'dbmaker' nao definida"
        ((warnings++))
    else
        _mensagec "${GREEN}" "OK: Configuracao de banco de dados definida"
    fi
    
    # Verificar diretorios essenciais
    local dirs=("olds" "logs" "cfg" "libs" "backup" "bases_backup" "envia" "recebe" "E_EXEC" "T_TELAS" "BASE1")
    for dir in "${dirs[@]}"; do
        local dir_path=""
        # Tratamento especial para E_EXEC e T_TELAS que ficam em ${raiz}
        if [[ "$dir" == "E_EXEC" ]] || [[ "$dir" == "T_TELAS" ]] || [[ "$dir" == "BASE1" ]]; then
            dir_path="${!dir}"
        else
            # Para outros diretorios, usar o caminho padrao
            dir_path="${SCRIPT_DIR}${!dir}"
        fi
        
        if [[ ! -d "${dir_path}" ]]; then
            _mensagec "${YELLOW}" "Alerta: Diretorio ${dir} nao encontrado: ${dir_path}"
            ((warnings++))
        fi
    done
    
    # Verificar conectividade se for modo online
    if [[ "${Offline}" == "n" ]]; then
        _mensagec "${WHITE}" "INFO: Servidor em modo On ..."
    else 
        _mensagec "${GREEN}" "INFO: Servidor em modo Off ..."
    fi
    
    _linha
    printf "\n"
    _mensagec "${CYAN}" "Resumo:"
    _mensagec "${RED}" "Erros: ${erros}"
    _mensagec "${YELLOW}" "Avisos: ${warnings}"
    
    if (( erros == 0 )); then
        _mensagec "${GREEN}" "Configuracao valida!"
    else
        _mensagec "${RED}" "Configuracao com erros!"
    fi
    
    _linha
}

_ir_para_tools() {
    cd "${SCRIPT_DIR}" || {
        printf "Erro ao acessar o diretorio %s\n" "${SCRIPT_DIR}"
        exit 1
    }
}

# Funcao para resetar variaveis (cleanup)
_limpar_estado_variaveis() {
    unset -v "${cores[@]}" 2>/dev/null || true
    unset -v "${atualizac[@]}" 2>/dev/null || true
    unset -v "${caminhos_base[@]}" 2>/dev/null || true
    unset -v "${caminhos_base2[@]}" 2>/dev/null || true
    unset -v "${biblioteca[@]}" 2>/dev/null || true
    unset -v "${comandos[@]}" 2>/dev/null || true
    unset -v "${outros[@]}" 2>/dev/null || true
    unset -v "${logis[@]}" 2>/dev/null || true

    tput sgr0 2>/dev/null || true
}

_resetando() {
    _limpar_estado_variaveis
    return 0
}

_encerrar_programa() {
    local status="${1:-0}"
    _limpar_estado_variaveis
    exit "$status"
}
