# AGENTS

Guia curto pra quem (ou qual IA) continuar o projeto MDviu.

## Indice

- [Regras zero](#regras-zero)
- [Contexto do projeto](#contexto-do-projeto)
- [Onde esta cada coisa](#onde-esta-cada-coisa)
- [Antes de commitar ou dar push](#antes-de-commitar-ou-dar-push)

## Regras zero

- **Pergunta nao e comando.** "Tem como...?", "faz sentido...?" pede resposta,
  nao codigo. So implementar apos confirmacao explicita.
- **Nunca commitar ou dar push sem pedido explicito do usuario**, mesmo que
  uma vez anterior ja tenha sido autorizado — autorizacao nao se generaliza.
- **Testar rodando o app de verdade antes de dizer que terminou** — compilar
  limpo nao e garantia de que funciona (o bug da `WebView2Loader.dll`
  faltando compilou limpo e so quebrou ao abrir o programa).
- **Arquivos `.md` de documentacao** (specs, README, este arquivo) levam
  indice logo apos o titulo e secoes (`##` em diante) sem acento nem
  pontuacao — so letras minusculas/maiusculas, digitos e espaco, pra ancora
  ficar igual em qualquer visualizador.

## Contexto do projeto

MDviu e um visualizador de Markdown com CSS externo customizavel. Dois apps:

- [MDviu_Delphi/MDviu.md](MDviu_Delphi/MDviu.md) — o app de verdade (Delphi + WebView2).
- [MDviu_HTML/MDviu_HTML.md](MDviu_HTML/MDviu_HTML.md) — protótipo HTML/CSS/JS, so pra desenhar CSS.

Leia o `.md` de detalhes de cada um antes de mexer nele — tem a arquitetura,
limitacoes conhecidas e bugs ja corrigidos (nao redescobrir os mesmos).

## Onde esta cada coisa

| Coisa | Onde |
|---|---|
| Codigo do app Delphi | `MDviu_Delphi/uMain.pas`, `MDviu_Delphi/MDviu.dpr` |
| CSS editaveis (combo "Estilo") | `MDviu_Delphi/web/styles/*.css` |
| Logica JS (markdown-it, links, titulos) | `MDviu_Delphi/web/script.js` |
| Dependencias que tem que ir junto do `.exe` | `WebView2Loader.dll`, `OnyxBlue.vsf`, `mdviu.ico`, pasta `web/` |
| Protótipo HTML | `MDviu_HTML/` |
| Arquivos `teste*.md`, `pagina_*.md`, `subpasta/` | So material de teste manual — nao sao parte do produto |

## Antes de commitar ou dar push

- Repositorio privado, conta GitHub `marcrsc`.
- Compilar em **64 bits** (`dcc64`) — ver [MDviu_Delphi/MDviu.md](MDviu_Delphi/MDviu.md#como-compilar).
- `.gitignore` ja cobre artefatos de build (`*.exe`, `*.dcu`, etc.) — nunca
  versionar o `.exe` compilado nem o log de debug.
- Mensagens de commit e PRs levam a atribuicao combinada com o usuario (ver
  instrucoes do ambiente de cada sessao).
