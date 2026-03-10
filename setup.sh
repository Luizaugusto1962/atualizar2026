#!/usr/bin/env bash
#
# setup.sh - Gerencia a configuracao do sistema
# Este script gerencia a criacao e a edicao dos arquivos de configuracao
# .config, que e essencial para o funcionamento do sistema.
#
# Modos de Operacao:
#   - ./setup.sh: Modo de configuracao inicial interativo.
#   - ./setup.sh --edit: Modo de edicao para modificar configuracoes existentes.
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 10/03/2026-00

#---------- FUNCAO DE LOGICA DE NEGOCIO ----------#
# Variaveis globais esperadas
verclass="${verclass:-}"

# Variáveis globais
declare -l sistema base base2 base3 dbmaker enviabackup
declare -u empresa

# Configuracao inicial do sistema
_initial_setup() {
    clear

    # Constantes
    local tracejada="#-------------------------------------------------------------------#"
    local traco="#####################################################################"

    # Header inicial
    echo "$traco"
    echo ${traco} >.config
    echo "###      ( Parametros para serem usados no atualiza.sh )          ###"
    echo "$traco"
    echo ${traco} >.config
    # Criar arquivos de configuracao
    echo "$traco" > .config
    echo "###      ( Parametros para serem usados no atualiza.sh )          ###" >> .config
    echo "$traco" >> .config

    # Selecionar sistema (IsCobol ou Microfocus)
    echo "Em qual sistema o SAV esta rodando?"
    echo "1) Iscobol"
    echo "2) Microfocus"
    read -n1 -rp "Escolha o sistema: " escolha
    echo

    case "$escolha" in
        1) _setup_iscobol ;;
        2) _setup_cobol ;;
        *)
            echo "Alternativa incorreta, saindo!"
            sleep 1
            exit 1
            ;;
    esac

    # Configuracoes adicionais
    _setup_banco_de_dados
    _setup_diretorios
    _setup_acesso_remoto
    _setup_backup
    _setup_empresa

    # Criar atalho global
    echo "cd ${TOOLS_DIR:-TOOLS_DIR}" > /usr/local/bin/atualiza
    echo "./atualiza.sh" >> /usr/local/bin/atualiza
    chmod +x /usr/local/bin/atualiza

    echo "Pronto!"
}

# Edicao de configuracoes existentes
_edit_setup() {
    local tracejada="#-------------------------------------------------------------------#"

    # Mover para o diretorio de configuracao
    cd "${cfg_dir}" || {
        echo "Erro: Diretorio 'cfg' nao encontrado."
        exit 1
    }

    # Verificar se os arquivos de configuracao existem
#    if [[ ! -f "${cfg_dir}/.config" ]]; then
    if [[ ! -f "${cfg_dir}/.atualizac" ]]; then
        echo "Arquivos de configuracao nao encontrados. Execute o setup inicial primeiro."
        exit 1
    fi

    echo "=================================================="
    echo "Carregando parametros para edicao..."
    echo "=================================================="

    # Carregar configuracoes existentes
    "." ./.config

    # Fazer backup
    cp .config .config.bkp

    # Edicao interativa das variaveis
    _editar_variavel sistema
    _editar_variavel verclass
    _editar_variavel dbmaker
    _editar_variavel acessossh
    _editar_variavel ipserver
    _editar_variavel Offline
    _editar_variavel enviabackup
    _editar_variavel empresa
    _editar_variavel base
    _editar_variavel base2
    _editar_variavel base3

    # Recriar arquivos de configuracao
    _recreate_config_files

    echo "Arquivos .config atualizado com sucesso!"

    # Configurar SSH se habilitado
    if [[ "${acessossh}" == "s" ]]; then
        _configure_ssh_access
    fi

    echo "$tracejada"
    read -rp "Pressione Enter para sair..."
    exit 0
}

#---------- FUNcoES DE SETUP INICIAL ----------#

# Configuracao para IsCobol
_setup_iscobol() {
    sistema="iscobol"
    echo "sistema=iscobol" >> .config
    echo "$tracejada"
    echo "Escolha a versao do Iscobol:"
    echo "1) Versao 2018"
    echo "2) Versao 2020"
    echo "3) Versao 2023"
    echo "4) Versao 2024"
    echo "5) Versao 2025"
    read -rp "Escolha a versao -> " -n1 VERSAO
    echo

    case "$VERSAO" in
        1) _2018 ;;
        2) _2020 ;;
        3) _2023 ;;
        4) _2024 ;;
        5) _2025 ;;
        *)
            echo "Alternativa incorreta, saindo!"
            sleep 1
            exit 1
            ;;
    esac

    }


# Configuracao para Micro Focus Cobol
_setup_cobol() {
    sistema="cobol"
    {
        echo "sistema=cobol"
    } >> .config
}
# Funcoes de versao do IsCobol
_2018() {
    {
        echo "verclass=2018"
    } >> .config
    verclass="2018"
}
_2020() {
    {
        echo "verclass=2020"
    } >> .config
    verclass="2020"
}
_2023() {
    {
        echo "verclass=2023"
    } >> .config
    verclass="2023"
}
_2024() {
    {
        echo "verclass=2024"
    } >> .config
    verclass="2024"
}

_2025() {
    {
        echo "verclass=2025"
    } >> .config
    verclass="2025"
}
# Configuracoes adicionais
_setup_banco_de_dados() {
    echo "$tracejada"
    while true; do
        read -rp "Sistema em banco de dados [S/N]: " -n1 dbmaker
        echo
        if [[ "${dbmaker,,}" =~ ^[sn]$ ]]; then
            break
        else
            echo "Entrada inválida. Digite S ou N."
        fi
    done
    if [[ "${dbmaker,,}" == "s" ]]; then
        echo "dbmaker=s" >> .config
    else
        echo "dbmaker=n" >> .config
    fi
}
_setup_diretorios() {
    echo ${tracejada}
    echo "###     ( Nome de pasta no servidor )              ###"
    read -rp "Nome da pasta da base de dados (Ex: /dados_jisam): " base
    echo "base=${base}" >> .config
    echo ${tracejada}
    read -rp "Nome da pasta da base 2 (Opcional): " base2
    [[ -n "$base2" ]] && echo "base2=${base2}" >> .config || echo "#base2=" >> .config
    echo ${tracejada}
    read -rp "Nome da pasta da base 3 (Opcional): " base3
    [[ -n "$base3" ]] && echo "base3=${base3}" >> .config || echo "#base3=" >> .config
    echo ${tracejada}
}
_setup_acesso_remoto() {
    echo "###      ( FACILITADOR DE ACESSO REMOTO )         ###"
    while true; do
        read -rp "Ativar acesso facil (SSH) [S/N]: " -n1 acessossh
        echo
        if [[ "${acessossh,,}" =~ ^[sn]$ ]]; then
            break
        else
            echo "Entrada inválida. Digite S ou N."
        fi
    done
    if [[ "${acessossh,,}" == "s" ]]; then
        echo "acessossh=s" >> .config
    else
        echo "acessossh=n" >> .config
    fi
    echo ${tracejada}
    echo "###      ( IP do servidor da SAV )         ###"
    read -rp "Informe o IP do servidor: " ipserver
    echo "ipserver=${ipserver}" >> .config
    echo "IP do servidor:${ipserver}"
    echo ${tracejada}

    echo "###      ( Tipo de acesso        )         ###"
    while true; do
        read -rp "Servidor OFF [S/N]: " -n1 opt 
        echo
        if [[ "${opt,,}" =~ ^[sn]$ ]]; then
            break
        else
            echo "Entrada inválida. Digite S ou N."
        fi
    done
    if [[ "${opt,,}" == "s" ]]; then
        Offline="s"
        echo "Offline=s" >> .config
    else
        Offline="n"
        echo "Offline=n" >> .config
    fi
}

_setup_backup() {
    echo ${tracejada}
    echo "###     ( Nome de pasta no servidor da SAV )                ###"
    echo "Nome de pasta no servidor da SAV, informar somento o nome do cliente"
    read -rp "(Ex: cliente/\"NOME_da_pasta_do_CLIENTE\"): " enviabackup
    if [[ -z "$enviabackup" && "${Offline}" =~ ^[Nn]$ ]]; then
        echo "enviabackup=" >> .config
    elif [[ -n "$enviabackup" ]]; then
        echo "enviabackup=cliente/${enviabackup}" >> .config
    else
        echo "enviabackup=${Offline}" >> .config
    fi
}
_setup_empresa() {
echo ${tracejada}
echo "###     ( NOME DA empresa )                   ###"
echo "###   Nao pode conter espacos entre os nomes    ###"
echo ${tracejada}
    read -rp "Nome da Empresa (sem espacos): " empresa
    echo "empresa=${empresa}" >> .config
}

#---------- FUNcoES DE EDIcaO ----------#

# Edita uma variavel de forma interativa
_editar_variavel() {
    local nome="$1"
    local valor_atual="${!nome}"
    local tracejada="#-------------------------------------------------------------------#"

    while true; do
        read -rp "Deseja alterar ${nome} (valor atual: ${valor_atual})? [s/N] " alterar
        if [[ "${alterar,,}" =~ ^[sn]$ ]]; then
            break
        else
            echo "Entrada inválida. Digite S ou N."
        fi
    done
    if [[ "${alterar,,}" == "s" ]]; then
        case "$nome" in
            "sistema")
                echo "1) IsCobol"
                echo "2) Micro Focus Cobol"
                read -rp "Opcao [1-2]: " opt
                [[ "$opt" == "1" ]] && sistema="iscobol"
                [[ "$opt" == "2" ]] && sistema="cobol"
                ;;
            "dbmaker"|"acessossh")
                while true; do
                    read -rp "Novo valor (s/n): " opt
                    if [[ "${opt,,}" =~ ^[sn]$ ]]; then
                        [[ "${opt,,}" == "s" ]] && declare -g "$nome"="s"
                        [[ "${opt,,}" == "n" ]] && declare -g "$nome"="n"
                        break
                    else
                        echo "Entrada inválida. Digite s ou n."
                    fi
                done
                ;;
            "Offline")
                while true; do
                    read -rp "Sistema em modo Offline? (s/n): " opt            
                    if [[ "${opt,,}" =~ ^[sn]$ ]]; then
                        [[ "${opt,,}" == "s" ]] && declare -g "Offline"="s"
                        [[ "${opt,,}" == "n" ]] && declare -g "Offline"="n"
                        break
                    else
                        echo "Entrada inválida. Digite s ou n."
                    fi
                done
                ;;

            *)
                read -rp "Novo valor para ${nome}: " novo_valor
                declare -g "$nome"="$novo_valor"
                ;;
        esac
    fi
    echo "$tracejada"
}

# Recria os arquivos de configuracao
_recreate_config_files() {
    local tracejada="#-------------------------------------------------------------------#"
    echo "Recriando arquivos de configuracao..."

    {
        echo "sistema=${sistema}"
        [[ -n "$verclass" ]] && echo "verclass=${verclass}"
        echo "dbmaker=${dbmaker}"
        echo "acessossh=${acessossh}"
        echo "ipserver=${ipserver}"
        echo "Offline=${Offline}"
        echo "enviabackup=${enviabackup}"
        echo "empresa=${empresa}"
        echo "base=${base}"
        [[ -n "$base2" ]] && echo "base2=${base2}" || echo "#base2="
        [[ -n "$base3" ]] && echo "base3=${base3}" || echo "#base3="
    } > .config
    echo "$tracejada"
}

#---------- FUNcoES AUXILIARES ----------#
# Configura acesso SSH facilitado
_configure_ssh_access() {
    local SERVER_IP="${ipserver}"
    local SERVER_PORTA="${SERVER_PORTA:-41122}"
    local SERVER_USER="${USUARIO:-atualiza}"
    local CONTROL_PATH_BASE="/${TOOLS_DIR}/.ssh/control"

    if [[ -z "$SERVER_IP" || -z "$SERVER_PORTA" || -z "$SERVER_USER" ]]; then
        echo "Erro: Variaveis de servidor nao definidas para configuracao SSH."
        return 1
    fi

    local SSH_CONFIG_DIR
    SSH_CONFIG_DIR=$(dirname "$CONTROL_PATH_BASE")
    mkdir -p "$SSH_CONFIG_DIR" && chmod 700 "$SSH_CONFIG_DIR"

    local CONTROL_PATH="$CONTROL_PATH_BASE"
    mkdir -p "$CONTROL_PATH" && chmod 700 "$CONTROL_PATH"

    if [[ ! -f "/root/.ssh/config" ]]; then
        mkdir -p "/root/.ssh" && chmod 700 "/root/.ssh"
        cat << EOF > "/root/.ssh/config"
Host sav_servidor
    HostName $SERVER_IP
    Port $SERVER_PORTA
    User $SERVER_USER
    ControlMaster auto
    ControlPath $CONTROL_PATH/%r@%h:%p
    ControlPersist 10m
EOF
        chmod 600 "/root/.ssh/config"
        echo "Configuracao SSH criada."
    elif ! grep -q "Host sav_servidor" "/root/.ssh/config"; then
        echo "Adicionando configuracao 'sav_servidor' ao seu ~/.ssh/config..."
        cat << EOF >> "/root/.ssh/config"

Host sav_servidor
    HostName $SERVER_IP
    Port $SERVER_PORTA
    User $SERVER_USER
    ControlMaster auto
    ControlPath $CONTROL_PATH/%r@%h:%p
    ControlPersist 10m
EOF
    fi
}

#---------- PONTO DE ENTRADA PRINCIPAL ----------#

# Funcao principal que direciona para o modo correto
main() {

cd .. || exit 1

# Diretorio do script
TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Diretorios dos modulos e configuracoes
lib_dir="${TOOLS_DIR}/libs"
cfg_dir="${TOOLS_DIR}/cfg"
readonly TOOLS_DIR lib_dir cfg_dir

# Verifica se o diretorio libs existe
if [[ ! -d "${lib_dir}" ]]; then
    echo "ERRO: Diretorio ${lib_dir} nao encontrado."
    exit 1
fi

# Verifica se o diretorio cfg existe
if [[ ! -d "${cfg_dir}" ]]; then
    echo "ERRO: Diretorio ${cfg_dir} nao encontrado."
    exit 1
fi

    # Verificar modo de operacao
    if [[ "$1" == "--edit" ]]; then
        _edit_setup
    else
        # Verificar se os arquivos de configuracao ja existem

#        if [[ -f "${cfg_dir}/.config" ]]; then  # Comentada para converter de .atualizac para .config.

        if [[ -f "${cfg_dir}/.atualizac" ]]; then
            clear
            echo "Arquivos de configuracao ja existem."
            while true; do
                read -rp "Deseja sobrescrevê-los com a configuracao inicial? [s/N]: " choice
                if [[ "${choice,,}" =~ ^[sn]$ ]]; then
                    break
                else
                    echo "Entrada inválida. Digite S ou N."
                fi
            done
            if [[ "${choice,,}" == "s" ]]; then
                cd cfg || exit 1
                _initial_setup
            else
                echo "Operacao cancelada. Use './setup.sh --edit' para modificar."
                exit 0
            fi
        else
            mkdir -p cfg
            cd cfg || exit 1
            _initial_setup
        fi
    fi
}

# Executar a funcao principal
main "$@"