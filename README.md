# Script de Atualização Completa do Ubuntu

Este script Bash automatiza o processo de atualização completa de um sistema Ubuntu, incluindo atualizações de pacotes APT, Snap e Flatpak, além de realizar limpezas para otimizar o sistema. Ele fornece feedback visual com cores no terminal, registra todas as operações em um arquivo de log e exibe um resumo das métricas de atualização ao final.

## Funcionalidades

*   **Atualização Abrangente:** Atualiza pacotes APT (incluindo `update`, `upgrade`, `dist-upgrade`), Snap e Flatpak.
*   **Verificações Iniciais:**
    *   Verifica a conexão com a internet antes de iniciar as atualizações.
    *   Verifica se há espaço em disco suficiente para evitar falhas durante a atualização.
    *   Verifica se `flatpak` e `snap` estão instalados e prossegue com as atualizações apenas se estiverem presentes.
*   **Tratamento de Erros e Retentativas:** Implementa um sistema de retentativas para comandos que podem falhar temporariamente devido a problemas de rede ou servidores ocupados.
*   **Timeout para Comandos:** Define um timeout para cada etapa para evitar que o script fique travado indefinidamente.
*   **Registro Detalhado (Logging):** Registra todas as ações, sucessos, erros e avisos em um arquivo de log (`~/.system-update.log`) para auditoria e diagnóstico.
*   **Métricas de Atualização:** Coleta e exibe métricas como tempo total de atualização, quantidade de dados baixados, espaço em disco liberado e número de erros encontrados.
*   **Feedback Visual Colorido:** Utiliza cores no terminal para destacar status, sucessos, erros, avisos e informações importantes, tornando a execução do script mais informativa e agradável visualmente.
*   **Limpeza do Sistema:** Realiza limpeza de pacotes desnecessários (`apt autoremove`) e cache de pacotes (`apt clean`) para liberar espaço em disco após a atualização.
*   **Verificação de Reinicialização Necessária:** Detecta se uma reinicialização do sistema é necessária após as atualizações e avisa o usuário.
*   **Segurança:** Usa `sudo` apenas quando necessário para operações administrativas.

## Pré-requisitos

*   Sistema operacional Ubuntu (ou derivado).
*   Conexão com a internet.
*   Acesso `sudo` para executar comandos administrativos.
*   Opcional: `flatpak` e `snap` instalados para atualização desses pacotes.

## Como Usar

1.  **Baixe o script:**
    Você pode baixar o script diretamente do GitHub ou usar `wget` ou `curl`:

    ```bash
    wget https://raw.githubusercontent.com/<seu-usuario>/<seu-repositorio>/main/seu-script-de-atualizacao.sh -O atualizar-ubuntu.sh
    # ou
    curl -o atualizar-ubuntu.sh https://raw.githubusercontent.com/<seu-usuario>/<seu-repositorio>/main/seu-script-de-atualizacao.sh
    ```
    Substitua `<seu-usuario>` e `<seu-repositorio>` pelo seu nome de usuário e nome do repositório no GitHub, e `seu-script-de-atualizacao.sh` pelo nome do arquivo do seu script.

2.  **Torne o script executável:**
    ```bash
    chmod +x atualizar-ubuntu.sh
    ```

3.  **Execute o script:**
    ```bash
    ./atualizar-ubuntu.sh
    ```

    Você precisará inserir sua senha de `sudo` quando solicitado.

## Logs

Todas as operações do script são registradas no arquivo `~/.system-update.log`. Este arquivo contém informações detalhadas sobre cada etapa da atualização, incluindo horários, status, sucessos, erros e avisos. Em caso de problemas, consulte este log para obter mais detalhes.

## Considerações Importantes

*   **Conexão com a Internet:** Uma conexão de internet estável é essencial para o script funcionar corretamente. O script verifica a conectividade antes de iniciar, mas certifique-se de que sua conexão seja confiável durante todo o processo de atualização.
*   **Espaço em Disco:** Certifique-se de ter espaço em disco suficiente antes de executar o script, especialmente na partição raiz (`/`). O script verifica se há pelo menos 1GB de espaço livre, mas mais espaço pode ser necessário dependendo do tamanho das atualizações.
*   **Tempo de Execução:** O tempo de execução do script pode variar dependendo da velocidade da sua internet, da quantidade de atualizações disponíveis e do desempenho do seu sistema. Seja paciente e não interrompa o script durante a execução, a menos que seja absolutamente necessário.
*   **Pacotes Retidos (Held):** O script avisa sobre pacotes retidos durante a atualização do APT. Pacotes retidos podem indicar problemas de dependência ou configurações específicas que impedem a atualização automática. Investigue pacotes retidos manualmente se o script avisar sobre eles.
*   **Reinicialização:** Se o script indicar que uma reinicialização é necessária, é altamente recomendável reiniciar o sistema para aplicar completamente todas as atualizações, especialmente as do kernel ou bibliotecas importantes.

## Customização

*   **Arquivo de Log:** O arquivo de log é salvo por padrão em `~/.system-update.log`. Você pode modificar a variável `UPDATE_LOG` no script para alterar o local do arquivo de log, se desejar.
*   **Retentativas e Timeout:** As variáveis `MAX_RETRIES` e `RETRY_DELAY` dentro da função `try_step` podem ser ajustadas para modificar o comportamento de retentativas do script. O `timeout` de 300 segundos (5 minutos) para cada comando também pode ser alterado na função `try_step`.

## Segurança

O script executa comandos administrativos usando `sudo`. Revise o código do script para garantir que você entende todas as operações que ele realiza antes de executá-lo em seu sistema. O script foi projetado para automatizar tarefas de atualização padrão do Ubuntu e não deve realizar ações destrutivas, mas é sempre uma boa prática revisar scripts de terceiros antes de executá-los com privilégios administrativos.

---

Este script foi criado para facilitar a manutenção de sistemas Ubuntu atualizados. Use-o por sua conta e risco. Sinta-se à vontade para contribuir com melhorias ou correções através de Pull Requests!
