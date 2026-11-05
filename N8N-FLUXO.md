# Fluxo do n8n: recebimento e arquivamento das fotos

> Este documento descreve o fluxo original (`n8n-workflow-fotos.json`, pasta única e nome `{matricula}-{nome}.jpg`). A versão em uso é `n8n-workflow-fotos-v2.json`, que cria uma subpasta por turma no Drive e nomeia o arquivo como `Nome_Numero.jpg` (o número vem de `criar-numero.sql`). A lógica de validação do token e de registro no banco é a mesma.

Endpoint: `https://COLE_AQUI_O_ENDERECO_DO_N8N/webhook/fotos/googlefotos`

O front (index.html) envia um `POST multipart/form-data` com:

| Campo | Conteúdo |
|---|---|
| `foto` | arquivo JPG já no padrão (100–200 KB, ≥1280×720) |
| `aluno_id` | ID do aluno no Supabase |
| `matricula` | matrícula do aluno |
| `nome` | nome do aluno |
| `turma` | turma do aluno |
| header `Authorization` | `Bearer <token JWT do Supabase Auth>` |

## Nós do workflow (na ordem)

### 1. Webhook
- **Método:** POST · **Path:** `fotos/googlefotos`
- **Respond:** "Using 'Respond to Webhook' node"
- **Options → Allowed Origins (CORS):** o domínio do Cloudflare Pages (ex.: `https://fotos.exemplo.edu.br` ou `https://<projeto>.pages.dev`). Sem isso o navegador bloqueia a chamada (preflight OPTIONS).
- **Options → Binary Property:** o arquivo chega como binário `foto`.

### 2. HTTP Request — validar o token do supervisor
Valida o JWT sem precisar de criptografia no n8n: pergunta ao próprio Supabase quem é o dono do token.
- **GET** `https://<PROJETO>.supabase.co/auth/v1/user`
- Headers:
  - `apikey`: anon key do Supabase
  - `Authorization`: `{{ $json.headers.authorization }}` (repassa o Bearer recebido)
- **On Error:** continuar (para cair no ramo de erro) ou usar um IF depois.
- Resposta 200 → token válido; o corpo traz `email` do supervisor.
- Resposta 401 → seguir para o nó **Respond to Webhook (erro)** com status **401** e corpo `{"ok": false, "erro": "não autorizado"}`.

### 3. (Opcional, recomendado) Supabase — conferir supervisor ativo
- **Get rows** em `supervisores` com filtro `email = {{ $json.email }}` e `ativo = true`.
- Vazio → responder 403.

### 4. Google Drive — Upload File
- **Credencial:** conta Google institucional (ideal: Shared Drive, não conta pessoal).
- **Binary Property:** `foto`
- **File Name:** `{{ $('Webhook').item.json.body.matricula }}-{{ $('Webhook').item.json.body.nome }}.jpg`
- **Parent Folder:** pasta `Fotos Alunos 2026/<turma>` — para criar a subpasta da turma automaticamente, adicionar antes um nó "Google Drive → Search folder / Create folder" (ou apontar tudo para uma pasta única no começo).
- Saída traz `id` e `webViewLink` do arquivo.

### 5. Supabase — Insert em `fotos`
- `aluno_id`: `{{ $('Webhook').item.json.body.aluno_id }}`
- `drive_file_id`: `{{ $json.id }}`
- `drive_url`: `{{ $json.webViewLink }}`
- `enviado_por`: id do supervisor (do passo 3)
- `enviado_em`: `{{ $now }}`
- Credencial Supabase com **service role key** (a escrita em `fotos` é bloqueada por RLS para o front).

### 6. Respond to Webhook
- Status **200**, corpo `{"ok": true}` — é isso que o front espera para marcar "foto salva".

## Atenções

- **Nunca deixar o webhook sem o passo 2.** A URL é pública; sem a validação, qualquer pessoa na internet consegue despejar arquivos no Drive da escola.
- **Teste do webhook em modo de edição:** no n8n, o botão "Listen for test event" usa a URL `webhook-test/...`; a URL de produção (`webhook/...`) só responde com o workflow **ativado**.
- O nome do path é `googlefotos`, mas o destino é o **Google Drive** (Google Fotos não tem API de upload aberta para esse uso) — só um cuidado para não confundir a equipe.
- Tamanho máximo de payload do n8n (padrão 16 MB) está folgado: as fotos chegam com ≤200 KB.
