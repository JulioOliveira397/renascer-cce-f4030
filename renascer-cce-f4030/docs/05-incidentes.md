# 05 · Incidentes

Documentar o que deu errado vale tanto como documentar o que correu bem. Cada incidente segue o formato **O que aconteceu → Causa → Correção → Lição**, o mesmo raciocínio de um *post-mortem* profissional.

---

## 1 · Script PowerShell fechava sem mostrar erro

- **O que aconteceu:** o script de backup abria e fechava a janela instantaneamente, sem mensagem.
- **Causa:** uso de `$lista.Item` como se fosse uma propriedade. Em PowerShell, `.Item` é um **indexador** (`$lista[0]`). O erro acontecia, mas a janela fechava antes de eu ler.
- **Correção:** acrescentei `trap` para capturar exceções, `Start-Transcript` para gravar um log e uma pausa no fim.
- **Lição:** um script sem log é uma caixa preta. **Primeiro a observabilidade, depois a depuração.**

## 2 · Backup apontou para o destino errado

- **O que aconteceu:** com vários discos conectados, o script escolheu um destino que não era o pretendido.
- **Causa:** a seleção do destino era ambígua (letra de unidade, sem confirmação).
- **Correção:** o script passou a mostrar uma tabela **"Cabe?"** com o espaço livre de cada disco comparado ao tamanho do backup e a pedir confirmação explícita.
- **Lição:** em operações com dados, **mostre antes de agir** e peça confirmação.

## 3 · Instalação antes da 2ª cópia

- **O que aconteceu:** instalei o Linux Mint (formatando o disco) **antes** de terminar a segunda cópia planejada do backup.
- **Causa:** pressa; confiei em uma única cópia verificada.
- **Impacto:** nenhum, porque a cópia existente estava íntegra. Mas, durante esse período, havia **um único ponto de falha**.
- **Lição:** **regra 3-2-1** antes de qualquer operação destrutiva. Sem exceções.

## 4 · `rsync` com variável vazia → `rsync /` em loop (o mais grave)

- **O que aconteceu:** um comando do tipo `rsync -a "$B"/ destino/` rodou com `B` **vazio**. `"$B"/` virou `/`, e o rsync começou a copiar **o sistema inteiro**, incluindo o próprio destino, em loop. Chegou a **84 GB** e o disco ficou a **100%**.
- **Causa:** nenhuma validação da variável antes de um comando com efeito em massa.
- **Correção:** parei o processo, apaguei a cópia descontrolada e passei a validar as entradas:

  ```bash
  set -euo pipefail
  : "${B:?Variável B vazia — abortando}"
  [ -d "$B" ] || { echo "Origem $B não existe"; exit 1; }
  rsync -a --dry-run "$B"/ destino/   # ensaio primeiro
  ```
- **Lição:** **valide sempre as entradas** e use `--dry-run` antes de comandos destrutivos ou em massa. Esse é o mesmo tipo de falha que, em produção, derruba servidores.

## 5 · Download de pasta grande pelo Drive web

- **O que aconteceu:** o download da pasta de backup pelo navegador falhava ou gerava ZIPs partidos.
- **Causa:** limites da interface web para pastas grandes.
- **Correção:** **rclone** com escopo `drive.readonly` (privilégio mínimo).
- **Lição:** para dados em volume, use ferramentas de linha de comando feitas para isso, e dê a elas só a permissão necessária.

## 6 · `authorized_keys` vazio com "OK" falso

- **O que aconteceu:** rodei um comando de **PowerShell no `cmd`**. A sintaxe foi interpretada de outra forma, o `authorized_keys` ficou **vazio** e o terminal ainda assim mostrou uma mensagem de sucesso.
- **Causa:** shell errada; confiei na mensagem em vez de no resultado.
- **Correção:** copiei de novo a chave na shell correta e **conferi o conteúdo** do arquivo (`cat ~/.ssh/authorized_keys`) e o login.
- **Lição:** **verifique o resultado, não a mensagem.** "OK" não é prova.

## 7 · `apt` à espera do lock do `dpkg`

- **O que aconteceu:** `sudo apt install` ficou parado com *"Waiting for cache lock: Could not get lock /var/lib/dpkg/lock-frontend"*.
- **Causa:** as **atualizações automáticas** (que eu mesmo ativei) estavam rodando em segundo plano.
- **Correção:** esperei terminar. **Nunca** apagar os arquivos de lock à mão.
- **Lição:** o lock existe para proteger a base de dados de pacotes. Apagar o lock com um update a meio pode **corromper o sistema**. Antes de forçar, entenda o que o bloqueio está protegendo.
