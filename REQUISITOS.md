# Levantamento de Requisitos — Plataforma de Fotos dos Alunos

**Data:** 08/09/2026
**Status:** rascunho para validação
**Solicitante:** Coordenação Pedagógica (coordenacao@exemplo.edu.br)

---

## 1. Visão geral

Plataforma web para que **supervisores do colégio** enviem a foto de cada aluno. O supervisor entra com o e-mail institucional, vê a lista de alunos (vinda do banco de dados), seleciona um aluno e envia a foto. A foto é armazenada no **Google Drive** e os metadados (quem enviou, quando, link do arquivo) ficam registrados no **Supabase**.

## 2. Stack definida

| Camada | Tecnologia | Papel |
|---|---|---|
| Front-end | HTML/CSS/JS estático no **Cloudflare Pages** | Interface do supervisor |
| Banco de dados | **Supabase** (PostgreSQL) | Alunos, supervisores, registro das fotos |
| Autenticação | **Supabase Auth** | Verificação do supervisor por e-mail |
| Integração | **n8n** (webhook) | Recebe a foto, envia ao Drive, grava o registro no Supabase |
| Armazenamento | **Google Drive** | Arquivo final da foto |

## 3. Atores

- **Supervisor** — envia fotos dos alunos das suas turmas.
- **Administrador** (coordenação) — cadastra supervisores e alunos, acompanha o andamento.
- **n8n (sistema)** — executa o fluxo de upload em segundo plano.

## 4. Requisitos funcionais

| ID | Requisito | Prioridade |
|---|---|---|
| RF01 | Login do supervisor por e-mail institucional via Supabase Auth (link mágico ou código OTP enviado ao e-mail — sem senha) | Alta |
| RF02 | Apenas e-mails previamente cadastrados na tabela de supervisores (ou do domínio autorizado, ex.: `@exemplo.edu.br`) conseguem acessar | Alta |
| RF03 | Listar alunos a partir do Supabase, com busca por nome e filtro por turma/série | Alta |
| RF04 | Indicar visualmente quais alunos já têm foto enviada e quais estão pendentes | Alta |
| RF05 | Selecionar um aluno e enviar uma foto (com pré-visualização antes de confirmar) | Alta |
| RF06 | Converter automaticamente a foto para o **padrão do reconhecimento facial**: JPG/JPEG, resolução mínima 1280×720 px, arquivo final entre **100 KB e 200 KB** (maiores são rejeitados pelo sistema). Fotos com resolução original abaixo do mínimo são recusadas com aviso | Alta |
| RF07 | Foto enviada ao n8n, que salva no Google Drive em pasta organizada (sugestão: `/Fotos Alunos {ano}/{turma}/`) com nome padronizado (sugestão: `{matricula}-{nome}.jpg`) | Alta |
| RF08 | n8n grava no Supabase o registro: aluno, link/ID do arquivo no Drive, supervisor, data/hora | Alta |
| RF09 | Permitir substituir a foto de um aluno (nova versão sobrescreve ou arquiva a anterior — decidir) | Média |
| RF10 | Feedback claro ao supervisor: "enviando…", "foto salva", ou erro com orientação | Alta |
| RF11 | Painel simples de acompanhamento para a coordenação (% de fotos enviadas por turma) | Baixa (fase 2) |

## 5. Requisitos não funcionais

- **LGPD** — fotos de alunos são dados pessoais de menores. A pasta do Drive não pode ser pública ("qualquer pessoa com o link"); acesso restrito às contas da escola. Registrar quem enviou cada foto (trilha de auditoria, já coberta pelo RF08).
- **Segurança do webhook** — o endpoint do n8n é exposto na internet; deve validar o token JWT do Supabase Auth (ou ao menos um header secreto) antes de aceitar upload. Sem isso, qualquer pessoa poderia enviar arquivos.
- **RLS no Supabase** — Row Level Security nas tabelas: supervisor autenticado só lê; escrita de fotos só pelo n8n (service role).
- **Mobile-first** — supervisores provavelmente vão tirar a foto pelo celular; a página deve funcionar bem no navegador do celular (`<input type="file" accept="image/*" capture>`).
- **Padrão do reconhecimento facial** — as fotos alimentam o sistema de reconhecimento facial do colégio, que exige JPG/JPEG, mínimo 1280×720 px e arquivo entre 100 e 200 KB. A conversão é feita no navegador antes do envio (redimensiona e ajusta a qualidade JPEG até cair na faixa), então qualquer celular serve como origem — inclusive iPhone, cujo HEIC é convertido para JPG no processo.

## 6. Fluxo principal

1. Supervisor acessa o site (Cloudflare Pages) e informa o e-mail.
2. Supabase Auth envia link/código; supervisor confirma e recebe a sessão.
3. Front consulta o Supabase e mostra a lista de alunos (com status com/sem foto).
4. Supervisor seleciona o aluno, escolhe/tira a foto, confere a pré-visualização e confirma.
5. Front comprime a imagem e envia (foto + ID do aluno + token) ao webhook do n8n.
6. n8n valida o token → sobe o arquivo no Google Drive → grava o registro na tabela `fotos` do Supabase → responde OK.
7. Front atualiza a lista: aluno passa a "foto enviada".

## 7. Modelo de dados (proposta)

```
supervisores: id, nome, email (único), ativo, criado_em
alunos:       id, matricula, nome, turma, serie, ativo
fotos:        id, aluno_id (FK), drive_file_id, drive_url,
              enviado_por (FK supervisores), enviado_em, substituida (bool)
```

Um aluno pode ter várias linhas em `fotos` (histórico); a vigente é a mais recente não substituída — ou, se preferirem simplicidade, uma foto por aluno com sobrescrita.

## 8. Pontos em aberto (para decidir com a equipe)

1. **Origem dos dados de alunos** — já existem em algum sistema/planilha? Como serão importados para o Supabase e com que frequência são atualizados?
2. **Escopo do supervisor** — cada supervisor vê todos os alunos ou só as turmas dele?
3. **Substituição de foto** — permitida livremente, ou trava depois de enviada (só coordenação libera)?
4. **Conta do Google Drive** — Drive de qual conta? Recomendado: Shared Drive institucional com credencial de service account no n8n (não a conta pessoal de alguém).
5. **Domínio de e-mail** — todos os supervisores usam `@exemplo.edu.br`? Se sim, dá para restringir por domínio além da lista.
6. **Padrão de nome do arquivo e das pastas** no Drive (proposta no RF07).
7. **Prazo/campanha** — há uma janela de coleta (ex.: início do ano letivo)? Isso define se o painel de acompanhamento (RF11) entra já na fase 1.
8. **n8n** — já existe instância no ar (cloud ou self-hosted)? Onde?

## 9. Fases sugeridas

- **Fase 1 (MVP):** login por e-mail, lista de alunos, upload → Drive via n8n, registro no Supabase, status com/sem foto.
- **Fase 2:** painel da coordenação, regras de substituição, filtros por turma do supervisor.

## 10. Riscos

- Webhook do n8n sem validação = porta aberta para upload malicioso (mitigar com JWT/segredo).
- Quota da API do Google Drive em picos de envio (mitigar: fila/retentativa no n8n).
- Fotos muito pesadas de celular estourando limites (mitigar: compressão no navegador).
- Link do Drive público por engano = vazamento de dados de menores (mitigar: revisão de permissões da pasta, nunca "qualquer pessoa com o link").
