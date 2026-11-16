# MDviu (Delphi)

App Windows nativo que visualiza Markdown com CSS externo customizavel,
construido em Delphi (RAD Studio 37.0) usando `TEdgeBrowser` (WebView2).

## Indice

- [Visao geral](#visao-geral)
- [Requisitos](#requisitos)
- [Arquivos que acompanham o exe](#arquivos-que-acompanham-o-exe)
- [Arquitetura](#arquitetura)
- [Barra de ferramentas e atalhos](#barra-de-ferramentas-e-atalhos)
- [Como funcionam os links](#como-funcionam-os-links)
- [Estilos css editaveis](#estilos-css-editaveis)
- [Limitacoes conhecidas](#limitacoes-conhecidas)
- [Bugs importantes ja corrigidos](#bugs-importantes-ja-corrigidos)
- [Como compilar](#como-compilar)

## Visao geral

Abre com duplo clique (apos associar a extensao `.md` nas propriedades do
Windows) ou pelo botao "Abrir...". Le o `.md` e o CSS selecionado direto do
disco a cada carga e a cada F5 — nao ha cache, nao ha passo de build.

## Requisitos

- Windows com o **WebView2 Runtime** instalado (vem por padrao no Windows 11;
  se faltar, o Windows oferece a instalacao automaticamente).
- Nada mais — o app e standalone, nao precisa do Delphi instalado na maquina
  que so vai *rodar* ele.

## Arquivos que acompanham o exe

Todos estes arquivos moram ao lado de `MDviu.exe` e sao obrigatorios:

| Arquivo | Para que serve |
|---|---|
| `WebView2Loader.dll` | Loader do WebView2 — sem ele o app nao abre (ver [Bugs importantes ja corrigidos](#bugs-importantes-ja-corrigidos)) |
| `OnyxBlue.vsf` | Estilo visual VCL (tema azul escuro da interface) |
| `mdviu.ico` | Icone do programa |
| `web\script.js` | Logica de renderizacao (markdown-it, links, titulos) |
| `web\lib\markdown-it.min.js` | Biblioteca de conversao Markdown -> HTML |
| `web\styles\*.css` | Um arquivo por estilo disponivel na combo "Estilo" |

## Arquitetura

`uMain.pas` monta toda a interface em codigo (o `.dfm` so tem o `TForm` vazio,
sem componentes — evita risco de um `.dfm` mal formado).

Fluxo de carregamento:

1. `FormCreate` cria a barra de ferramentas, o `TEdgeBrowser` e chama
   `CreateWebView`.
2. `OnCreateWebViewCompleted` dispara `BuildShellAndNavigate`: monta uma
   pagina HTML (com o `markdown-it.min.js` e o `script.js` embutidos
   inline) e chama `NavigateToString` — so acontece uma vez, por processo.
3. `OnNavigationCompleted` dispara `RenderCurrentFile`: le o `.md` e o CSS
   selecionado do disco e manda os dois pro JS via `ExecuteScript`,
   chamando `setStyle(css)` e `renderMD(texto, nomeArquivo)`.
4. F5 (Atualizar) so repete o passo 3 — nao recarrega a pagina, so
   reinjeta o conteudo atualizado.

## Barra de ferramentas e atalhos

| Botao | Atalho | Acao |
|---|---|---|
| Abrir... | Ctrl+O | Abre outro `.md` (dialogo nativo do Windows) |
| Voltar | Alt+Backspace | Reabre o arquivo imediatamente anterior |
| Topo | — | Rola o conteudo de volta pro inicio |
| Atualizar | F5 | Rele o `.md` e o CSS selecionado do disco |
| Imprimir | Ctrl+P | Abre a impressao nativa do WebView2 (com preview) |
| Salvar PDF | Ctrl+Shift+P | Exporta PDF direto, sem dialogo, ao lado do `.md` |

A combo "Estilo" lista os arquivos de `web\styles\*.css`. A caixa "Nova
janela" controla o comportamento dos links pra outro `.md` (ver proxima
secao) — desmarcada por padrao.

## Como funcionam os links

- **Ancora na mesma pagina** (`[texto](#secao)`): cada titulo (h1-h6) ganha
  um `id` automatico (slug do proprio texto), entao o navegador rola
  sozinho ate o lugar certo — nenhum codigo Delphi envolvido.
- **Link para outro `.md` local** (caminho relativo, com ou sem `/` ou
  `..\`): o `script.js` intercepta o clique e avisa o Delphi via
  `window.chrome.webview.postMessage`. O Delphi resolve o caminho relativo
  a pasta do arquivo atual e abre — na mesma janela (empilhando o arquivo
  atual pro botao "Voltar") ou numa janela nova do MDviu, conforme a caixa
  "Nova janela".
- **Link externo** (`http://`, `https://`, `mailto:`): sempre abre no
  navegador padrao do Windows (`ShellExecute`), nunca dentro do MDviu — o
  WebView2 sinaliza isso via `NewWindowRequested`, que o Delphi sempre
  intercepta e redireciona pro navegador do sistema.

## Estilos css editaveis

Cada arquivo em `web\styles\` vira uma opcao na combo "Estilo" (nome do
arquivo sem a extensao). O arquivo cujo nome contem o sufixo `_DEF` (ex.:
`Claro_DEF.css`) e o selecionado por padrao ao abrir — pra trocar o
default, renomeie o sufixo pra outro arquivo.

Estilos ja incluidos:

- `Claro_DEF.css` — claro, espacoso, prioriza legibilidade
- `Escuro.css` — mesmo espacamento do Claro, cores invertidas pra fundo escuro
- `Compacto.css` — claro, fontes e espacamentos menores

Cada CSS e organizado em secoes numeradas comentadas (base, titulos,
paragrafos, links, imagens, tabelas, codigo, destaques, regua horizontal) —
editar, salvar e apertar F5 no MDviu mostra o resultado na hora.

## Limitacoes conhecidas

- **Arrastar um arquivo pra janela nao funciona** (desativado de proposito):
  o navegador nao entrega o caminho real do arquivo arrastado pro Delphi,
  entao o F5 depois nao conseguiria relê-lo do disco. Use duplo clique ou
  o botao "Abrir...".
- **Destaque de texto** (`==texto==` ou `<mark>texto</mark>`) ainda nao
  renderiza colorido: `markdown-it` nao tem suporte nativo a `==texto==`
  (precisa de um plugin pequeno) e o app desativa HTML cru por seguranca
  (`html: false`). Facil de ligar quando for pedido.
- Exportar PDF so tem os dois caminhos ja prontos (dialogo Ctrl+P e
  automatico Ctrl+Shift+P) — sem conversao em lote ainda.

## Bugs importantes ja corrigidos

Histórico util pra nao redescobrir os mesmos problemas:

1. **WebView2 nao iniciava** (`E_FAIL` / `0x80004005`) — faltava o
   `WebView2Loader.dll` ao lado do `.exe` (e´ carregado dinamicamente via
   `LoadLibrary`, nao vem embutido no Delphi). Corrigido bundlando uma
   copia assinada pela Microsoft e compilando o app em **64 bits**
   (`dcc64`) pra bater com a arquitetura dessa DLL.
2. **Smart App Control do Windows bloqueou o executavel** — um `.exe` novo,
   recompilado varias vezes, sem assinatura, do lado de uma DLL assinada
   pela Microsoft, parece uma tecnica de "DLL side-loading". O usuario
   liberou manualmente; um certificado de assinatura de codigo resolveria
   em definitivo se o app continuar sendo desenvolvido/distribuido.
3. **Link com barra invertida falhava** (`..\arquivo.md`) — o
   `markdown-it` codifica `\` como `%5C` na URL do link. Corrigido
   decodificando a URL (`TNetEncoding.URL.Decode`) antes de resolver o
   caminho.
4. **Espaco grande demais acima do primeiro titulo** — a margem de cima do
   `h1` somava com o padding do `body` (margem nao colapsa com padding).
   Corrigido com `#content > *:first-child { margin-top: 0; }` em cada CSS.

## Como compilar

Target **Win64** (`dcc64`, nao `dcc32` — a `WebView2Loader.dll` bundlada e
x64). Arquivos que tem que acompanhar o `MDviu.exe` apos compilar: ver
[Arquivos que acompanham o exe](#arquivos-que-acompanham-o-exe).
