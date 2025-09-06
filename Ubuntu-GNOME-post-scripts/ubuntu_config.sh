#!/bin/bash

# =========================================================================
# Script de Pós-Instalação e Personalização do GNOME (Ubuntu/Debian)
#
# O que este script faz:
# 1. Desativa o som de eventos do sistema.
# 2. Adiciona um segundo layout de teclado.
# 3. Altera atalhos do teclado.
# 4. Define um papel de parede personalizado.
# 5. Configura o comportamento da tecla Caps Lock.
# 6. Configura o Git para salvar credenciais via OAuth.
# 7. Adiciona suporte ao Flatpak e ao repositório Flathub.
# 8. Instala o Gerenciador de Extensões (Extension Manager).
# =========================================================================

echo "🚀 Iniciando a personalização do ambiente GNOME..."
echo ""

echo "-> 1/8: Desativando o som de captura de tela e outros eventos..."
gsettings set org.gnome.desktop.sound event-sounds false
echo "    ✅ Sons de eventos do sistema desativados."
echo ""

echo "-> 2/8: Configurando layouts de teclado..."
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

echo "-> 3/8: Alterando atalhos do teclado..."
echo "    - Configurando 'Mudar layout' para 'Ctrl+Espaço'..."
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Control>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Control><Shift>space']"
echo "    - Configurando 'Captura de tela interativa' para 'Ctrl+Shift+S'..."
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['<Control><Shift>s']"
echo "    ✅ Atalhos personalizados foram aplicados."
echo ""

echo "-> 4/8: Configurando o papel de parede..."
# Define o caminho relativo da imagem
WALLPAPER_RELATIVE_PATH="./wallpaper/bota_garrao_gpteco.png"

# Converte o caminho relativo para um caminho absoluto
WALLPAPER_ABSOLUTE_PATH=$(readlink -f "$WALLPAPER_RELATIVE_PATH")

# Verifica se o arquivo de imagem realmente existe no caminho absoluto
if [ -f "$WALLPAPER_ABSOLUTE_PATH" ]; then
    WALLPAPER_URI="file://$WALLPAPER_ABSOLUTE_PATH"
    echo "    - Aplicando imagem: $WALLPAPER_ABSOLUTE_PATH"
    gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER_URI"
    gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER_URI"
    gsettings set org.gnome.desktop.background picture-options 'scaled'
    echo "    ✅ Papel de parede aplicado com sucesso."
else
    echo "    ⚠️  Aviso: O arquivo de papel de parede não foi encontrado em '$WALLPAPER_ABSOLUTE_PATH'."
    echo "    ➡️  Pulando esta etapa."
fi
echo ""

echo "-> 5/8: Configurando a tecla Caps Lock..."
CAPS_STATUS=$(gsettings get org.gnome.desktop.input-sources xkb-options)

if [[ "$CAPS_STATUS" == *"'caps:none'"* ]]; then
    echo "    ℹ️  Sua tecla Caps Lock já está desativada."
else
    echo "    ℹ️  Sua tecla Caps Lock está ativada."
    read -p "    Deseja desativá-la? (S/n) " -n 1 -r REPLY
    echo
    if [[ -z "$REPLY" || $REPLY =~ ^[Ss]$ ]]; then
        gsettings set org.gnome.desktop.input-sources xkb-options "['caps:none']"
        echo "    ✅ Caps Lock foi DESATIVADO."
    else
        echo "    ➡️  Nenhuma alteração feita."
    fi
fi
echo ""

echo "-> 6/8: Configurando o Git Credential Helper (método OAuth)..."
PACKAGES_NEEDED=("git" "git-credential-oauth")
PACKAGES_TO_INSTALL=()

for pkg in "${PACKAGES_NEEDED[@]}"; do
    if ! dpkg -s "$pkg" &> /dev/null; then
        PACKAGES_TO_INSTALL+=("$pkg")
    fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo "    ℹ️  Pacotes necessários para o Git: ${PACKAGES_TO_INSTALL[*]}"
    read -p "    Deseja instalá-los agora? (S/n) " -n 1 -r REPLY
    echo
    if [[ -z "$REPLY" || $REPLY =~ ^[Ss]$ ]]; then
        sudo apt-get update
        sudo apt-get install -y "${PACKAGES_TO_INSTALL[@]}"
        echo "    ✅ Dependências instaladas."
    else
        echo "    ➡️  Instalação cancelada. Pulando a configuração do Git."
    fi
fi
git config --global credential.helper oauth
echo "    ✅ Credential Helper do Git configurado para usar OAuth."
echo ""


echo "-> 7/8: Configurando o suporte a Flatpak..."
echo "    - Instalando pacotes base para Flatpak e integração com a loja de aplicativos..."
sudo apt-get update
sudo apt-get install -y flatpak gnome-software gnome-software-plugin-flatpak gnome-software-plugin-snap
echo "    - Adicionando o repositório Flathub (principal fonte de apps Flatpak)..."
# O comando abaixo adiciona o repositório principal de aplicativos Flatpak para o usuário atual
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
echo "    ✅ Suporte a Flatpak configurado com sucesso."
echo ""

echo "-> 8/8: Instalando o Gerenciador de Extensões (Extension Manager)..."
# ID do aplicativo Extension Manager no Flathub
EXTENSION_MANAGER_ID="com.mattjakeman.ExtensionManager"

# Verifica se o Extension Manager já está instalado via Flatpak
if ! flatpak info "$EXTENSION_MANAGER_ID" &> /dev/null; then
    echo "    - Gerenciador de Extensões não encontrado. Instalando via Flatpak..."
    # Instala o aplicativo de forma não interativa
    flatpak install -y flathub "$EXTENSION_MANAGER_ID"
    echo "    ✅ Gerenciador de Extensões instalado."
else
    echo "    ℹ️  O Gerenciador de Extensões já está instalado."
fi
echo "    💡 Dica: Abra o novo aplicativo 'Extension Manager' para procurar e instalar extensões para o GNOME, como a popular 'Dash to Dock'."
echo ""

echo "🎉 Configuração concluída!"
