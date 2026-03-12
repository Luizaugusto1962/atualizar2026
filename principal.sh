#!/usr/bin/env bash
#
# SISTEMA SAV - Script de Atualizacao Modular
# Versao: 12/03/2026-00
# Autor: Luiz Augusto
# Email: luizaugusto@sav.com.br
#
# Versao do sistema
readonly UPDATE="12/03/26-v.2026"
export UPDATE

# Diretorio do script principal
TOOLS_DIR="${TOOLS_DIR:-$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")}"

# Diretorios dos modulos e configuracoes
lib_dir="${lib_dir:-${TOOLS_DIR}/libs}"       # Diretorio dos modulos de biblioteca
cfg_dir="${cfg_dir:-${TOOLS_DIR}/cfg}"        # Diretorio de configuracoes
export TOOLS_DIR lib_dir cfg_dir  

# Diretórios obrigatórios
aux_dirs=("${lib_dir}" "${cfg_dir}")  # Lista de diretorios obrigatorios

for dir in "${aux_dirs[@]}"; do
    [[ -z "${dir}" ]] && { printf "ERRO: Variavel de diretorio nao definida.\n"; exit 1; }
    [[ -d "${dir}" ]] || {
        printf '%s\n' "ERRO: O diretorio '${dir}' nao foi encontrado."
        printf "Certifique-se de que os arquivos/modulos correspondentes estao instalados corretamente.\n"
        _read_sleep 2
        exit 1
    }
done

# Funcao para carregar modulos com verificacao
_carregar_modulo() {
    local modulo="$1"
    local caminho="${lib_dir}/${modulo}"
    if [[ ! -f "${caminho}" ]]; then
        printf "%s\n" "ERRO: Modulo ${modulo} nao encontrado em ${caminho}"
        _read_sleep 2
        exit 1
    fi
    
    if [[ ! -r "${caminho}" ]]; then
        printf "%s\n" "ERRO: Modulo ${modulo} nao pode ser lido"
        _read_sleep 2
        exit 1
    fi
    
    # shellcheck source=/dev/null
    if ! source "${caminho}"; then
        printf "%s\n" "ERRO: Falha ao carregar modulo ${modulo}"
        _read_sleep 2
        exit 1
    fi
}

# Carregamento sequencial dos modulos (ordem importante)
_carregar_modulo "utils.sh"      # Utilitarios basicos primeiro
_carregar_modulo "config.sh"     # Configuracoes
_carregar_modulo "auth.sh"       # Autenticacao
_carregar_modulo "lembrete.sh"   # Sistema de lembretes
_carregar_modulo "vaievem.sh"      # Operacoes de rede
_carregar_modulo "sistema.sh"    # Informacoes do sistema
_carregar_modulo "arquivos.sh"   # Gestao de arquivos
_carregar_modulo "backup.sh"     # Sistema de backup
_carregar_modulo "programas.sh"  # Gestao de programas
_carregar_modulo "biblioteca.sh" # Gestao de biblioteca
_carregar_modulo "help.sh"       # Sistema de ajuda
_carregar_modulo "menus.sh"       # Menu principal

# Funcao principal de inicializacao
_inicializar_sistema() {
    # Carregar e validar configuracoes
    _carregar_configuracoes
    
    # Verificar dependências
    _check_instalado

    # Validar diretorios
    _validar_diretorios
    
    # Configurar ambiente
    _configurar_ambiente
    
    # Executar limpeza automatica diaria
    _executar_expurgador_diario
}

# Funcao principal do programa
main() {
    # Tratamento de sinais para limpeza
    trap '_resetando' EXIT INT TERM
    
    # Inicializar sistema
    _inicializar_sistema
    
    # Autenticacao
    if ! _login; then
        printf "Autenticacao falhou. Saindo...\n"
        exit 1
    fi
    
    # Mostrar mensagem de entrada (se existe) e opcao para excluir
    _mostrar_aviso

    # Mostrar notas se existirem
    _mostrar_notas_iniciais
    
    # Executar menu principal
    _principal
}

# Verificar se esta sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi