# 02 · Backup e restauração

## Estratégia

A regra que segui (e que aprendi a respeitar da forma difícil, ver [incidente 3](05-incidentes.md)) é a **3-2-1**:

- **3** cópias dos dados
- em **2** tipos de suporte diferentes
- **1** delas fora do local

| Cópia | Suporte | Local |
|---|---|---|
| 1 | Pendrive | Local |
| 2 | HDD externo | Local |
| 3 | Google Drive (conta separada) | Nuvem (fora do local) |

## O que foi salvo

- Pasta de backup principal + pastas do perfil do usuário (Documentos, Imagens, Área de Trabalho, Downloads…)
- **Total: 11.769 arquivos / 12,5 GB**

## Manifesto SHA-256: a prova de que nada se perdeu

Copiar arquivos não basta. É preciso **provar** que a cópia é idêntica ao original. Para isso, o script [`backup-verify.ps1`](../scripts/windows/backup-verify.ps1) gera um **manifesto** em CSV com o caminho relativo, o tamanho e o hash SHA-256 de cada arquivo:

```powershell
.\backup-verify.ps1 -Origem "D:\Backup" -Manifesto "D:\manifesto.csv"
```

```csv
"Caminho","Tamanho","SHA256"
"Documentos/exemplo.pdf","48213","9F86D081884C7D659A2FEAE0C55AD015A3BF4F1B2B0B822CD15D6C15B0F00A08"
```

Se um único bit de um arquivo mudar, o hash muda completamente. Isso permite detectar corrupção, cópias incompletas ou arquivos esquecidos.

## Restauração

1. **Download a partir do Google Drive com `rclone`**, porque o download pelo navegador falhava com pastas grandes ([incidente 5](05-incidentes.md)).
   A conta foi conectada com o escopo **`drive.readonly`**, de **privilégio mínimo**: o rclone consegue ler, mas nunca apagar ou alterar nada na nuvem.

   ```bash
   rclone config            # remote "gdrive", scope = drive.readonly
   rclone copy gdrive:Backup ~/restauro --progress --transfers 4
   ```

2. **Conferência contra o manifesto** com [`verificar-manifesto.py`](../scripts/linux/verificar-manifesto.py):

   ```bash
   python3 verificar-manifesto.py manifesto.csv ~/restauro
   ```

   Resultado da pasta de backup principal: **11.759 arquivos idênticos**, nenhum faltando e nenhum diferente.

3. Os arquivos foram colocados em `Documentos → "Arquivos do Windows"`, em um local óbvio para o usuário.

## Snapshots do sistema (depois da instalação)

O **Timeshift** (modo RSYNC) protege o *sistema*, não os arquivos pessoais:

- 2 snapshots diários + 2 semanais
- `/home` **excluída**, porque os dados pessoais têm backup próprio e assim os snapshots ocupam menos espaço

Backup (dados) e snapshot (sistema) são coisas diferentes, e um não substitui o outro.
