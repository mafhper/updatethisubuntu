# update-ubuntu
Minhas preferências de atualizações no Ubuntu.

---
# Script de Atualização Completa do Sistema

Este repositório contém um script de atualização completo para sistemas Ubuntu, projetado para automatizar diversas tarefas de manutenção, tais como:

- Atualização da lista de pacotes e upgrades do sistema
- Realização de dist-upgrade
- Atualização de aplicativos instalados via Flatpak (se disponível)
- Limpeza de pacotes não utilizados e cache do APT
- Exibição de métricas e estatísticas da atualização (tempo total, dados baixados, espaço liberado)
- Mensagens coloridas para facilitar a visualização e identificação do status das operações

## Recursos do Script

- **Cores e Mensagens:**  
  O script utiliza cores para diferenciar os tipos de mensagens:
  - **Azul:** Status e informações gerais
  - **Verde:** Mensagens de sucesso
  - **Vermelho:** Mensagens de erro
  - **Amarelo:** Avisos
  - **Ciano e Magenta:** Outras informações e métricas

- **Medição de Métricas:**  
  São calculados os dados baixados (através da verificação do tamanho do cache APT e do repositório Flatpak) e o espaço liberado após a limpeza.

- **Tolerância a Falhas:**  
  O script utiliza uma função `try_step` que permite múltiplas tentativas para cada etapa, caso ocorra alguma falha durante a execução de comandos.

- **Compatibilidade com Flatpak:**  
  Antes de tentar atualizar aplicativos via Flatpak, o script verifica se o Flatpak está instalado e exibe uma mensagem de aviso caso não esteja.

## Pré-requisitos

- Sistema operacional: Ubuntu (ou distribuições baseadas em Ubuntu)
- Permissões de `sudo` para a execução dos comandos de atualização e limpeza
- (Opcional) Flatpak instalado, caso você utilize aplicativos via Flatpak

## Instalação e Execução

### 1. Criação do Script

O script pode ser criado manualmente ou por meio de um arquivo de configuração do **cloud-init** (como demonstrado no arquivo YAML de instalação automatizada). Para criar o script manualmente:

```bash
sudo nano /usr/local/bin/update_script.sh
```

Cole o conteúdo do script de atualização (conforme disponibilizado no arquivo YAML ou em outro local) e salve o arquivo.

### 2. Tornar o Script Executável

Após criar o script, torne-o executável:

```bash
sudo chmod +x /usr/local/bin/update_script.sh
```

### 3. Execução do Script

Para executar o script manualmente, utilize o seguinte comando:

```bash
sudo /usr/local/bin/update_script.sh
```

O script irá executar as seguintes etapas:

- Atualizar a lista de pacotes
- Recarregar os serviços do systemd
- Realizar upgrade e dist-upgrade dos pacotes instalados
- Atualizar aplicativos via Flatpak (se aplicável)
- Realizar a limpeza de pacotes e cache do APT
- Exibir métricas e estatísticas da atualização
- Informar se o sistema requer reinicialização
