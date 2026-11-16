# MDviu HTML (protótipo)

Protótipo em HTML/CSS/JS puro do visualizador de Markdown — sem instalação,
sem build, só abrir o `index.html` no navegador.

## Indice

- [Visao geral](#visao-geral)
- [Arquivos](#arquivos)
- [Como usar](#como-usar)
- [Relacao com o mdviu delphi](#relacao-com-o-mdviu-delphi)
- [Limitacoes](#limitacoes)

## Visao geral

Foi o primeiro passo do projeto: validar a ideia de customizar cada
elemento do Markdown renderizado (titulos, tabela, links, blocos de
codigo, destaques, regua horizontal) via um `style.css` comum, sem
precisar de nenhuma ferramenta além de um navegador.

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `index.html` | Pagina principal — area de conteudo + referencias ao CSS/JS |
| `style.css` | Estilo editavel (unico, modo claro) |
| `script.js` | Logica: drag-and-drop, F5, conversao via markdown-it |
| `lib/markdown-it.min.js` | Biblioteca de conversao Markdown -> HTML |

## Como usar

1. Abra `index.html` com duplo clique (abre no navegador padrao).
2. Arraste um arquivo `.md` pra dentro da janela.
3. Edite `style.css`, salve, aperte **F5** na janela do navegador — ele
   relê o mesmo arquivo do disco (sem precisar arrastar de novo).

O F5 funciona porque o drop usa a File System Access API do navegador
(`getAsFileSystemHandle`, quando disponivel em navegadores Chromium/Edge),
guardando uma referencia que pode ser relida a qualquer momento — com
fallback pra um `File` comum em navegadores sem esse suporte.

## Relacao com o mdviu delphi

Este protótipo deu origem ao [MDviu (Delphi)](../MDviu_Delphi/MDviu.md), o
app de verdade da familia. O `style.css` inicial foi a base dos estilos
`web\styles\*.css` de lá, mas os dois CSS **divergiram** — este arquivo
continua sendo mantido so como referencia/protótipo de CSS, nao recebe
mais as funcionalidades novas (toolbar, multiplos estilos, PDF, etc.).

## Limitacoes

- Sem duplo clique nativo / associacao de arquivo (precisa arrastar o
  `.md` pra dentro da janela ja aberta).
- Um unico estilo (`style.css`), sem combo de troca.
- Sem exportar PDF, sem botoes de navegacao entre arquivos `.md`.
- Destaque de texto (`==texto==`, `<mark>`) tem a mesma limitacao do
  MDviu (Delphi): sem plugin / HTML cru desativado.
