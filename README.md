# Fotos dos alunos: envio pelos supervisores e painel por turma

Plataforma web para coletar a foto de cada aluno no padrão exigido pelo
sistema de reconhecimento facial do colégio. Quem envia escolhe o aluno na
lista, tira ou seleciona a foto no celular e o próprio navegador converte a
imagem para JPG, com resolução mínima de 1280 x 720 e tamanho entre 100 KB e
200 KB, antes de enviar. Um fluxo do n8n valida o login, salva o arquivo no
Google Drive (uma pasta por turma) e registra no banco quem enviou e quando.
A coordenação acompanha num painel o percentual de fotos enviadas por turma.
Enquanto o `config.js` estiver com os valores de exemplo, a página roda em
modo demonstração com dados fictícios.

## Como está organizado

- `index.html`: tela de envio. Login por código enviado ao e-mail (Supabase Auth), lista de alunos com busca e filtro por turma, status com ou sem foto, pré-visualização, conversão da imagem e envio ao webhook. Também permite apagar uma foto enviada.
- `dashboard.html`: painel da coordenação com o andamento por turma.
- `config.exemplo.js`: modelo do `config.js` (URL e chave anon do projeto, endereços dos webhooks). As duas telas carregam `config.js` antes do supabase-js.
- `supabase-schema.sql`: tabelas `supervisores`, `alunos` e `fotos`, com RLS (quem está logado só lê; a escrita é feita pelo n8n com a service_role). Inclui três alunos fictícios para teste.
- `criar-numero.sql`: preenche a coluna `numero` usada no nome do arquivo (`Nome_Numero.jpg`); pode ser executado repetidas vezes.
- `n8n-workflow-fotos-v2.json`: fluxo de upload em uso (valida o token, confere o supervisor, cria a pasta da turma no Drive, sobe o arquivo e registra no banco).
- `n8n-workflow-fotos.json`: primeira versão do fluxo de upload (pasta única).
- `n8n-workflow-apagar.json`: apaga a foto de um aluno no Drive e no banco.
- `n8n-workflow-organizar-fotos.json` e `n8n-workflow-renomear-fotos.json`: fluxos manuais que moveram as fotos antigas para as pastas por turma e as renomearam para o padrão atual.
- `N8N-FLUXO.md`: descrição nó a nó do fluxo de upload.
- `REQUISITOS.md`: levantamento de requisitos e decisões do projeto.

A pasta `deploy/` da versão original era uma cópia idêntica de `index.html` e `dashboard.html` e por isso não está aqui: publica-se a raiz.

## Stack

- Front: HTML, CSS e JavaScript puros, sem build; supabase-js por CDN. A conversão da foto é feita no navegador com canvas.
- Banco: PostgreSQL, usando o Supabase como serviço gerenciado (Auth por código OTP, RLS e API REST).
- Automação: n8n (webhooks de upload e exclusão, integração com a API do Google Drive).
- Armazenamento das fotos: Google Drive.
- Hospedagem: estática (os arquivos da raiz).

## Como rodar

1. Crie um projeto no Supabase e rode `supabase-schema.sql` no SQL Editor. Depois, cadastre os supervisores na tabela `supervisores` e os alunos em `alunos`.
2. Rode `criar-numero.sql` para dar um número fixo a cada pessoa (usado no nome do arquivo).
3. Em Authentication, habilite o login por e-mail com código OTP.
4. No n8n, importe `n8n-workflow-fotos-v2.json` e `n8n-workflow-apagar.json`. Em cada um, troque `https://SEU-PROJETO.supabase.co`, `COLE_AQUI_A_CHAVE_ANON`, `COLE_AQUI_A_SERVICE_ROLE_KEY` e `COLE_AQUI_O_ID_DA_PASTA_DO_DRIVE` pelos valores do seu projeto, conecte uma credencial do Google Drive e libere o domínio do site em CORS (Allowed Origins) no nó Webhook.
5. Copie `config.exemplo.js` para `config.js` e preencha a URL e a chave anon do projeto e os endereços dos dois webhooks. O `config.js` fica fora do repositório.
6. Publique `index.html`, `dashboard.html` e `config.js` numa hospedagem estática.

## Dados

Este repositório não contém dados pessoais. As planilhas de alunos e funcionários, o CSV consolidado e os scripts SQL de importação, inclusão e remoção de pessoas ficam fora por LGPD e estão no `.gitignore`.
