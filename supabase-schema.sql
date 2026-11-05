-- =====================================================================
-- Plataforma de Fotos dos Alunos — schema inicial
-- Colar no Supabase: SQL Editor → New query → Run
-- =====================================================================

create table if not exists public.supervisores (
  id         bigint generated always as identity primary key,
  nome       text not null,
  email      text not null unique,
  ativo      boolean not null default true,
  criado_em  timestamptz not null default now()
);

create table if not exists public.alunos (
  id         bigint generated always as identity primary key,
  matricula  text not null unique,
  nome       text not null,
  turma      text not null,
  serie      text not null,
  ativo      boolean not null default true,
  criado_em  timestamptz not null default now()
);

create table if not exists public.fotos (
  id             bigint generated always as identity primary key,
  aluno_id       bigint not null references public.alunos (id),
  drive_file_id  text not null,
  drive_url      text,
  enviado_por    bigint references public.supervisores (id),
  enviado_em     timestamptz not null default now(),
  substituida    boolean not null default false
);

create index if not exists fotos_aluno_idx on public.fotos (aluno_id);

-- =====================================================================
-- RLS: supervisor logado só LÊ; quem escreve é o n8n (service role,
-- que ignora RLS). Ninguém sem login lê nada.
-- =====================================================================

alter table public.supervisores enable row level security;
alter table public.alunos       enable row level security;
alter table public.fotos        enable row level security;

-- Supervisor autenticado enxerga apenas o próprio cadastro
-- (o front usa isso para conferir se o e-mail está ativo).
create policy "supervisor le o proprio cadastro"
  on public.supervisores for select
  to authenticated
  using (email = (auth.jwt() ->> 'email'));

-- Qualquer supervisor autenticado lê a lista de alunos.
create policy "supervisores leem alunos"
  on public.alunos for select
  to authenticated
  using (true);

-- Qualquer supervisor autenticado lê os registros de fotos
-- (necessário para o status "foto enviada" / "pendente").
create policy "supervisores leem fotos"
  on public.fotos for select
  to authenticated
  using (true);

-- Sem policies de insert/update/delete: escrita só pelo n8n (service role).

-- =====================================================================
-- Dados de exemplo para testar (apagar depois, ou trocar pelos reais)
-- =====================================================================

insert into public.supervisores (nome, email) values
  ('Coordenação Pedagógica', 'coordenacao@exemplo.edu.br')
on conflict (email) do nothing;

insert into public.alunos (matricula, nome, turma, serie) values
  ('2026001', 'Ana Beatriz Souza',    '1A', '1º ano'),
  ('2026002', 'Bruno Carvalho Lima',  '1A', '1º ano'),
  ('2026003', 'Clara Mendes Rocha',   '1B', '1º ano')
on conflict (matricula) do nothing;
