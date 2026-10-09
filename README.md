# intactoz. — Underground (recriação independente)

Recriação da homepage, catálogo, login e dashboard a partir de HTMLs e capturas fornecidos no chat. **Não é o site oficial**, e nenhuma compra ou pagamento é processado por esta aplicação. Botões de compra abrem URLs na loja original.

## Abra agora, sem custos

Pode abrir `index.html` diretamente em um navegador moderno, mas para garantir que módulos JavaScript carreguem corretamente, execute em terminal na pasta do projeto:

```bash
python -m http.server 8080
```

Acesse `http://localhost:8080`. No modo local você pode filtrar o catálogo, abrir produtos e testar o painel `/adm` (via navegação de hash `#/adm`) sem conta. As alterações persistem no navegador com `localStorage` — **não são compartilhadas, não são protegidas e não constituem um banco de dados**. Não use esse painel de demonstração em produção.

## Para ativar contas reais e painel protegido

1. Crie **um projeto Supabase novo e dedicado ao Intactoz**. Não use bancos de outros sites.
2. No SQL Editor do projeto, execute `supabase/schema.sql`. A rotina cria as tabelas, os controles de acesso (RLS), o bucket de imagens e 4 produtos de exemplo.
3. Em **Project Settings → API**, copie a `Project URL` e a **anon/publishable key** para `config.js`. **Nunca coloque `service_role` ou chave secreta no frontend.**
4. Em **Authentication → URL Configuration**, configure a URL real em Site URL e inclua a URL do site em Redirect URLs (incluindo a navegação para `#/conta` quando necessário). Configure o serviço SMTP no Supabase se for necessário entregar e-mails de confirmação com volume confiável.
5. Crie a conta de administrador pela página `#/conta` e confirme o e-mail. No painel Supabase → Authentication → Users, copie o UUID da conta e execute uma única instrução SQL autenticada no editor administrativo:

```sql
insert into public.intactoz_admin_users(user_id)
values ('COLE-AQUI-O-UUID-DO-ADMINISTRADOR');
```

6. Atualize `#/adm` após entrar na conta. O painel usa permissões reais verificadas pelo servidor. Visitantes comuns só podem ler o catálogo; não podem editar produtos, fotos ou liberar acesso para si mesmos.
7. Imagens de produtos importadas do site anterior podem estar inacessíveis (HTTP 401): substitua-as pelo upload de imagens **com autorização de uso** no painel.

## Hospedagem

Projeto estático, sem necessidade de build. Publique a pasta no GitHub Pages, Vercel ou outro serviço estático; `index.html` é a entrada, e URLs internas são hashes para dispensar configuração de rewrites. Para colocar em produção com Supabase, configure antes `config.js` e o SQL.

## Recursos

- Homepage responsiva seguindo os prints, com fotografias P&B → cores no hover.
- Filtros por categoria e coleção; detalhes e galeria dos produtos; links para compra externa.
- Área `#/conta`: cadastro, login, logout e redefinição de senha por e-mail quando conectada ao Supabase.
- Painel `#/adm`: criação, edição e exclusão de produtos, categorias e coleções; fotos JPG/PNG/WebP; ordenação básica (capa); pesquisa; controle de acesso com RLS.
- Modo de demonstração local, com catálogo editável salvo no próprio navegador.

## Observações

As fotos da collab Intactoz × KACE são creditadas no artigo original: https://www.kacewear.com.br/blogs/conteudo/sidoka-e-intactoz-x-kace-collab-envelope-traz-novas-roupas-e-acessorios. Confirme direitos de uso antes de publicar uma versão comercial. A foto do login veio da imagem enviada no chat e foi recortada para encaixar no mesmo retângulo do original.

Os preços e links inicialmente são do HTML fornecido, **não demonstram estoque nem preços em tempo real**. Confirme disponibilidade no site original.

## Animações de interface (inspiradas no MotionSites)

A versão animada utiliza `motion.css` e `motion.js`, sem bibliotecas extras:
- Entrada suave dos títulos, seções, editoriais e cards com IntersectionObserver.
- Parallax discreto na fotografia principal e barra fina de progresso de rolagem.
- Faixa editorial contínua (marquee) que pausa ao passar o cursor.
- Hover que revela as cores originais das imagens, com zoom suave nas fotos dos produtos.
- Respeita `prefers-reduced-motion` e não depende de animações para carregar conteúdo.

As animações são uma implementação original inspirada nos princípios do MotionSites, não uma cópia de seus templates ou efeitos pagos.

## Correção de carregamento da homepage

Os scripts `config.js`, `motion.js` e `app.js` agora usam `defer` e JavaScript clássico, permitindo abrir `index.html` diretamente pelo explorador de arquivos (`file://`). Para testar integrações externas, prefira GitHub Pages ou um servidor local. Configure as chaves públicas no objeto `window.INTACTOZ_CONFIG` do arquivo `config.js`.

## Backend conectado — Intactoz (2026-10)

- URL pública: https://intactoz-underground.vercel.app/
- Supabase compartilhado com **Arceuz**, com tabelas isoladas por prefixo `intactoz_`: `intactoz_products`, `intactoz_categories`, `intactoz_collections`, `intactoz_members`, `intactoz_admin_users`.
- As políticas de segurança RLS permitem consultas públicas do catálogo e restringem modificações a administradores autorizados por `public.is_intactoz_admin()`.
- As imagens enviadas pelo painel ficam no bucket `intactoz-products`.
- **Não execute `supabase/schema.sql` sobre o banco compartilhado do Arceuz**: ele foi elaborado inicialmente para uma instalação exclusiva. A configuração compartilhada já foi aplicada por migrações no Supabase.
- O projeto compartilha o serviço de autenticação da instância Supabase, mas utiliza dados de perfil e permissão Intactoz separados. Nunca publique chaves `service_role`.
- Para conceder acesso administrativo, escolha um usuário que já tenha cadastro confirmado e atribua a autorização pelo backend, após verificar a identidade do titular. **Nunca habilite autorização admin por campos editáveis pelo usuário.**
- Para confirmar cadastro e recuperar senha, autorize `https://intactoz-underground.vercel.app/**` em Authentication > URL Configuration > Redirect URLs no painel Supabase (sem remover as URLs existentes do Arceuz).
