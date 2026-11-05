-- Coluna "numero" — número fixo de cada pessoa para o nome do arquivo (Nome_Numero.jpg)
-- Alunos e terceiros: numero = matrícula/CPF. Funcionários (matrícula = e-mail): sequência 1, 2, 3…
-- Colar no Supabase SQL Editor e Run. Pode rodar quantas vezes quiser (só preenche quem está sem número).

alter table public.alunos add column if not exists numero text;

-- 1) Quem tem matrícula numérica usa a própria matrícula
update public.alunos
set numero = matricula
where numero is null and matricula ~ '^[0-9]+$';

-- 2) Quem não tem número (e-mail) recebe a sequência, continuando do maior já usado
with prox as (
  select coalesce(max(numero::bigint), 0) as m
  from public.alunos
  where numero ~ '^[0-9]+$' and length(numero) <= 6
),
seq as (
  select id, row_number() over (order by nome) + (select m from prox) as n
  from public.alunos
  where numero is null
)
update public.alunos a
set numero = seq.n::text
from seq
where a.id = seq.id;

-- Conferência: ninguém pode ficar sem número
select count(*) as sem_numero from public.alunos where numero is null;

-- Lista dos funcionários com o número que receberam
select numero, nome, matricula from public.alunos
where matricula !~ '^[0-9]+$'
order by numero::bigint;

-- IMPORTANTE: sempre que cadastrar gente nova, rode este MESMO arquivo de novo —
-- ele dá matrícula como número pra quem tem, e o próximo número da fila pra quem não tem.
