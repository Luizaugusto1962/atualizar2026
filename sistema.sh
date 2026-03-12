#!/usr/bin/env bash
#
# sistema.sh - Modulo de Informacoes do Sistema
# Responsavel por informacoes do IsCOBOL, Linux, parametros e atualizacoes
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 10/03/2026-00
#
# Variaveis globais esperadas
cfg_dir="${cfg_dir:-}"      # Caminho do diretorio de configuracao do programa.
lib_dir="${lib_dir:-}"      # Diretorio dos modulos de biblioteca.
cmd_unzip="${cmd_unzip:-}"  # Comando de descompactacao (unzip).
class="${class:-}"          # Variavel da classe.
mclass="${mclass:-}"        # Variavel da mclass.

#---------- FUNCOES DE VERSAO ----------#
# Mostra versao do IsCOBOL
_mostrar_versao_iscobol() {
    if [[ "${sistema}" == "iscobol" ]]; then
        if [[ -x "${SAVISC}${ISCCLIENT}" ]]; then
            clear
            _linha "=" "${GREEN}"
            _mensagec "${GREEN}" "Versao do IsCobol"
            _linha "=" "${GREEN}"
            "${SAVISC}${ISCCLIENT}" -v
            _linha "=" "${GREEN}"
            printf "\n\n"
        else
            _linha
            _mensagec "${RED}" "Erro: ${SAVISC}${ISCCLIENT} nao encontrado ou nao executavel"
            _linha
            _read_sleep 2
        fi
    elif [[ -z "${sistema}" ]]; then
        _linha
        _mensagec "${RED}" "Erro: Variavel de sistema nao configurada"
        _linha
        _read_sleep 2
    else
        _linha
        _mensagec "${YELLOW}" "Sistema nao e IsCOBOL"
        _linha
        _read_sleep 2
    fi
    _press
}

# Mostra informacoes do Linux
_mostrar_versao_linux() {
    clear
    printf "\n\n"
    _mensagec "${GREEN}" "Vamos descobrir qual S.O. / Distro voce esta executando"
    _linha
    printf "\n\n"
    _mensagec "${YELLOW}" "A partir de algumas informacoes basicas o seu sistema, parece estar executando:"
    _linha

    # Checando se conecta com a internet ou nao
    if ping -c 1 google.com &>/dev/null; then
        printf "${GREEN}""Internet: ""${NORM}""Conectada""%*s\n"
    else
        printf "${GREEN}""Internet: ""${NORM}""Desconectada""%*s\n"
    fi

    # Checando tipo de OS
    os=$(uname -o)
    printf "${GREEN}""Sistema Operacional :""${NORM}""${os}""%*s\n"

    # Checando OS Versao e nome
    if [[ -f /etc/os-release ]]; then
        grep 'NAME\|VERSION' /etc/os-release | grep -v 'VERSION_ID\|PRETTY_NAME' >"${LOG_TMP}osrelease"
        printf "${GREEN}""OS Nome :""${NORM}""%*s\n"
        grep -v "VERSION" "${LOG_TMP}osrelease" | cut -f2 -d\"
        printf "${GREEN}""OS Versao :""${NORM}""%*s\n"
        grep -v "NAME" "${LOG_TMP}osrelease" | cut -f2 -d\"
    else
        printf "${RED}""Arquivo /etc/os-release nao encontrado.""%*s\n"
    fi
    printf "\n"

    # Checando hostname
    nameservers=$(hostname)
    printf "${GREEN}""Nome do Servidor :""${NORM}""${nameservers}""%*s\n"
    printf "\n"

    # Checando Interno IP
    internalip=$(ip route get 1 | awk '{print $7;exit}')
    printf "${GREEN}""IP Interno :""${NORM}""${internalip}""%*s\n"
    printf "\n"

    # Checando Externo IP
    if [[ "${Offline}" == "n" ]]; then
        externalip=$(curl -s ipecho.net/plain || printf "Nao disponivel")
        printf "${GREEN}""IP Externo :""${NORM}""${externalip}""%*s\n"
    fi

    _linha
    _press
    clear
    _linha

    # Checando os usuarios logados
    _run_who() {
        who >"${LOG_TMP}who"
    }
    _run_who
    printf "${GREEN}""Usuario Logado :""${NORM}""%*s\n"
    cat "${LOG_TMP}who"
    printf "\n"

    # Checando uso de memoria RAM e SWAP
    free | grep -v + >"${LOG_TMP}ramcache"
    printf "${GREEN}""Uso de Memoria Ram :""${NORM}""%*s\n"
    grep -v "Swap" "${LOG_TMP}ramcache"
    printf "${GREEN}""Uso de Swap :""${NORM}""%*s\n"
    grep -v "Mem" "${LOG_TMP}ramcache"
    printf "\n"

    # Checando uso de disco
    df -h | grep 'Filesystem\|/dev/sda*' >"${LOG_TMP}diskusage"
    printf "${GREEN}""Espaco em Disco :""${NORM}""%*s\n"
    cat "${LOG_TMP}diskusage"
    printf "\n"

    # Checando o Sistema Uptime
    tecuptime=$(uptime -p | cut -d " " -f2-)
    printf "${GREEN}""Sistema em uso Dias/(HH:MM) : ""${NORM}""${tecuptime}""%*s\n"

    # Unset Variables
    unset os internalip externalip nameservers tecuptime

    # Removendo temporarios arquivos
    rm -f "${LOG_TMP}osrelease" "${LOG_TMP}who" "${LOG_TMP}ramcache" "${LOG_TMP}diskusage"
    _linha
    _press
}

#---------- FUNcoES DE PARaMETROS ----------#
       # Antes de usar, carregar o arquivo
        if [[ -f "${cfg_dir}/.versao" ]]; then
            "." "${cfg_dir}/.versao"
        fi
        
# Mostra parametros do sistema
_mostrar_parametros() {
    clear
    _linha "=" "${GREEN}"
    printf "${GREEN}Sistema e banco de dados: ${NORM}${dbmaker}""%*s\n"
    printf "${GREEN}Diretorio raiz: ${NORM}${raiz}""%*s\n"
    printf "${GREEN}Diretorio do atualiza.sh: ${NORM}${TOOLS_DIR}""%*s\n"
    printf "${GREEN}Diretorio da base principal: ${NORM}${raiz}${base}""%*s\n"
    printf "${GREEN}Diretorio da segunda base: ${NORM}${raiz}${base2}""%*s\n"
    printf "${GREEN}Diretorio da terceira base: ${NORM}${raiz}${base3}""%*s\n"
    printf "${GREEN}Diretorio dos executaveis: ${NORM}${E_EXEC}""%*s\n"
    printf "${GREEN}Diretorio das telas: ${NORM}${T_TELAS}""%*s\n"
    printf "${GREEN}Diretorio dos xmls: ${NORM}${X_XML}""%*s\n"
    printf "${GREEN}Diretorio dos logs: ${NORM}${LOGS}""%*s\n"
    printf "${GREEN}Diretorio dos olds: ${NORM}${OLDS}""%*s\n"
    printf "${GREEN}Diretorio dos progs: ${NORM}${PROGS}""%*s\n"
    printf "${GREEN}Diretorio do backup: ${NORM}${BACKUP}""%*s\n"
    printf "${GREEN}Diretorio de configuracoes: ${NORM}${cfg_dir}""%*s\n"
    printf "${GREEN}Sistema em uso: ${NORM}${sistema}""%*s\n"
    printf "${GREEN}Versao em uso: ${NORM}${verclass}""%*s\n"
    printf "${GREEN}Biblioteca 1: ${NORM}${SAVATU1}""%*s\n"
    printf "${GREEN}Biblioteca 2: ${NORM}${SAVATU2}""%*s\n"
    printf "${GREEN}Biblioteca 3: ${NORM}${SAVATU3}""%*s\n"
    printf "${GREEN}Biblioteca 4: ${NORM}${SAVATU4}""%*s\n"
    _linha "=" "${GREEN}"
    _press
    clear
    _linha "=" "${GREEN}"
    printf "${GREEN}Diretorio para envio de backup: ${NORM}${enviabackup}""%*s\n"
    printf "${GREEN}Servidor OFF: ${NORM}${Offline}""%*s\n"
    printf "${GREEN}Diretorio de configuracoes em OFF: ${NORM}${down_dir}""%*s\n"
    printf "${GREEN}Versao da biblioteca atual: ${NORM}${VERSAOANT}""%*s\n"
    printf "${GREEN}Variavel da classe: ${NORM}${class}""%*s\n"
    printf "${GREEN}Variavel da mclass: ${NORM}${mclass}""%*s\n"
    printf "${GREEN}Porta de conexao: ${NORM}${SERVER_PORTA}""%*s\n"
    printf "${GREEN}Usuario de conexao: ${NORM}${USUARIO}""%*s\n"
    printf "${GREEN}Servidor IP: ${NORM}${ipserver}""%*s\n"
    _linha "=" "${GREEN}"
    _press
}

#---------- FUNcoES DE ATUALIZAcaO ----------#

# Executa atualizacao do script
_executar_update() {
    local temp_dir="${ENVIA}/temp_update/"
    local zipfile="atualiza.zip"
    local down_dir="${down_dir}"
    _configurar_acessos
    
    if [[ "${Offline}" == "n" ]]; then
        _atualizar_online
        export tipo_online 
    else
        _atualizar_offline
        export tipo_offline
    fi
    _press
}

# Atualizacao online via GitHub
_atualizando() {
    _configurar_diretorios
    _mensagec "${GREEN}" "Atualizando script via GitHub..."

    # Criar backup do arquivo atual
    if [[ ! -d "${BACKUP}" ]]; then
        mkdir -p "${BACKUP}" || {
            _mensagec "${RED}" "Erro: Nao foi possivel criar diretorio de backup"
            _read_sleep 2
            return 1
        }
    fi

    # Fazer backup dos arquivos atuais
    local backup_sucesso=0
    local backup_erro=0
    cd "${lib_dir}" || {
        _mensagec "${RED}" "Erro: Diretorio de atualizacao nao encontrado"
        _read_sleep 2
        return 1
    }
    # Processar todos os arquivos .sh para backup
    for arquivo in *.sh; do
        # Verificar se o arquivo existe
        if [[ ! -f "$arquivo" ]]; then
            _mensagec "${YELLOW}" "Aviso: Nenhum arquivo .sh encontrado para backup"
            _read_sleep 2
            break
        fi

        # Copiar o arquivo para o diretorio de backup
        if cp -f "$arquivo" "$BACKUP/$arquivo.bkp"; then
            _mensagec "${GREEN}" "Backup do arquivo $arquivo feito com sucesso"
            ((backup_sucesso++))
        else
            _mensagec "${RED}" "Erro ao fazer backup de $arquivo"
            ((backup_erro++))
            _read_sleep 2
        fi
    done

    # Verificar se houve erros no backup
    if [[ $backup_erro -gt 0 ]]; then
        _mensagec "${RED}" "Falha no backup de $backup_erro arquivo(s)"
        _read_sleep 2
        return 1
    elif [[ $backup_sucesso -eq 0 ]]; then
        _mensagec "${YELLOW}" "Nenhum arquivo foi copiado para backup"
        _read_sleep 2
        return 1
    else
        _mensagec "${GREEN}" "Backup de $backup_sucesso arquivo(s) realizado com sucesso"
         # Compactar arquivos .bkp com nome baseado na data atual (DDMM_backup.zip)
        local data_zip
        data_zip=$(date +"%d%m")
        local zip_nome="${data_zip}_backup.zip"

        if cd "${BACKUP}" && zip -jm "${zip_nome}" ./*.sh.bkp >>"$LOG_ATU" 2>&1; then
            _mensagec "${GREEN}" "Backup compactado com sucesso: ${BACKUP}/${zip_nome}"
        else
            _mensagec "${YELLOW}" "Aviso: Nao foi possivel compactar os arquivos de backup"
        fi
        cd "${lib_dir}" || return 1

    fi

    # Acessar diretorio de trabalho
    cd "$ENVIA" || {
        _mensagec "${RED}" "Erro: Diretorio $ENVIA nao acessivel"
        _read_sleep 2
        return 1
    }
    if [[ "${Offline}" == "n" ]]; then
    # Baixar arquivo
        if ! wget -q -c "$link"; then
            _mensagec "${RED}" "Erro ao baixar arquivo de atualizacao"
            _mensagec "${YELLOW}" "Verifique sua conexao com a internet e tente novamente"
            _read_sleep 2
            return 1
        fi
    fi

    # Descompactar
    if ! "${cmd_unzip}" -o -j "$zipfile" >>"$LOG_ATU" 2>&1; then
        _mensagec "${RED}" "Erro ao descompactar atualizacao"
        _mensagec "${YELLOW}" "Verifique se o atualiza.zip esta no diretorio $ENVIA"
        _read_sleep 2
        return 1
    fi
    # Verificar e instalar arquivos
    local arquivos_instalados=0
    local arquivos_erro=0

    #---------- INSTALAR ARQUIVOS DE CONFIGURAÇÃO ----------#
    # Processa manual.txt e atualiza.txt com destino ${cfg_dir}
    local -a cfg_files=("manual.txt" "avisos" "indexar" "limpetmp" ".senhas")
    
    for cfg_arquivo in "${cfg_files[@]}"; do
        if [[ ! -f "$cfg_arquivo" ]]; then
            continue  # Arquivo não encontrado, pula para próximo
        fi

        # Definir permissões executáveis
        chmod +x "$cfg_arquivo" 2>/dev/null || true

        # Definir destino (cfg_dir para todos os arquivos de config)
        local cfg_target="${cfg_dir}"
        
        # Criar destino se não existir
        if ! mkdir -p "$cfg_target" 2>/dev/null; then
            _mensagec "${RED}" "Erro ao criar diretório de destino: $cfg_target"
            ((arquivos_erro++))
            continue
        fi

        # Mover arquivo para destino
        if mv -f "$cfg_arquivo" "$cfg_target/$cfg_arquivo"; then
            _mensagec "${GREEN}" "Arquivo $cfg_arquivo instalado em $cfg_target"
            ((arquivos_instalados++))
             
        else
            _mensagec "${RED}" "✗ Erro ao instalar $cfg_arquivo"
            ((arquivos_erro++))
        fi
    done

    #---------- INSTALAR ARQUIVOS .SH ----------#
    # Processa todos os arquivos .sh encontrados
    local sh_instalados=0
    for arquivo in *.sh; do
        # Verificar se o arquivo existe
        if [[ ! -f "$arquivo" ]]; then
            continue  # Arquivo não encontrado, pula para próximo
        fi

        # Definir permissões executáveis
        chmod +x "$arquivo" || {
            _mensagec "${RED}" "Aviso: falha ao definir permissão em $arquivo"
        }

        # Determinar destino baseado no nome do arquivo
        local sh_target
        if [[ "$arquivo" == "atualiza.sh" ]]; then
            sh_target="${TOOLS_DIR}"
        else
            sh_target="${lib_dir}"
        fi

        # Criar destino se não existir
        if ! mkdir -p "$sh_target" 2>/dev/null; then
            _mensagec "${RED}" "Erro ao criar diretório: $sh_target"
            ((arquivos_erro++))
            continue
        fi

        # Mover arquivo para destino
        if mv -f "$arquivo" "$sh_target/"; then
            _mensagec "${GREEN}" "Instalado $arquivo em $sh_target"
            ((arquivos_instalados++))
            ((sh_instalados++))
        else
            _mensagec "${RED}" "✗ Erro ao instalar $arquivo"
            ((arquivos_erro++))
        fi
    done

    # Relatório final de instalação
    if [[ $sh_instalados -eq 0 ]]; then
        _mensagec "${YELLOW}" "Aviso: Nenhum arquivo .sh foi instalado"
    fi

    #---------- VALIDAÇÃO FINAL ----------#
    # Verificar resultado da instalação
    if [[ $arquivos_erro -gt 0 ]]; then
        _mensagec "${RED}" "Falha na instalação de $arquivos_erro arquivo(s)"
        return 1
    elif [[ $arquivos_instalados -eq 0 ]]; then
        _mensagec "${YELLOW}" "Nenhum arquivo foi instalado - verifique os arquivos no ZIP"
        return 1
    else
        _mensagec "${GREEN}" "Sucesso: $arquivos_instalados arquivo(s) instalado(s)"
    fi

# Limpar diretorio de trabalho
# Verificar se o diretório ENVIA existe
if [[ ! -d "${ENVIA}" ]]; then
    _mensagec "${RED}" "ERRO: Diretorio '${ENVIA}' nao encontrado."
    _read_sleep 2
    exit 1
fi

# Mudar para o diretório ENVIA com verificação
if ! cd "${ENVIA}"; then
   _mensagec "${RED}" "ERRO: Nao foi possível acessar o diretorio '${ENVIA}'."
    _read_sleep 2
    exit 1
fi

# Confirmar que estamos no diretório correto antes de deletar
if [[ "$(pwd)" != "${ENVIA}" ]]; then
    _mensagec "${RED}" "ERRO: Falha na verificacao de seguranca do diretcrio."
    _read_sleep 2
    exit 1
fi

# Verificar se há arquivos para remover
if [[ -n "$(ls -A 2>/dev/null)" ]]; then
    _mensagec "${YELLOW}" "Limpando conteudo do diretorio: ${ENVIA}"
    
    # Remover apenas o conteúdo, não o próprio diretório
    if rm -rf ./* ./.[!.]* 2>/dev/null; then
        _mensagec "${GREEN}" "Diretorio limpo com sucesso."
    else
        _mensagec "${YELLOW}" "AVISO: Alguns arquivos podem nao ter sido removidos."
    fi
else
    _mensagec "${GREEN}" "Diretorio ja esta vazio."
fi
    _linha
    _mensagec "${GREEN}" "Atualizacao concluida com sucesso!"
    _mensagec "${GREEN}" "Ao terminar, entre novamente no sistema"
    _linha

    exit 0
}

_atualizar_online() {
    local link="https://github.com/Luizaugusto1962/atualizar2026/archive/master/atualiza.zip"
       # Criar e acessar diretorio temporario
    mkdir -p "$temp_dir" || {
        _mensagec "${RED}" "Erro: Nao foi possivel criar o diretorio temporario $temp_dir."
        _read_sleep 2
        return 1
    }
    _atualizando
}

# Atualizacao offline via arquivo local
_atualizar_offline() {
    local temp_dir="${ENVIA}/temp_update/"
    local zipfile="atualiza.zip"

    # Criar e acessar diretorio temporario
    mkdir -p "$temp_dir" || {
        _mensagec "${RED}" "Erro: Nao foi possivel criar o diretorio temporario $temp_dir."
        _read_sleep 2
        return 1
    }

    # Verificar se o arquivo zip existe
    if [[ ! -f "${down_dir}/${zipfile}" ]]; then
        _mensagec "${RED}" "Erro: $zipfile nao encontrado em $down_dir"
        _mensagec "${YELLOW}" "Certifique-se de que o arquivo $zipfile esteja presente no diretorio $down_dir"
        _read_sleep 2
        return 1
    fi

    mv "${down_dir}/${zipfile}" "${ENVIA}" || {
        _mensagec "${RED}" "Erro: Nao foi possivel mover $zipfile para $ENVIA"
        _read_sleep 2
        return 1
    }

        # Acessar diretorio offline
    cd "$temp_dir" || {
        _mensagec "${RED}" "Erro: Diretorio temporario, $temp_dir nao acessivel"
        _read_sleep 2
        return 1
    }
    _atualizando
}

#---------- FUNcoES DE MANUTENcaO DO SETUP ----------#
# Constantes
readonly tracejada="#-------------------------------------------------------------------#"

# Variaveis globais
declare -l sistema base base2 base3 dbmaker raiz Offline enviabackup
declare -u empresa
# Posiciona o script no diretorio cfg_dir.
cd "${cfg_dir}" || {
    _mensagec "${RED}" "Erro: Diretorio ${cfg_dir} nao encontrado"
    _read_sleep 2
    exit 1
}

editar_variavel() {
    local nome="$1"
    local valor_atual="${!nome}"

    # Funcao para editar variavel com prompt
    read -rp "Deseja alterar ${nome} (valor atual: ${valor_atual})? [s/N] " alterar
    alterar=${alterar,,}
    if [[ "$alterar" =~ ^s$ ]]; then
        if [[ "$nome" == "sistema" ]]; then
            printf "\n"
            printf "%s\n" "Escolha o sistema:"
            printf "%s\n" "1) IsCobol"
            printf "%s\n" "2) Micro Focus Cobol"
            read -rp "Opcao [1-2]: " opcao
            case "$opcao" in
            1) sistema="iscobol" ;;
            2) sistema="cobol" ;;
            *) echo "Opcao invalida. Mantendo valor anterior: $valor_atual" ;;
            esac

        elif [[ "$nome" == "dbmaker" ]]; then
            printf "\n"
            printf "%s\n" "${tracejada}"
            printf "%s\n" "O sistema usa banco de dados?"
            printf "%s\n" "1) Sim"
            printf "%s\n" "2) Nao"
            read -rp "Opcao [1-2]: " opcao
            case "$opcao" in
            1) dbmaker="s" ;;
            2) dbmaker="n" ;;
            *) echo "Opcao invalida. Mantendo valor anterior: $valor_atual" ;;
            esac

        elif [[ "$nome" == "acessossh" ]]; then
            printf "\n"
            printf "%s\n" "${tracejada}"
            printf "%s\n" "Metodo de acesso facil?"
            printf "%s\n" "1) Sim"
            printf "%s\n" "2) Nao"
            read -rp "Opcao [1-2]: " opcao
            case "$opcao" in
            1) acessossh="s" ;;
            2) acessossh="n" ;;
            *) echo "Opcao invalida. Mantendo valor anterior: $valor_atual" ;;
            esac

        elif [[ "$nome" == "ipserver" ]]; then
            printf "\n"
            printf "%s\n" "${tracejada}"
            read -rp "Digite o IP do Servidor SAV (ou pressione Enter para manter $valor_atual): " novo_ip
        if [[ -n "$novo_ip" ]]; then
            ipserver="$novo_ip"
        else
            ipserver="$valor_atual"
            echo "Mantendo valor anterior: $valor_atual"
        fi    

        elif [[ "$nome" == "Offline" ]]; then
            printf "\n"
            printf "%s\n" "${tracejada}"
            printf "%s\n" "O sistema em modo Offline ?"
            printf "%s\n" "1) Sim"
            printf "%s\n" "2) Nao"
            read -rp "Opcao [1-2]: " opcao
            case "$opcao" in
            1) Offline="s" ;;
            2) Offline="n" ;;
            *) printf "%s\n" "Opcao invalida. Mantendo valor anterior: $valor_atual" ;;
            esac
        else
            read -rp "Novo valor para ${nome}: " novo_valor
            # Usar declare em vez de eval para seguranca
            declare -g "$nome"="$novo_valor"
        fi
    fi
    printf "%s\n" "${tracejada}"
}
_manutencao_setup() {

# Se os arquivos existem, carrega e pergunta se quer editar campo a campo
if [[ -f ".config" ]]; then
    echo "=================================================="
    echo "Arquivo .config ja existem."
    echo "Carregando parametros para edicao..."
    echo "=================================================="
    echo

    # Carrega os valores existentes do arquivo .config
    "." ./.config || {
        echo "Erro: Falha ao carregar .config"
        _read_sleep 2
        exit 1
    }

    # Faz backup dos arquivos
    cp .config .config.bkp || {
        echo "Erro: Falha ao criar backup de .config"
        _read_sleep 2
        exit 1
    }
fi

clear

    # Edita as variaveis
    editar_variavel sistema
    editar_variavel verclass
    editar_variavel dbmaker
    editar_variavel acessossh
    editar_variavel ipserver
    editar_variavel Offline
    editar_variavel enviabackup
    editar_variavel empresa
    editar_variavel base
    editar_variavel base2
    editar_variavel base3

    # Recria .config
    echo "Recriando .config com os novos parametros..."
    echo ${tracejada}

    {
        echo "sistema=${sistema}"
        [[ -n "$verclass" ]] && echo "verclass=${verclass}"
        [[ -n "$dbmaker" ]] && echo "dbmaker=${dbmaker}"
        [[ -n "$acessossh" ]] && echo "acessossh=${acessossh}"
        [[ -n "$ipserver" ]] && echo "ipserver=${ipserver}"      
        [[ -n "$Offline" ]] && echo "Offline=${Offline}"
        [[ -n "$enviabackup" ]] && echo "enviabackup=${enviabackup}"
        [[ -n "$empresa" ]] && echo "empresa=${empresa}"
        [[ -n "$base" ]] && echo "base=${base}"
        [[ -n "$base2" ]] && echo "base2=${base2}"
        [[ -n "$base3" ]] && echo "base3=${base3}"
    } >.config

    echo
    echo "Arquivo .config atualizado com sucesso!"
    echo
    echo ${tracejada}
    
if [[ "${acessossh}" = "s" ]]; then

# CONFIGURAcoES PERSONALIZAVEIS (ALTERE AQUI OU VIA VARIAVEIS DE AMBIENTE)
SERVER_IP="${ipserver}"                        # IP do servidor 
SERVER_PORTA="${SERVER_PORTA:-41122}"            # Porta SFTP (padrao: 41122)
SERVER_USER="${SERVER_USER:-atualiza}"         # Usuario SSH (padrao: atualiza)
CONTROL_PATH_BASE="${CONTROL_PATH_BASE:-${TOOLS_DIR}/.ssh/control}"
# VALIDAcaO DAS VARIaVEIS OBRIGAToRIAS
    if [[ -z "$SERVER_IP" || -z "$SERVER_PORTA" || -z "$SERVER_USER" ]]; then
        echo "Erro: Variaveis obrigatorias nao definidas!"
        echo "Defina via ambiente ou edite as configuracoes no inicio do script:"
        echo "  export SERVER_IP='seu.ip.aqui'"
        echo "  export SERVER_PORTA='porta'"
        echo "  export SERVER_USER='usuario'"
        exit 1
    fi

# PREPARAcaO DOS DIREToRIOS
SSH_CONFIG_DIR="$(dirname "$CONTROL_PATH_BASE")"
CONTROL_PATH="$CONTROL_PATH_BASE"

# Verifica/cria diretorio base
    if [[ ! -d "$SSH_CONFIG_DIR" ]]; then
        echo "Criando diretorio $SSH_CONFIG_DIR..."
        mkdir -p "$SSH_CONFIG_DIR" || {
            echo "Falha: Permissao negada para criar $SSH_CONFIG_DIR. Use sudo se necessario."
            exit 1
        }
        chmod 700 "$SSH_CONFIG_DIR"
    fi

# Verifica/cria diretorio de controle
    if [[ ! -d "$CONTROL_PATH" ]]; then
        echo "Criando diretorio de controle $CONTROL_PATH..."
        mkdir -p "$CONTROL_PATH" || {
            echo "Falha: Permissao negada para criar $SSH_CONFIG_DIR."
            exit 1
        }
        chmod 700 "$CONTROL_PATH"
    fi

# CONFIGURAcaO SSH
    if [[ ! -f "/root/.ssh/config" ]]; then
    mkdir -p "/root/.ssh"
    chmod 700 "/root/.ssh"
    
    # Injeta as variaveis diretamente na configuracao (sem aspas em EOF para expansao)
    cat << EOF >> "/root/.ssh/config"
Host sav_servidor
    HostName $SERVER_IP
    Port $SERVER_PORTA
    User $SERVER_USER
    ControlMaster auto
    ControlPath $CONTROL_PATH/%r@%h:%p
    ControlPersist 10m
EOF
    chmod 600 "/root/.ssh/config"
    echo "Configuracao SSH criada com parametros:"
    else
    echo "Arquivo de configuracao ja existe regravando: /root/.ssh/config"
    
    # Verifica se a configuracao especifica ja esta presente
        cat << EOF >> "/root/.ssh/config"
# Configuracao adicionada automaticamente
Host sav_servidor
    HostName $SERVER_IP
    Port $SERVER_PORTA
    User $SERVER_USER
    ControlMaster auto
    ControlPath $CONTROL_PATH/%r@%h:%p
    ControlPersist 10m
EOF
        echo "Configuracao 'sav_servidor' adicionada com parametros:"
    fi

_linha
# EXIBE OS PARaMETROS UTILIZADOS
echo -e "\n   IP do Servidor:   ${SERVER_IP}"
echo "   Porta:            ${SERVER_PORTA}"
echo "   Usuario:          ${SERVER_USER}"
echo "   ControlPath:      ${CONTROL_PATH}/%r@%h:%p"
echo -e "\n Validacao concluida! Teste com:"
echo "   sftp sav_servidor"
echo
echo
_linha
_press 
else
    echo "Acesso SSH desativado. Para configurar, defina acessossh=s no arquivo .config"    
exit 1
fi
}
