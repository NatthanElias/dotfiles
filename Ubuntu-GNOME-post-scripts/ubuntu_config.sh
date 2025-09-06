#!/bin/bash

# =========================================================================
# Script de Pós-Instalação e Personalização do GNOME (Ubuntu)
#
# O que este script faz:
# 1. Desativa o som de eventos do sistema.
# 2. Adiciona um segundo layout de teclado.
# 3. Altera atalhos do teclado.
# 4. Define um papel de parede personalizado.
# 5. Configura o comportamento da tecla Caps Lock.
# 6. Configura o Git para salvar credenciais no GNOME Keyring.
# =========================================================================

echo "🚀 Iniciando a personalização do ambiente GNOME..."
echo ""

echo "-> 1/6: Desativando o som de captura de tela e outros eventos..."
gsettings set org.gnome.desktop.sound event-sounds false
echo "    ✅ Sons de eventos do sistema desativados."
echo ""

echo "-> 2/6: Configurando layouts de teclado..."
# Verifica a variável de ambiente $LANG que define o idioma/região
if [[ "$LANG" == "pt_BR"* ]]; then
    echo "    Idioma detectado: Português (Brasil). Adicionando layout Inglês (US)..."
    # A ordem dos layouts importa: o primeiro é o principal.
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'br'), ('xkb', 'us')]"
    echo "    ✅ Layouts configurados: [br, us]"
elif [[ "$LANG" == "en"* ]]; then
    echo "    Idioma detectado: Inglês. Adicionando layout Português (Brasil)..."
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'br')]"
    echo "    ✅ Layouts configurados: [us, br]"
else
    echo "    ⚠️  Idioma do sistema não é 'pt_BR' ou 'en'. Pulando a configuração de layouts."
fi
echo ""

echo "-> 3/6: Alterando atalhos do teclado..."
echo "    - Configurando 'Mudar layout' para 'Ctrl+Espaço'..."
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Control>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Control><Shift>space']"
echo "    - Configurando 'Captura de tela interativa' para 'Ctrl+Shift+S'..."
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['<Control><Shift>s']"
echo "    ✅ Atalhos personalizados foram aplicados."
echo ""

echo "-> 4/6: Configurando o papel de parede..."
# Define o caminho relativo da imagem
WALLPAPER_RELATIVE_PATH="./wallpaper/bota_garrao_gpteco.png"

# Converte o caminho relativo para um caminho absoluto
# gsettings precisa do caminho completo para funcionar corretamente
WALLPAPER_ABSOLUTE_PATH=$(readlink -f "$WALLPAPER_RELATIVE_PATH")

# Verifica se o arquivo de imagem realmente existe no caminho absoluto
if [ -f "$WALLPAPER_ABSOLUTE_PATH" ]; then
    # Adiciona o prefixo 'file://' necessário para o gsettings
    WALLPAPER_URI="file://$WALLPAPER_ABSOLUTE_PATH"

    echo "    - Aplicando imagem: $WALLPAPER_ABSOLUTE_PATH"
    # Define a imagem para os modos claro e escuro para garantir consistência
    gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER_URI"
    gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER_URI"
    
    # Define o modo de ajuste como 'scaled' (manter proporções e preencher)
    gsettings set org.gnome.desktop.background picture-options 'scaled'

    echo "    ✅ Papel de parede aplicado com sucesso."
else
    echo "    ⚠️  Aviso: O arquivo de papel de parede não foi encontrado em '$WALLPAPER_ABSOLUTE_PATH'."
    echo "    ➡️  Pulando esta etapa. Verifique se a pasta 'wallpaper' está no mesmo local que o script."
fi
echo ""

echo "-> 5/6: Configurando a tecla Caps Lock..."
CAPS_STATUS=$(gsettings get org.gnome.desktop.input-sources xkb-options)

# Verifica se a string de configuração contém a opção 'caps:none'
if [[ "$CAPS_STATUS" == *"'caps:none'"* ]]; then
    echo "    ℹ️  Sua tecla Caps Lock já está desativada."
    read -p "    Deseja reativá-la? (s/N) " -n 1 -r REPLY
    echo

    if [[ $REPLY =~ ^[Ss]$ ]]; then
        # Usa um array vazio "[]" para restaurar o comportamento padrão (ativado)
        gsettings set org.gnome.desktop.input-sources xkb-options "[]"
        echo "    ✅ Caps Lock foi REATIVADO."
    else
        echo "    ➡️  Nenhuma alteração feita. O Caps Lock permanece desativado."
    fi
else
    echo "    ℹ️  Sua tecla Caps Lock está ativada."
    read -p "    Deseja desativá-la? (S/n) " -n 1 -r REPLY
    echo

    # A condição abaixo torna "Sim" a opção padrão se o usuário apenas pressionar Enter
    if [[ -z "$REPLY" || $REPLY =~ ^[Ss]$ ]]; then
        gsettings set org.gnome.desktop.input-sources xkb-options "['caps:none']"
        echo "    ✅ Caps Lock foi DESATIVADO."
    else
        echo "    ➡️  Nenhuma alteração feita. O Caps Lock permanece ativado."
    fi
fi
echo ""

# --- INÍCIO DA NOVA SEÇÃO ---
echo "-> 6/6: Configurando o Git Credential Helper (para salvar senhas)..."

# Lista de pacotes necessários para esta etapa
PACKAGES_NEEDED=("git" "libsecret-1-0")
PACKAGES_TO_INSTALL=()

# Verifica se cada pacote está instalado
for pkg in "${PACKAGES_NEEDED[@]}"; do
    if ! dpkg -s "$pkg" &> /dev/null; then
        PACKAGES_TO_INSTALL+=("$pkg")
    fi
done

# Se houver pacotes faltando, pergunta ao usuário se deseja instalá-los
if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo "    ℹ️  Para configurar o Git, os seguintes pacotes são necessários: ${PACKAGES_TO_INSTALL[*]}"
    read -p "    Deseja instalá-los agora? (S/n) " -n 1 -r REPLY
    echo
    if [[ -z "$REPLY" || $REPLY =~ ^[Ss]$ ]]; then
        echo "    - Instalando dependências..."
        # É necessário sudo para instalar pacotes
        sudo apt-get update
        sudo apt-get install -y "${PACKAGES_TO_INSTALL[@]}"
        echo "    ✅ Dependências instaladas."
    else
        echo "    ➡️  Instalação cancelada. Pulando a configuração do Git."
        # Sai da seção se o usuário recusar a instalação
        echo ""
        echo "🎉 Configuração concluída!"
        exit 0
    fi
fi

# Configura o Git para usar o libsecret, que se integra com o GNOME Keyring
# Esta é a forma segura de salvar tokens de acesso no Ubuntu
echo "    - Configurando o Git para usar o cofre de senhas do sistema (GNOME Keyring)..."
git config --global credential.helper /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret

echo "    ✅ Credential Helper do Git configurado com sucesso."
echo "    ℹ️  Na próxima vez que usar 'git push', uma janela solicitará seu usuário e token, que serão salvos."
echo ""
# --- FIM DA NOVA SEÇÃO ---

echo "🎉 Configuração concluída!"
