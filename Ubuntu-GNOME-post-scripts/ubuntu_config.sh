#!/bin/bash

# =========================================================================
# Script de Pós-Instalação e Personalização do GNOME (Ubuntu)
#
# O que este script faz:
# 1. Desativa o som de eventos do sistema (como o da captura de tela).
# 2. Adiciona um segundo layout de teclado com base no idioma do sistema.
# 3. Altera atalhos do teclado para captura de tela e troca de layout.
# 4. Verifica o estado do Caps Lock e pergunta ao usuário se deseja alterá-lo.
# =========================================================================

echo "🚀 Iniciando a personalização do ambiente GNOME..."
echo ""

echo "-> 1/4: Desativando o som de captura de tela e outros eventos..."
gsettings set org.gnome.desktop.sound event-sounds false
echo "   ✅ Sons de eventos do sistema desativados."
echo ""

echo "-> 2/4: Configurando layouts de teclado..."
# Verifica a variável de ambiente $LANG que define o idioma/região
if [[ "$LANG" == "pt_BR"* ]]; then
    echo "   Idioma detectado: Português (Brasil). Adicionando layout Inglês (US)..."
    # A ordem dos layouts importa: o primeiro é o principal.
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'br'), ('xkb', 'us')]"
    echo "   ✅ Layouts configurados: [br, us]"
elif [[ "$LANG" == "en"* ]]; then
    echo "   Idioma detectado: Inglês. Adicionando layout Português (Brasil)..."
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'br')]"
    echo "   ✅ Layouts configurados: [us, br]"
else
    echo "   ⚠️ Idioma do sistema não é 'pt_BR' ou 'en'. Pulando a configuração de layouts."
fi
echo ""

echo "-> 3/4: Alterando atalhos do teclado..."
echo "   - Configurando 'Mudar layout' para 'Ctrl+Espaço'..."
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Control>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Control><Shift>space']"
echo "   - Configurando 'Captura de tela interativa' para 'Ctrl+Shift+S'..."
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['<Control><Shift>s']"
echo "   ✅ Atalhos personalizados foram aplicados."
echo ""

echo "-> 4/4: Configurando a tecla Caps Lock..."
CAPS_STATUS=$(gsettings get org.gnome.desktop.input-sources xkb-options)

# Verifica se a string de configuração contém a opção 'caps:none'
if [[ "$CAPS_STATUS" == *"'caps:none'"* ]]; then
    echo "   ℹ️  Sua tecla Caps Lock já está desativada."
    read -p "   Deseja reativá-la? (s/N) " -n 1 -r REPLY
    echo

    if [[ $REPLY =~ ^[Ss]$ ]]; then
        # Usa um array vazio "[]" para restaurar o comportamento padrão (ativado)
        gsettings set org.gnome.desktop.input-sources xkb-options "[]"
        echo "   ✅ Caps Lock foi REATIVADO."
    else
        echo "   ➡️  Nenhuma alteração feita. O Caps Lock permanece desativado."
    fi
else
    echo "   ℹ️  Sua tecla Caps Lock está ativada."
    read -p "   Deseja desativá-la? (S/n) " -n 1 -r REPLY
    echo

    # A condição abaixo torna "Sim" a opção padrão se o usuário apenas pressionar Enter
    if [[ -z "$REPLY" || $REPLY =~ ^[Ss]$ ]]; then
        gsettings set org.gnome.desktop.input-sources xkb-options "['caps:none']"
        echo "   ✅ Caps Lock foi DESATIVADO."
    else
        echo "   ➡️  Nenhuma alteração feita. O Caps Lock permanece ativado."
    fi
fi
echo ""

echo "🎉 Configuração concluída!"
