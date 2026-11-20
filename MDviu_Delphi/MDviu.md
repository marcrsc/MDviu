# MDviu (Delphi)

App Windows nativo que visualiza Markdown com CSS externo customizavel,
construido em Delphi (RAD Studio 37.0) usando `TEdgeBrowser` (WebView2).

## Indice

- [Visao geral](#visao-geral)
- [Requisitos](#requisitos)
- [Arquivos que acompanham o exe](#arquivos-que-acompanham-o-exe)
- [Bibliotecas de terceiros](#bibliotecas-de-terceiros)
- [Arquitetura](#arquitetura)
- [Barra de ferramentas e atalhos](#barra-de-ferramentas-e-atalhos)
- [Como funcionam os links](#como-funcionam-os-links)
- [Destaque de texto](#destaque-de-texto)
- [Html cru opcional](#html-cru-opcional)
- [Quebras de linha](#quebras-de-linha)
- [Imagens](#imagens)
- [Destaque de sintaxe em blocos de codigo](#destaque-de-sintaxe-em-blocos-de-codigo)
- [Abrir codigo fonte direto](#abrir-codigo-fonte-direto)
- [Copiar bloco de codigo](#copiar-bloco-de-codigo)
- [Estilos css editaveis](#estilos-css-editaveis)
- [Limitacoes conhecidas](#limitacoes-conhecidas)
- [Bugs importantes ja corrigidos](#bugs-importantes-ja-corrigidos)
- [Como compilar](#como-compilar)

## Visao geral

Abre com duplo clique (apos associar a extensao `.md` nas propriedades do
Windows), pelo botao "Abrir..." ou arrastando o arquivo pra janela (ver
[Barra de ferramentas e atalhos](#barra-de-ferramentas-e-atalhos)). Le o `.md` e o CSS selecionado direto do
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
| `lib\script.js` | Logica de renderizacao (markdown-it, links, titulos) |
| `lib\markdown-it.min.js` | Biblioteca de conversao Markdown -> HTML |
| `lib\highlight.min.js` | Destaque de sintaxe em bloco de codigo (ver [Destaque de sintaxe em blocos de codigo](#destaque-de-sintaxe-em-blocos-de-codigo)) |
| `lib\highlight-light.min.css` / `lib\highlight-dark.min.css` | Tema de cor do highlight.js, claro e escuro — NAO aparecem na combo "Estilo" por estarem em `lib\`, nao em `styles\` |
| `styles\*.css` | Um arquivo por estilo disponivel na combo "Estilo" |

Icone e estilo visual VCL (Onyx Blue) vem **dentro do `MDviu.exe`**, nao sao
arquivo solto — ver [Arquitetura](#arquitetura).

## Bibliotecas de terceiros

Todas rodam 100% client-side dentro do WebView2 (sem rede em tempo de uso) —
embutidas inline no HTML por `BuildShellAndNavigate` em `uMain.pas`, igual
descrito em [Arquitetura](#arquitetura).

| Biblioteca | Versao | Site / onde baixar | Licenca |
|---|---|---|---|
| markdown-it | 14.1.0 | <https://github.com/markdown-it/markdown-it> — build minificado via jsDelivr/unpkg: `https://cdn.jsdelivr.net/npm/markdown-it@14.1.0/dist/markdown-it.min.js` | MIT |
| highlight.js | 11.12.0 | <https://highlightjs.org/download> — build customizado com "Select all languages" (repositorio: <https://github.com/highlightjs/highlight.js>) | BSD-3-Clause |
| Temas highlight.js ("Default" / "GitHub Dark") | 11.12.0 | Incluidos no mesmo build de `highlight.js` acima, pasta `styles/` do zip | BSD-3-Clause |

## Arquitetura

Projeto Delphi VCL padrao, como feito pela IDE:

- **Interface no Form Designer** (`uMain.dfm`): painel, label "Estilo",
  combo, os 6 `TSpeedButton`, os 2 checkboxes, `TEdgeBrowser`,
  `TOpenDialog` e `TActionList` (com os atalhos de teclado) sao todos
  componentes de tempo de projeto, com os eventos ligados no proprio
  `.dfm`. Nada visual e criado em codigo — da pra abrir e editar a tela
  normalmente na IDE.
  - Cada checkbox ("Janela", "HTML", "Quebra") e so a caixinha (`TCheckBox` sem
    texto) + um `TLabel` ao lado com o texto: com fonte menor que a dos
    botoes, o texto do proprio `TCheckBox` desalinhava da caixa. Clicar no
    texto marca/desmarca a caixa (`LblCheckClick`).
  - `ActiveControl = EdgeBrowser1` no form: o foco ja comeca na area do
    documento (senao a combo "Estilo", primeira na ordem de Tab, aparecia
    selecionada em azul ate o documento renderizar).
- **Icone e estilo VCL configurados no projeto** (`MDviu.dproj`):
  `Icon_MainIcon` = `mdviu.ico` (Project Options > Application > Icon) e
  `Custom_Styles` = Onyx Blue (Project Options > Application > Appearance,
  arquivo vindo da instalacao do RAD Studio, `$(BDSCOMMONDIR)\Styles`).
  Ao compilar, o MSBuild gera o `MDviu.res` com icone, estilo, manifesto
  (temas + DPI-aware `PerMonitorV2`) e versao, linkado pelo `{$R *.res}`
  do `MDviu.dpr`, que aplica o estilo com `TStyleManager.TrySetStyle`
  antes de criar o form. Pra testar outro estilo: marcar na Appearance e
  trocar o nome no `.dpr` — sem mexer no resto do codigo.
- `MDviu.res` e artefato (gerado a cada compilacao a partir do `.dproj`,
  fica no `.gitignore`); o `.dproj` e quem guarda essas configuracoes e e
  versionado.

Fluxo de carregamento:

1. O `.dfm` cria a tela; `FormCreate` le os parametros, preenche a combo de
   estilos CSS (`PopulateStyles`), pinta o fundo da janela com a cor do
   estilo e define `WEBVIEW2_DEFAULT_BACKGROUND_COLOR` (abertura sem
   "piscada", ver bug 13 em [Bugs importantes ja corrigidos](#bugs-importantes-ja-corrigidos))
   e chama `CreateWebView`.
2. `OnCreateWebViewCompleted` chama `ApplyPageColors` (cor de fundo e
   esquema claro/escuro do WebView2) e `BuildShellAndNavigate`: monta uma
   pagina HTML (com o `markdown-it.min.js`, o `script.js` e o CSS do estilo
   atual embutidos inline) e chama `NavigateToString` — so acontece uma
   vez, por processo.
3. `OnNavigationCompleted` dispara `RenderCurrentFile`: le o `.md` e o CSS
   selecionado do disco e manda os dois pro JS via `ExecuteScript`,
   chamando `setStyle(css)` e `renderMD(texto, nomeArquivo)`.
4. F5 (Atualizar) so repete o passo 3 — nao recarrega a pagina, so
   reinjeta o conteudo atualizado.

## Barra de ferramentas e atalhos

| Botao | Atalho | Acao |
|---|---|---|
| Abrir... | Ctrl+O | Abre outro `.md` (ou arquivo de codigo-fonte, dialogo nativo do Windows — ver [Abrir codigo fonte direto](#abrir-codigo-fonte-direto)) |
| Voltar | Alt+Backspace | Reabre o arquivo imediatamente anterior, restaurando a posicao de rolagem de onde estava |
| Topo | — | Rola o conteudo de volta pro inicio |
| Atualizar | F5 | Rele o `.md` e o CSS selecionado do disco, sem mexer na rolagem atual |
| Imprimir | Ctrl+P | Abre a impressao nativa do WebView2 (com preview) |
| Salvar PDF | Ctrl+Shift+P | Exporta PDF direto, sem dialogo, ao lado do `.md` (mesmo nome, `.pdf`). Se o PDF ja existe, pergunta "Substituir?" (Sim substitui; Nao, o padrao, cancela sem gerar nada) |

**Arrastar arquivo** pra janela abre igual ao "Abrir..." (so o primeiro, se
vierem varios). O JS nao ve o caminho real do arquivo solto; `script.js`
manda o `File` por `postMessageWithAdditionalObjects` e o Delphi le o
caminho do `ICoreWebView2File` (`DroppedFilePath` em `uMain.pas`) — por
isso F5 e "Voltar" funcionam normalmente depois. Exige WebView2 Runtime
recente; em runtime antigo, soltar o arquivo nao faz nada.

"Voltar" empilha em `FHistory` (sem limite) toda vez que voce abre outro
arquivo (link, "Abrir..." ou arrastar) — funciona pra cadeia inteira de arquivos
visitados nesta janela, nao so um passo. So esvazia fechando a janela
(processo novo = pilha nova).

**Rolagem**: abrir um arquivo novo (Abrir, link, duplo clique, arrastar) sempre
comeca do topo. So "Voltar" restaura a posicao de rolagem exata de quando
voce saiu daquele arquivo (guardada em `script.js`, por caminho completo,
enquanto o processo estiver aberto). F5 e troca de estilo/caixa "HTML"
(mesmo arquivo) mantem onde voce esta — mas trocar de estilo muda tamanho
de fonte e espacamento, entao a posicao em pixel de antes nao aponta mais
pro mesmo trecho; em vez de guardar pixel, o `script.js` guarda **qual
bloco** (paragrafo, titulo, tabela etc.) esta encostado no topo da tela e
rola ate esse mesmo bloco depois de re-renderizar — funciona porque o
texto nao muda, so o CSS, entao a ordem dos blocos e sempre identica.

A combo "Estilo" lista os arquivos de `styles\*.css`. A caixa "Janela"
controla o comportamento dos links pra outro `.md` (ver proxima
secao) — desmarcada por padrao. A caixa "HTML" libera HTML cru no arquivo
atual (ver [Destaque de texto](#destaque-de-texto) e a nota de seguranca
logo abaixo) — tambem desmarcada por padrao, e volta a desmarcar sozinha
toda vez que um arquivo diferente e aberto (Abrir, arrastar, link pra
outro `.md`, Voltar). A caixa "Quebra" (ver
[Destaque de sintaxe em blocos de codigo](#destaque-de-sintaxe-em-blocos-de-codigo))
quebra as linhas longas dentro dos blocos de codigo em vez de rolar pro
lado — tambem desmarcada por padrao, mas nao reseta ao trocar de arquivo
(so e aparencia, nao tem nada de seguranca envolvido). Nas tres caixas,
clicar no texto ao lado tambem marca/desmarca.

Todo botao e caixa da barra tem dica (`Hint`/`ShowHint` no `.dfm`) — passe
o mouse por cima pra ver uma frase do que ele faz.

O titulo da janela mostra `MDviu - <caminho completo do arquivo>`
(definido em `RenderCurrentFile`); o mesmo texto aparece na dica da barra
de tarefas do Windows.

## Como funcionam os links

- **Ancora na mesma pagina** (`[texto](#secao)`): cada titulo (h1-h6) ganha
  um `id` automatico (slug do proprio texto), entao o navegador rola
  sozinho ate o lugar certo — nenhum codigo Delphi envolvido.
- **Link para outro `.md` local** (caminho relativo, com ou sem `/` ou
  `..\`): o `script.js` intercepta o clique e avisa o Delphi via
  `window.chrome.webview.postMessage`. O Delphi resolve o caminho relativo
  a pasta do arquivo atual e abre — na mesma janela (empilhando o arquivo
  atual pro botao "Voltar") ou numa janela nova do MDviu, conforme a caixa
  "Janela". Nao faz distincao de extensao: um link pra um arquivo de
  codigo-fonte (`.pas`, `.py` etc.) abre com highlight em vez de Markdown —
  ver [Abrir codigo fonte direto](#abrir-codigo-fonte-direto).
- **Link combinando arquivo + ancora** (`[texto](outro.md#secao)`): o
  Delphi separa a ancora do caminho ANTES de resolver/abrir o arquivo
  (`ExtractAnchor` em `uMain.pas`) — sem isso, tentaria abrir um arquivo
  chamado literalmente `outro.md#secao` e falhar com "arquivo nao
  encontrado". Depois de abrir `outro.md`, rola ate o titulo com aquele id
  (`FPendingAnchor`, usado tanto ao trocar de arquivo na mesma janela quanto
  ao abrir pela linha de comando/"Janela").
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
  sendo so conteudo literal do codigo. Antes de contar, CRLF vira LF
  (arquivos salvos no Windows) e linha so com espacos/tabs conta como em
  branco — sem isso a regra nao funcionava em arquivo CRLF (bug corrigido;
  os arquivos de `testes/` sao LF e nao mostravam o problema).

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

## Destaque de sintaxe em blocos de codigo

Bloco de codigo com linguagem (` ```pascal `, ` ```python `, etc.) ganha cor
via highlight.js (ver [Bibliotecas de terceiros](#bibliotecas-de-terceiros)),
build completo — todas as linguagens da lib, inclusive `delphi`/`pascal` e
`vbscript-html` (alias `asp`).

- **Liga/desliga**: constante `ENABLE_SYNTAX_HIGHLIGHT` no topo do
  `lib\script.js` — sem interface pra isso, so trocar o valor e recompilar.
  Desligado (ou linguagem nao reconhecida pela lib), o bloco volta a aparecer
  sem cor, como antes dessa funcionalidade existir.
- **Tema claro/escuro**: cada CSS em `styles\` declara, perto do topo, uma
  variavel `--mdviu-theme: light;` ou `--mdviu-theme: dark;` dentro de um
  `:root { }`. A funcao `setStyle()` do `script.js` le essa variavel a cada
  troca de estilo e liga o `<style>` de highlight correspondente
  (`lib\highlight-light.min.css` ou `lib\highlight-dark.min.css`, embutidos
  no Shell desde o inicio, so um dos dois fica ativo por vez) — os 3 CSS do
  projeto continuam do jeito que estavam, so essa variavel a mais.
- **Cor de cada "token"**: base nos dois temas padrao da propria lib
  ("Default" claro, "GitHub Dark" escuro — `lib\highlight-light.min.css` /
  `lib\highlight-dark.min.css`), com ajustes manuais feitos depois (ver
  backup do original em `lib\highlight-light_orig.css` /
  `lib\highlight-dark_orig.css`):
  - Palavra reservada (`.hljs-keyword` — `var`, `begin`, `if`, `procedure`
    etc.): branco no tema escuro (era vermelho claro); tema claro
    inalterado.
  - Nome de classe/funcao (`.hljs-title`): azul forte nos dois temas (era
    vermelho escuro no claro, roxo claro no escuro).
  - Comentario (`.hljs-comment`): vermelho puro em negrito nos dois temas
    (era cinza).
  - Numero e string (`.hljs-number`, `.hljs-string`): roxo nos dois temas.
  - Resto dos tokens (operador, atributo, tipo, etc.) continua como veio da
    lib.
- **Quebra de linha longa**: por padrao o bloco de codigo rola pro lado
  (`overflow-x`) em vez de quebrar, pra nao desalinhar indentacao/colunas.
  A caixa "Quebra" na barra (desmarcada por padrao) troca pra `white-space:
  pre-wrap` + `overflow-wrap: anywhere` (regra `body.wrap-code pre` em cada
  CSS de `styles\`) — so acrescenta uma classe no `<body>` via JS
  (`setCodeWrap()` em `script.js`), sem re-renderizar nada; por isso
  sobrevive a troca de estilo e a abertura de outro arquivo na mesma
  janela (só fecha a janela zera, igual os outros dois checkboxes).

## Abrir codigo fonte direto

Arquivo com extensao reconhecida (tabela abaixo) abre direto como bloco de
codigo com highlight (`renderSource` em `script.js`), SEM passar pelo
markdown-it — nao interpreta `==`, `_`, tabela etc. dentro do arquivo, mostra
o conteudo inteiro como esta no disco. `LanguageForExtension` (`uMain.pas`)
decide isso pela extensao do arquivo, nao importa como foi aberto:

- **Botao "Abrir..."**: o dialogo tem 3 opcoes em "Tipo" — "Arquivos
  Markdown" (`*.md`, **default**), "Codigo-fonte e texto" (filtra so as
  extensoes da tabela abaixo) e "Todos os arquivos" (`*.*`). Os nomes nao
  mostram as extensoes, so filtram. O filtro fica no `OpenDialog1.Filter`
  (`uMain.dfm`) e tem que bater com `LanguageForExtension`.
- **Arrastar o arquivo pra janela**: mesmo caminho do "Abrir...".
- **Link dentro de um `.md`** (ex.: `[veja](exemplo.pas)`): `OpenRelatedMdFile`
  nao faz distincao de extensao — qualquer link local cai no mesmo
  `RenderCurrentFile` que decide o highlight, entao um link pra `.pas` ja
  abre com highlight sem precisar de nada a mais.
- **Linha de comando** (duplo clique, "Janela"): mesma coisa, `FormCreate`
  nao faz distincao, qualquer extensao reconhecida funciona.

| Extensao | Linguagem (highlight.js) |
|---|---|
| `.pas`, `.dpr`, `.dfm`, `.dpk`, `.inc` | Delphi/Pascal (`delphi`) |
| `.html`, `.htm` | HTML |
| `.js` | JavaScript |
| `.ts` | TypeScript |
| `.css` | CSS |
| `.php` | PHP |
| `.asp` | ASP classico (`vbscript-html`) |
| `.json` | JSON |
| `.xml`, `.dproj`, `.groupproj`, `.config`, `.manifest`, `.svg`, `.xsd`, `.xsl` | XML (`xml`) |
| `.yml`, `.yaml` | YAML |
| `.ini`, `.toml` | INI/TOML (`ini`) |
| `.sql` | SQL |
| `.bat`, `.cmd` | Batch do Windows (`dos`) |
| `.ps1` | PowerShell |
| `.sh` | Bash |
| `.py` | Python |
| `.pyw` | Python |
| `.vbs` | VBScript |
| `.vb` | VB.NET |
| `.cs` | C# |
| `.java` | Java |
| `.cpp`, `.h` | C++ (`cpp`) |
| `.diff`, `.patch` | Diff |
| `.txt`, `.log`, `.csv` | Sem cor (`plaintext`) — abre como texto puro com "Copiar", em vez de virar Markdown |

`.svg` aberto direto mostra o codigo XML; dentro de um `.md`
(`![](figura.svg)`) continua aparecendo como imagem. Arquivo muito grande
(ex.: `.log` de dezenas de MB) deixa a abertura lenta: o texto inteiro vai
pro WebView2 e o highlight colore tudo de uma vez.

Extensao fora dessa lista (inclusive `.md`) continua sendo tratada como
Markdown, igual sempre foi.

## Copiar bloco de codigo

Todo `<pre>` (bloco de codigo com ou sem highlight — fenced do markdown-it
ou arquivo de codigo-fonte aberto direto, ver secao anterior) ganha um
botao "Copiar" no canto superior direito, visivel so no hover do bloco
(`addCopyButtons()`/`injectCopyButtonStyle()` em `lib\script.js` — estilo
proprio, nao depende dos CSS do projeto). Posicao: dentro da caixa do
codigo, afastado da moldura (o `padding` do `pre` de cada CSS) por metade da
espessura dela, em cima e na direita — `addCopyButtons()` le o `padding` do
`pre` em tempo de execucao e poe o botao a 1,5x dele (+2px em cima, ajuste
visual), entao acompanha cada estilo. A largura e fixada pela do texto
"Copiado!" (medida ao criar o botao), pra borda esquerda nao pular no
clique. Copia o texto puro (sem as tags de cor do highlight).

Dois jeitos de copiar, o segundo so entra se o primeiro falhar:

1. `navigator.clipboard.writeText` (API padrao do navegador).
2. Se isso falhar — pagina carregada via `NavigateToString` tem origem
   "opaca", que pode restringir a Clipboard API (mesmo motivo do `fetch()`
   falhar pra imagem via host virtual, ver [Imagens](#imagens)) — cai pra
   `window.chrome.webview.postMessage({copyText: texto})`, que o Delphi
   recebe em `EdgeBrowser1WebMessageReceived` e escreve direto na area de
   transferencia do Windows (`Clipboard.AsText`, unit `Vcl.Clipbrd`).

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
- `Largo.css` — igual ao Claro, sem largura maxima (texto ocupa a janela toda)

A largura maxima do texto e o `max-width` do `body` de cada CSS (860px no
Claro, Escuro e Compacto); a coluna fica centralizada (`margin: 0 auto`).
Nao vem do Markdown nem do markdown-it.

Cada CSS e organizado em secoes numeradas comentadas (base, titulos,
paragrafos, links, imagens, tabelas, codigo, destaques, regua horizontal) —
editar, salvar e apertar F5 no MDviu mostra o resultado na hora.

## Limitacoes conhecidas

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
10. **Link "arquivo.md#secao" nao abria** — a ancora ficava grudada no
    caminho na hora de resolver/checar o arquivo, entao tentava abrir um
    arquivo chamado literalmente "arquivo.md#secao" e dava "arquivo nao
    encontrado". Corrigido separando a ancora do caminho antes de tudo
    (`ExtractAnchor`), guardando-a (`FPendingAnchor`) pra rolar ate o
    titulo certo depois que o arquivo novo renderizar.
11. **Tentativa de embutir `mdviu.ico`/`OnyxBlue.vsf` no `.exe` (revertida)**
    — pra nao depender dos dois arquivos soltos, foram compilados como
    recursos (`{$R *.res}`/`{$R *.dres}` no `.dpr`, novo pra esse projeto —
    nunca tinha nenhum `{$R}`). Isso trouxe, sem querer, o **manifesto
    padrao do Windows** que a IDE gera junto (antes o `.exe` nao tinha
    manifesto nenhum). Manifesto muda dois comportamentos do Windows ao
    mesmo tempo: ativa controles com tema (ComCtl32 v6 — por isso o hover
    dos botoes da toolbar passou de contorno fino pra preenchimento colorido)
    e ativa DPI-aware de verdade (`PerMonitorV2`, ja configurado no projeto
    mas nunca de fato linkado) — como a interface inteira e montada em
    codigo no `FormCreate` com posicao/tamanho em pixel fixo (sem `.dfm`,
    decisao de projeto pra evitar risco de corrupcao do arquivo), isso
    expos um bug de layout em tela com escala >100% que nunca tinha
    aparecido (testado numa maquina com 150%). Tentei remover so o
    manifesto (mantendo icone/estilo embutidos) via `UpdateResource` da
    API do Windows num passo pos-build — funcionou, mas exigiria rodar um
    script toda vez que recompilar, o que nao e como nenhum outro projeto
    Delphi funciona. **Revertido**: `mdviu.ico`/`OnyxBlue.vsf` voltam a ser
    arquivos soltos (`TStyleManager.LoadFromFile`/`Icon.LoadFromFile`, como
    sempre foi), `.dpr` sem
    `{$R}` nenhum, de novo sem manifesto. Se um dia quiser mesmo embutir o
    icone, o jeito correto e sem gambiarra e reconstruir a interface pelo
    Form Designer (`.dfm` normal, componentes em tempo de design) em vez de
    montar tudo em codigo — ai o VCL escala sozinho pra qualquer DPI, do
    jeito que os outros programas Delphi do autor sempre funcionaram.
12. **Interface refeita pelo Form Designer (resolve o item 11)** — a tela
    passou a ser 100% `.dfm`, e icone + estilo vem da configuracao do
    projeto (ver [Arquitetura](#arquitetura)). Com isso o manifesto
    (temas + `PerMonitorV2`) entra de proposito e o VCL escala a tela
    sozinho em qualquer DPI. Os botoes da barra agora sao pintados pelo
    tema Onyx Blue (hover azul preenchido) em vez do azul fixo pintado na
    mao de antes. O texto cinza do tema ficava ilegivel; corrigido no
    `.dfm` com `StyleElements = [seClient, seBorder]` (sem `seFont`) e
    `Font.Color = clWhite` — so o texto fica branco, fundo/borda/hover
    continuam do estilo.
13. **"Piscada" na abertura** (cinza → branco → preto → documento) — cinza
    era o fundo do `TEdgeBrowser` (`Color` herdada do form) enquanto o
    WebView2 iniciava; branco, o fundo padrao do WebView2; preto (`#121212`),
    o fundo do Chromium com o Windows em tema escuro antes da pagina pintar.
    Agora tudo usa a cor de fundo do `body` do estilo atual
    (`StylePageColors` le do CSS): `Color` do form, variavel
    `WEBVIEW2_DEFAULT_BACKGROUND_COLOR` antes de criar o WebView2,
    `DefaultBackgroundColor` em `ApplyPageColors`, e o CSS ja embutido na
    pagina inicial. `PreferredColorScheme` fica **sempre claro**, mesmo em
    estilo escuro: no esquema escuro o Chromium pinta a pagina em branco
    inicial (`about:blank`) com o `#121212` dele, ignorando o
    `DefaultBackgroundColor` (nenhum CSS usa `prefers-color-scheme`, entao
    o estilo escuro continua escuro). O 1o quadro da janela o Windows 11
    mostrava em branco antes de o form se desenhar (a cor de fundo da
    classe da janela nao adianta): a janela nasce encoberta
    (`DWMWA_CLOAK` em `CreateWnd`) e so e revelada depois de desenhada
    (`DoShow` posta `WMRevealWindow`). Verificado gravando a abertura com
    Claro e Escuro como padrao, Windows em tema escuro.

## Como compilar

Target **Win64** (a `WebView2Loader.dll` bundlada e x64). Duas formas,
mesmo resultado (`MDviu.exe` gerado em `MDviu_Delphi\`, ao lado de
`lib\`/`styles\`):

- **IDE**: abrir `MDviu.dproj`, plataforma Windows 64-bit, Build.
- **Linha de comando**: `MDviu_Delphi\build.bat` (ou `build.bat Debug`) —
  chama o `rsvars.bat` do RAD Studio e o `msbuild` no `MDviu.dproj`.

Nao usar `dcc64 MDviu.dpr` direto: o `dcc64` sozinho nao gera o
`MDviu.res`, entao o `.exe` sai sem icone e sem estilo (ou nem compila, se
o `.res` nao existir). Arquivos que tem que acompanhar o `MDviu.exe`: ver
[Arquivos que acompanham o exe](#arquivos-que-acompanham-o-exe).
