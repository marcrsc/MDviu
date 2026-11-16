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
- [Destaque de texto](#destaque-de-texto)
- [Html cru opcional](#html-cru-opcional)
- [Quebras de linha](#quebras-de-linha)
- [Imagens](#imagens)
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
| `lib\script.js` | Logica de renderizacao (markdown-it, links, titulos) |
| `lib\markdown-it.min.js` | Biblioteca de conversao Markdown -> HTML |
| `styles\*.css` | Um arquivo por estilo disponivel na combo "Estilo" |

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
| Voltar | Alt+Backspace | Reabre o arquivo imediatamente anterior, restaurando a posicao de rolagem de onde estava |
| Topo | — | Rola o conteudo de volta pro inicio |
| Atualizar | F5 | Rele o `.md` e o CSS selecionado do disco, sem mexer na rolagem atual |
| Imprimir | Ctrl+P | Abre a impressao nativa do WebView2 (com preview) |
| Salvar PDF | Ctrl+Shift+P | Exporta PDF direto, sem dialogo, ao lado do `.md` |

"Voltar" empilha em `FHistory` (sem limite) toda vez que voce abre outro
arquivo (link ou "Abrir...") — funciona pra cadeia inteira de arquivos
visitados nesta janela, nao so um passo. So esvazia fechando a janela
(processo novo = pilha nova).

**Rolagem**: abrir um arquivo novo (Abrir, link, duplo clique) sempre
comeca do topo. So "Voltar" restaura a posicao de rolagem exata de quando
voce saiu daquele arquivo (guardada em `script.js`, por caminho completo,
enquanto o processo estiver aberto). F5 e troca de estilo/caixa "HTML"
(mesmo arquivo) mantem onde voce esta — mas trocar de estilo muda tamanho
de fonte e espacamento, entao a posicao em pixel de antes nao aponta mais
pro mesmo trecho; em vez de guardar pixel, o `script.js` guarda **qual
bloco** (paragrafo, titulo, tabela etc.) esta encostado no topo da tela e
rola ate esse mesmo bloco depois de re-renderizar — funciona porque o
texto nao muda, so o CSS, entao a ordem dos blocos e sempre identica.

A combo "Estilo" lista os arquivos de `styles\*.css`. A caixa "Nova
janela" controla o comportamento dos links pra outro `.md` (ver proxima
secao) — desmarcada por padrao. A caixa "HTML" libera HTML cru no arquivo
atual (ver [Destaque de texto](#destaque-de-texto) e a nota de seguranca
logo abaixo) — tambem desmarcada por padrao, e volta a desmarcar sozinha
toda vez que um arquivo diferente e aberto (Abrir, link pra outro `.md`,
Voltar).

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

## Destaque de texto

Duas sintaxes marcam texto com fundo colorido (`mark` no CSS, secao 8 de
cada estilo), funcionam juntas inclusive aninhadas em `**negrito**` —
independente da caixa "HTML" (ver [HTML cru opcional](#html-cru-opcional))
estar marcada ou nao:

- `==texto destacado==` — nao existe no `markdown-it` nativo; o
  `script.js` adiciona uma regra inline propria (`mark_delim`) que cria os
  tokens `mark_open`/`mark_close`.
- `<mark>texto destacado</mark>` — tag HTML5 oficial. Uma segunda regra
  (`mark_tag`) reconhece **so** essas duas strings literais e as converte
  nos mesmos tokens, direto, sem depender do `html: true`/`false` geral do
  markdown-it (roda antes da regra nativa de HTML na ordem do parser).

## Html cru opcional

Por padrao o markdown-it roda com `html: false` — qualquer tag solta no
`.md` (`<div>`, `<b>`, `<img>`, `<script>`, etc.) aparece como texto
literal, escapada. A caixa "HTML" na barra liga `html: true` so pro
arquivo atual (`md.set({ html: ... })` em `script.js`, antes de cada
`md.render()`), deixando essas tags passarem cru pro HTML final.

- **Desmarcada por padrao**, e volta a desmarcar sozinha toda vez que um
  arquivo diferente e aberto (Abrir, link pra outro `.md`, Voltar) — nunca
  fica ligada "sem querer" num arquivo que voce nao escolheu abrir com ela
  ligada.
- **Risco real**: com a caixa marcada, um `.md` que executa `<script>` roda
  esse JS dentro do WebView2 do MDviu. Só marque em arquivo que voce
  escreveu ou confia — e a mesma logica de "pergunta antes de confiar" vale
  pra qualquer `.md` recebido de terceiro.

## Quebras de linha

Dois comportamentos fora do padrao CommonMark, pensados pra quem escreve
quebrando linha com frequencia (uma frase por linha, paragrafos separados
por varias linhas em branco):

- **Quebra de linha simples dentro de um paragrafo** (uma linha logo
  abaixo da outra, sem linha em branco entre elas) vira `<br>` — opcao
  `breaks: true` do markdown-it (`script.js`). Por padrao do Markdown isso
  seria ignorado, juntando tudo num paragrafo so que quebra pela largura da
  janela.
- **Varias linhas em branco seguidas** empilham espaco: cada linha em
  branco **alem da primeira** vira um paragrafo vazio forcado (um `&nbsp;`
  invisivel, pra nao depender da caixa "HTML"). Por padrao do Markdown,
  1 linha em branco ou 10 dao exatamente o mesmo resultado — aqui,
  cada uma a mais soma espaco visivel. Implementado em
  `expandBlankLines()` (`script.js`), que preserva o conteudo de blocos de
  codigo (` ``` `/`~~~`) sem mexer — linha em branco la dentro continua
  sendo so conteudo literal do codigo.

## Imagens

- **Caminho absoluto** (`http://`, `https://`): carrega normal, direto da
  internet, sem nenhum tratamento especial.
- **Caminho relativo** (`![alt](foo.jpg)`, mesma pasta ou subpasta do
  `.md`, inclusive com `../`): o WebView2 nao tem "pasta atual" de disco
  pra resolver isso sozinho (a pagina e injetada via `NavigateToString`,
  nao carregada de um `file://` real). Por isso, antes de mandar o texto
  pro JS, o Delphi (`InlineLocalImages`/`ImageToDataUri` em `uMain.pas`) le
  a imagem do disco e substitui o caminho por um `data:` URI em base64,
  embutido direto no HTML — funciona sem rede, sem CORS, sem limite de
  pasta. So reconhece `.jpg`/`.jpeg`/`.png`/`.gif`/`.svg`/`.webp`/`.bmp`;
  arquivo nao encontrado ou extensao desconhecida deixa o caminho original
  (a imagem so nao aparece).
- **Tag `<img>` crua** (com a caixa "HTML" marcada, ver
  [Html cru opcional](#html-cru-opcional)): o embutir em base64 so olha
  sintaxe Markdown (`![alt](caminho)`), nao mexe em HTML cru — um
  `<img src="relativo.jpg">` cru so carrega se o caminho for absoluto
  (`http://`/`https://`).

## Estilos css editaveis

Cada arquivo em `styles\` vira uma opcao na combo "Estilo" (nome do
arquivo sem a extensao e sem o sufixo `_DEF`, se tiver — e so estetico, o
arquivo no disco continua com o sufixo). O arquivo cujo nome **de disco**
contem o sufixo `_DEF` (ex.: `Claro_DEF.css`) e o selecionado por padrao
ao abrir — pra trocar o default, renomeie o sufixo pra outro arquivo.

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
5. **Imagem com caminho relativo nao carregava** — primeira tentativa foi
   mapear a pasta do `.md` como host virtual do WebView2
   (`SetVirtualHostNameToFolderMapping`), mas a pagina criada via
   `NavigateToString` tem uma origem opaca que bloqueia os pedidos pro host
   mapeado (falha sempre, `fetch` retorna "Failed to fetch"). Abandonado em
   favor do `data:` URI em base64 (ver [Imagens](#imagens)). De quebra: o
   hostname de teste usava sufixo `.local`, que o Windows tenta resolver via
   mDNS antes do WebView2 interceptar — evitar esse sufixo em qualquer
   tentativa futura parecida, usar `.example` (reservado p/ documentacao).
6. **Base64 quebrando a sintaxe do markdown-it** — `TNetEncoding.Base64`
   quebra linha a cada 76 caracteres por padrao (estilo MIME); uma quebra de
   linha dentro do destino de uma imagem/link invalida a sintaxe do
   CommonMark, entao a imagem aparecia como texto literal em vez de
   renderizar. Corrigido com `TBase64Encoding.Create(0)` (0 = sem quebra).
7. **Rolagem "vazava" entre arquivos** — como a pagina do WebView2 nunca
   recarrega de verdade (so reinjeta o conteudo via `innerHTML`), a posicao
   de rolagem do arquivo anterior ficava e o arquivo novo abria no meio do
   nada. Corrigido guardando a rolagem por arquivo (`scrollPositions` em
   `script.js`) e so restaurando no "Voltar" — arquivo novo sempre comeca
   do topo.
8. **Rolagem "perdia o lugar" ao trocar de estilo** — trocar pro estilo
   Compacto (fontes/espacamento menores) deixava a posicao em pixel
   apontando pra outro trecho do texto. Corrigido ancorando num bloco
   (`captureScrollAnchor`/`restoreScrollAnchor` em `script.js`) em vez de
   pixel — acha o paragrafo/titulo/etc. encostado no topo antes de trocar
   e rola ate ele de novo depois.
9. **Ancora de rolagem pegava o bloco errado** — a primeira versao do item 8
   chamava `captureScrollAnchor` de dentro de `renderMD`, mas o Delphi
   executa `setStyle(cssNovo)` **antes** de `renderMD` — ou seja, a captura
   media o conteudo ainda ANTIGO ja com o CSS NOVO aplicado (tudo encolhido
   de repente), achando um bloco bem mais abaixo do real (chegava a "pular"
   pro fim do arquivo). Corrigido com `prepareScrollAnchor()`, chamado pelo
   Delphi **antes** de `setStyle`, pra capturar com o CSS ainda antigo.

## Como compilar

Target **Win64** (`dcc64`, nao `dcc32` — a `WebView2Loader.dll` bundlada e
x64). Arquivos que tem que acompanhar o `MDviu.exe` apos compilar: ver
[Arquivos que acompanham o exe](#arquivos-que-acompanham-o-exe).
