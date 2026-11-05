/* Copie este arquivo para config.js e preencha. O config.js real está
   no .gitignore e não vai para o repositório.

   A chave anon é pública por desenho: as tabelas têm RLS e quem escreve
   é só o n8n, com a service_role (que nunca entra aqui). */
window.CONFIG_PROJETO = {
  SUPABASE_URL:      'https://SEU-PROJETO.supabase.co',
  SUPABASE_ANON_KEY: 'SUA_CHAVE_ANON',

  // Webhooks do n8n (fluxos n8n-workflow-fotos-v2.json e n8n-workflow-apagar.json)
  N8N_WEBHOOK_URL:   'https://COLE_AQUI_O_ENDERECO_DO_N8N/webhook/fotos/googlefotos',
  N8N_DELETE_URL:    'https://COLE_AQUI_O_ENDERECO_DO_N8N/webhook/fotos/apagar'
};
