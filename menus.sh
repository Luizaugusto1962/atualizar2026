#!/usr/bin/env bash
#
# menus.sh - Sistema de Menus com Suporte a Ajuda
# Responsavel pela apresentacao e navegacao dos menus do sistema
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 17/03/2026-00
# Autor: Luiz Augusto
#
# Variaveis globais esperadas
sistema="${sistema:-}"                    # Nome do sistema (iscobol, savatu, transpc).
cfg_dir="${cfg_dir:-${TOOLS_DIR}/cfg}"    # Diretorio de configuracoes
base="${base:-}"                          # Caminho do diretorio da primeira base de dados.
base2="${base2:-}"                        # Caminho do diretorio da segunda base de dados.
dbmaker="${dbmaker:-}"                    # Caminho do diretorio da base de dados do dbmaker.
empresa="${empresa:-}"                    # Nome da empresa (usado para exibir no menu)

#---------- FUNCAO AUXILIAR DE LEITURA ----------#

# Funcao auxiliar para leitura de opcao com suporte a ajuda contextual
# Uso: _ler_opcao_menu "contexto"
# Retorna: 0 se opcao normal, 1 se comando de ajuda processado
_ler_opcao_menu() {
    local contexto="${1:-geral}"
    
    # Exibir linha de ajuda
    _linha "="
    printf '%b\n' "${BLUE}Ajuda: Digite ${YELLOW}M${BLUE} (manual) | ${YELLOW}H${BLUE} (help)${NORM}"
    _linha "=" "${GREEN}"
    
    # Ler opcao do usuario
    read -rp "${YELLOW} Digite a opcao desejada -> ${NORM}" opcao
    
    # Verificar comandos de ajuda
    case "${opcao,,}" in
        "?"|"h"|"help"|"ajuda")
            _exibir_ajuda_contextual "$contexto"
            return 1
            ;;
        "m"|"manual")
            _exibir_manual_completo
            return 1
            ;;
    esac
    
    # Retorna 0 para processar a opcao normalmente
    return 0
}

#---------- MENU PRINCIPAL ----------#
# Menu principal do sistema
_principal() {
    while true; do
        tput clear
        printf "\n"
        
        # Cabecalho
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu Principal"
        _linha
        _mensagec "${GREEN}" ".. Empresa: ${WHITE}${empresa}${GREEN} .."
        _linha
        _mensagec "${CYAN}" "_| Sistema: ${sistema} - Versao do Iscobol: ${verclass} |_"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}" "-" "${YELLOW}"
        printf "\n"
        # Opcoes do menu
        _mensagec "${GREEN}" "1${NORM} -|: Atualizar Programa(s) "
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Atualizar Biblioteca  "
        printf "\n"
        _mensagec "${GREEN}" "3${NORM} -|: Gerenciar Arquivos    "
        printf "\n"
        _mensagec "${GREEN}" "4${NORM} -|: Ferramentas           "
        printf "\n"        
        _mensagec "${GREEN}" "0${NORM} -|: Sistema de Ajuda      "
        printf "\n"
        _meia_linha "-" "${YELLOW}" "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Sair do Sistema "
        printf "\n"
        _mensaged "${BLUE}" "${UPDATE}"     
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "principal"; then
            continue
        fi

        case "${opcao}" in
            1) _menu_programas ;;
            2) _menu_biblioteca ;;
            3) _menu_arquivos ;;
            4) _menu_ferramentas ;;
            0) _menu_ajuda_principal ;;
            9) 
                clear
                _encerrar_programa 0
                ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

#---------- MENU DE PROGRAMAS ----------#

# Menu de atualizacao de programas
_menu_programas() {
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu de Programas"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" "Escolha o tipo de Atualizacao:"
        _meia_linha "-" "${YELLOW}" 
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Programa(s) ON-Line       "
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Programa(s) OFF-Line      "
        printf "\n"
        _mensagec "${GREEN}" "3${NORM} -|: Programa(s) em Pacote     "
        printf "\n\n"
        _mensagec "${PURPLE}" "Escolha Desatualizar:         "
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "4${NORM} -|: Voltar programa Atualizado"
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n" 
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        
        if [[ -n "${verclass}" ]]; then
            printf "\n"
            _mensaged "${BLUE}" "Versao do Iscobol - ${verclass}"
        fi
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "programas"; then
            continue
        fi

        case "${opcao}" in
            1) _atualizar_programa_online ;;
            2) _atualizar_programa_offline ;;
            3) _atualizar_programa_pacote ;;
            4) _reverter_programa ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

#---------- MENU DE BIBLIOTECA ----------#

# Menu de atualizacao de biblioteca
_menu_biblioteca() {
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu da Biblioteca"
        _linha "="
        printf "\n"
        _mensagec "${PURPLE}" "Escolha o local da Biblioteca:      "
        _meia_linha "-" "${YELLOW}"
        printf "\n" 
        _mensagec "${GREEN}" "1${NORM} -|: Atualizacao do Transpc      "
        printf "\n" 
#        _mensagec "${GREEN}" "2${NORM} -|: Atualizacao do Savatu       "
#        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Atualizacao OFF-Line        "
        printf "\n\n"
        _mensagec "${PURPLE}" "Escolha Desatualizar:               "
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "3${NORM} -|: Voltar Programa(s) da Biblioteca"
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        
        # Antes de usar, carregar o arquivo
        if [[ -f "${cfg_dir}/.versao" ]]; then
            "." "${cfg_dir}/.versao"
        fi

        if [[ -n "${VERSAOANT}" ]]; then
            printf "\n"
            _mensaged "${BLUE}" "Versao Anterior - ${VERSAOANT}"
        fi
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "biblioteca"; then
            continue
        fi

        case "${opcao}" in
            1) _atualizar_transpc ;;
            2) _atualizar_biblioteca_offline ;;
            3) _reverter_biblioteca ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

####
#---------- MENU DE ARQUIVOS ----------#

# Menu de arquivos do sistema
_menu_arquivos() {
    while true; do
        tput clear
        printf "\n"
        
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu Gerencial dos Arquivos"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        
        # Verificar se sistema tem banco de dados
        if [[ "${dbmaker}" != "s" ]]; then
            _mensagec "${GREEN}" "1${NORM} -|: Recuperar Arquivos        "
            printf "\n" 
            _mensagec "${GREEN}" "2${NORM} -|: Rotinas de Backup         "
            printf "\n"
        fi
        _mensagec "${GREEN}" "3${NORM} -|: Enviar e Receber Arquivos "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "4${NORM} -|: Arquivos Temporarios      "
        printf "\n"
        _mensagec "${GREEN}" "5${NORM} -|: Expurgador de Arquivos    "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "arquivos"; then
            continue
        fi

        case "${opcao}" in
            1) 
                if [[ "${dbmaker}" = "s" ]]; then
                    _opinvalida
                    _read_sleep 1
                else
                    _menu_recuperar_arquivos
                fi
                ;;
            2) 
                if [[ "${dbmaker}" = "s" ]]; then
                    _opinvalida
                    _read_sleep 1
                else
                    _menu_backup
                fi
                ;;
            3) _menu_transferencia_arquivos ;;
            4) _menu_temporarios ;;
            5) _executar_expurgador "arquivos" ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

###
#---------- MENU DE FERRAMENTAS ----------#

# Menu de ferramentas do sistema
_menu_ferramentas() {
    while true; do
        tput clear
        printf "\n"
        
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu das Ferramentas"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}"
        printf "\n"

        # Opcoes do menu 
        if [[ "${sistema}" = "iscobol" ]]; then
            _mensagec "${GREEN}" "1${NORM} -|: Versao do Iscobol         "
        else
            _mensagec "${GREEN}" "1${NORM} -|: Funcao nao disponivel     "
        fi
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Versao do Linux           "
        printf "\n"
        _mensagec "${GREEN}" "3${NORM} -|: Parametros                "
        printf "\n"
        _mensagec "${GREEN}" "4${NORM} -|: Update                    "
        printf "\n" 
        _mensagec "${GREEN}" "5${NORM} -|: Lembretes                 "
        printf "\n"
        _mensagec "${GREEN}" "6${NORM} -|: Avisos iniciais           "
        printf "\n"
        _mensagec "${GREEN}" "7${NORM} -|: Logs do sistema           "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior  "
        printf "\n"
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "ferramentas"; then
            continue
        fi

        case "${opcao}" in
            1) _mostrar_versao_iscobol ;;
            2) _mostrar_versao_linux ;;
            3) _menu_setups ;;
            4) _executar_update ;;
            5) _menu_lembretes ;;
            6) _menu_avisos ;;
            7) _menu_logs ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

#---------- MENU DE TEMPORARIOS ----------#

# Menu de limpeza de arquivos temporarios
_menu_temporarios() {
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu de Limpeza"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Limpeza dos Arquivos Temporarios "
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Adicionar Arquivos no limpetmp2  "
        printf "\n"
        _mensagec "${GREEN}" "3${NORM} -|: Listar os registros dos Arquivos "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "temporarios"; then
            continue
        fi

        case "${opcao}" in
            1) _executar_limpeza_temporarios ;;
            2) _adicionar_arquivo_lixo ;;
            3) _lista_arquivos_lixo ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

#---------- MENU DE RECUPERACAO ----------#

# Menu de recuperacao de arquivos
_menu_recuperar_arquivos() {
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu de Recuperacao de Arquivo(s)"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Um arquivo ou Todos   "
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Arquivos Principais   "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "recuperacao"; then
            continue
        fi

        case "${opcao}" in
            1) _recuperar_arquivo_especifico ;;
            2) _recuperar_arquivos_principais ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

#---------- MENU DE BACKUP ----------#

# Menu de backup do sistema
_menu_backup() {
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu de Backup(s)"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Backup da base de dados  "
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Restaurar base de dados  "
        printf "\n"
        _mensagec "${GREEN}" "3${NORM} -|: Enviar Backup            "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "backup"; then
            continue
        fi

        case "${opcao}" in
            1) _executar_backup ;;
            2) _restaurar_backup ;;
            3) _enviar_backup_avulso ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}


#---------- MENU DE TRANSFERENCIA ----------#

# Menu de envio e recebimento de arquivos
_menu_transferencia_arquivos() {
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu de Enviar e Receber Arquivo(s)"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Enviar arquivo(s)     "
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Receber arquivo(s)    "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "transferencia"; then
            continue
        fi

        case "${opcao}" in
            1) _enviar_arquivo_avulso ;;
            2) _receber_arquivo_avulso ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

# Menu de setups do sistema
_menu_setups() {
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu de Setup do Sistema"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Consulta de setup    "
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Manutencao de setup  "
        printf "\n"
        _mensagec "${GREEN}" "3${NORM} -|: Validar configuracao "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "setups"; then
            continue
        fi

        case "${opcao}" in
            1) 
                _mostrar_parametros
                ;;
            2) 
               _manutencao_setup
                # Apos a manutencao, recarregar as configuracoes
                if [[ -f "${cfg_dir}/.config" ]]; then
                    "." "${cfg_dir}/.config"
                    _mensagec "${GREEN}" "Configuracoes recarregadas com sucesso!"
                    _read_sleep 2
                fi
                ;;
            3)
                _validar_configuracao
                _press
                ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}


#---------- MENU DE LEMBRETES ----------#

# Menu de bloco de notas/lembretes
_menu_lembretes() {
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" " Bloco de Notas "
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Escrever nova nota    "
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Visualizar nota       "
        printf "\n"
        _mensagec "${GREEN}" "3${NORM} -|: Editar nota           "
        printf "\n"
        _mensagec "${GREEN}" "4${NORM} -|: Apagar nota           "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "lembretes"; then
            continue
        fi

        case "${opcao}" in

            1) _escrever_nova_nota ;;
            2) 
                if [[ -f "${cfg_dir}/lembrete" ]]; then
                    _visualizar_notas_arquivo "${cfg_dir}/lembrete"
                else
                    _mensagec "${YELLOW}" "Arquivo de notas nao encontrado"
                    _read_sleep 1
                fi
                ;;
            3) _editar_nota_existente ;;
            4) _apagar_nota_existente ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

# Menu de aviso inicial
_menu_avisos() {
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu de Aviso(s)"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Gerar Aviso   "
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Editar Aviso  "
        printf "\n"
        _mensagec "${GREEN}" "3${NORM} -|: Apagar Aviso  "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "aviso"; then
            continue
        fi

        case "${opcao}" in
            1) _gerar_aviso_entrada ;;
            2) _editar_aviso_existente ;;
            3) _apagar_aviso_entrada ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

# Menu dos logs do sistema
_menu_logs() {
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu dos Logs"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Log de Atualizacao"
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Log de Limpeza    "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        
        # Usar funcao centralizada
        local opcao
        if ! _ler_opcao_menu "logs"; then
            continue
        fi

        case "${opcao}" in
            1) _listar_logs_atualizacao ;;
            2) _listar_logs_limpeza ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

#---------- MENU PRINCIPAL DE AJUDA ----------#

# Menu principal do sistema de ajuda
_menu_ajuda_principal() {
    # Verifica se manual existe ao entrar no menu
    if ! _verificar_manual; then
        _press
        return
    fi
    
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "SISTEMA DE AJUDA"
        _linha 
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Manual Completo    "
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Ajuda Rapida       "
        printf "\n"
        _mensagec "${GREEN}" "3${NORM} -|: Ajuda no Geral     "
        printf "\n"
        _mensagec "${GREEN}" "4${NORM} -|: Buscar no Manual   "
        printf "\n"
        _mensagec "${GREEN}" "5${NORM} -|: Exportar Manual    "
        printf "\n"
        _mensagec "${GREEN}" "6${NORM} -|: Ajuda por Contexto "
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        _linha "=" "${GREEN}"
        
        local opcao
        read -rp "${YELLOW}Digite a opcao desejada ->: ${NORM}" opcao

        case "${opcao}" in
            1) _exibir_manual_completo ;;
            2) _ajuda_rapida ;;
            3) _ajuda_no_geral ;;
            4) _buscar_manual ;;
            5) _exportar_manual ;;
            6) _menu_selecao_contexto ;;
            9) return ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}


#---------- MENU DE ESCOLHA DE BASE ----------#

# Menu para escolher base de dados
_menu_escolha_base() {
    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Escolha a Base"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Base em ${raiz}${base}"
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Base em ${raiz}${base2}"
        printf "\n"
        
        if [[ -n "${base3}" ]]; then
            _mensagec "${GREEN}" "3${NORM} -|: Base em ${raiz}${base3}"
            printf "\n"
        fi
        
        printf "\n"
        _meia_linha "-" "${YELLOW}"
        printf "\n"
        _mensagec "${WHITE}" "9${RED} -|: Menu Anterior "
        printf "\n"
        _linha "=" "${GREEN}"

        local opcao
        read -rp "${YELLOW} Digite a opcao desejada -> ${NORM}" opcao

        case "${opcao}" in
            1) 
                if _definir_base_trabalho "base"; then
                    return 0
                fi
                ;;
            2) 
                if _definir_base_trabalho "base2"; then
                    return 0
                fi
                ;;
            3) 
                if [[ -n "${base3}" ]]; then
                    if _definir_base_trabalho "base3"; then
                        return 0
                    fi
                else
                    _opinvalida
                    _read_sleep 1
                fi
                ;;
            9) return 1 ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

#---------- MENU DE TIPO DE BACKUP ----------#
# Menu para escolher tipo de backup

_menu_tipo_backup() {

    while true; do
        clear
        printf "\n"
        _linha "=" "${GREEN}"
        _mensagec "${RED}" "Menu de Tipo de Backup(s)"
        _linha
        printf "\n"
        _mensagec "${PURPLE}" " Escolha a opcao:"
        printf "\n"
        _mensagec "${GREEN}" "1${NORM} -|: Backup Completo      "
        printf "\n"
        _mensagec "${GREEN}" "2${NORM} -|: Backup Incremental   "
        printf "\n\n"
        _mensagec "${WHITE}" "9${NORM} -|: ${RED}Menu Anterior"
        printf "\n"
        _linha "=" "${GREEN}"

        local opcao
        read -rp "${YELLOW} Digite a opcao desejada -> ${NORM}" opcao

        case "${opcao}" in
            1) 
                tipo_backup="completo"
                export tipo_backup
                return 0
                ;;
            2) 
                tipo_backup="incremental"
                export tipo_backup
                return 0
                ;;
            9) 
                tipo_backup=""
                export tipo_backup
                return 1
                ;;
            *)
                _opinvalida
                _read_sleep 1
                ;;
        esac
    done
}

#---------- FUNcoES AUXILIARES DE MENU ----------#

# Define a base de trabalho atual
# Parametros: $1=nome_da_base (base, base2, base3)
_definir_base_trabalho() {
    local base_var="$1"
    local base_dir="${!base_var}"

    if [[ -z "${raiz}" ]] || [[ -z "${base_dir}" ]]; then
        _mensagec "${RED}" "Erro: Variaveis de configuracao nao definidas"
        _linha
        _read_sleep 2
        return 1
    fi
    
    export base_trabalho="${raiz}${base_dir}"
    
    if [[ ! -d "${base_trabalho}" ]]; then
        _mensagec "${RED}" "Erro: Diretorio ${base_trabalho} nao encontrado"
        _linha
        _read_sleep 2
        return 1
    fi
    
    _mensagec "${GREEN}" "Base de trabalho definida: ${base_trabalho}"
    return 0
}

