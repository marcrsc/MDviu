# MDviu

Visualizador de Markdown leve e customizavel via CSS externo.

> **Projeto pessoal, sem suporte.** Feito pra uso proprio, customizado
> conforme as preferencias do autor — nao e um produto. Mesmo compartilhado
> com a comunidade, nao ha nenhum tipo de suporte (ver isencao de
> responsabilidade na [licenca](LICENSE)).

## Indice

- [Visao geral](#visao-geral)
- [Os dois apps deste repositorio](#os-dois-apps-deste-repositorio)
- [Uso](#uso)
- [Estrutura do repositorio](#estrutura-do-repositorio)
- [Licenca](#licenca)
- [Para continuar o projeto](#para-continuar-o-projeto)

## Visao geral

MDviu nasceu de um estudo sobre como fazer um leitor de Markdown rapido de abrir,
com controle total do visual via CSS (como se cada elemento — titulos, tabela,
links, blocos de codigo, destaques, regua horizontal — fosse estilizavel
igual a uma pagina HTML comum).

O repositorio guarda dois apps:

1. **MDviu_Delphi** — o app de verdade: programa Windows nativo (Delphi +
   WebView2), com duplo clique, associação de arquivo, barra de ferramentas,
   multiplos estilos CSS trocaveis e exportação em PDF.
2. **MDviu_HTML** — protótipo em HTML/CSS/JS puro, sem instalação, usado pra
   desenhar o CSS sem precisar compilar nada.

## Os dois apps deste repositorio

| App | Pasta | Detalhes |
|---|---|---|
| MDviu (Delphi) | [MDviu_Delphi/](MDviu_Delphi/) | [MDviu.md](MDviu_Delphi/MDviu.md) |
| MDviu_HTML (protótipo) | [MDviu_HTML/](MDviu_HTML/) | [MDviu_HTML.md](MDviu_HTML/MDviu_HTML.md) |

## Uso

So pra **rodar** o MDviu (Delphi) ja compilado:

- Windows com o **WebView2 Runtime** instalado (vem por padrao no
  Windows 11; se faltar, o Windows instala sozinho quando necessario).
  Deve funcionar em Windows a partir do 7, nao testado.
- **Compilado só pra Windows 64 bits** — não roda em Windows de 32 bits.
- Estes arquivos juntos, na mesma pasta — todos ja prontos em
  `MDviu_Delphi/` no repositorio, exceto o `.exe` (gerado ao compilar, ver
  link no fim desta secao; nao fica no repositorio, `*.exe` esta no
  `.gitignore`):

  | Arquivo | Para que serve |
  |---|---|
  | `MDviu.exe` | O programa (icone e estilo visual ja vem dentro dele) |
  | `WebView2Loader.dll` | Loader do WebView2 — sem ele o app nao abre |
  | `lib\` | Scripts (markdown-it, highlight.js, script.js) |
  | `styles\*.css` | Estilos disponiveis na combo "Estilo" |

  Detalhe de cada um em
  [MDviu_Delphi/MDviu.md#arquivos-que-acompanham-o-exe](MDviu_Delphi/MDviu.md#arquivos-que-acompanham-o-exe).
- Abrir um `.md`: duplo clique (apos associar a extensao ao `MDviu.exe` nas
  propriedades do Windows), pelo botao "Abrir..." dentro do programa, ou
  `MDviu.exe caminho\do\arquivo.md` pela linha de comando.

Para compilar, veja instrucoes em
[MDviu_Delphi/MDviu.md#como-compilar](MDviu_Delphi/MDviu.md#como-compilar).

## Estrutura do repositorio

```
MDviu/
├── MDviu_Delphi/       App de verdade (Delphi + WebView2)
│   ├── MDviu.md        Detalhes deste app
│   ├── lib/            script.js e markdown-it usados pelo app
│   └── styles/         CSS editaveis (combo "Estilo")
├── MDviu_HTML/         Protótipo HTML/CSS/JS puro
│   └── MDviu_HTML.md   Detalhes deste protótipo
├── AGENTS.md           Regras e contexto pra quem (ou IA) continuar o projeto
├── LICENSE             Licenca MIT
└── README.md           Este arquivo
```

## Licenca

MIT — ver [LICENSE](LICENSE). Livre pra usar, copiar, modificar e
redistribuir, por sua conta e risco (sem garantia nem responsabilidade do
autor por danos).

Parte do desenvolvimento (codigo, documentacao e testes) teve assistencia de
IA (Claude, Anthropic) — ver os commits com `Co-Authored-By: Claude` no
historico do Git.

O app MDviu (Delphi) embute duas bibliotecas de terceiros, cada uma com sua
propria licenca permissiva — detalhes (versao, fonte, licenca) em
[MDviu_Delphi/MDviu.md#bibliotecas-de-terceiros](MDviu_Delphi/MDviu.md#bibliotecas-de-terceiros):

- [markdown-it](https://github.com/markdown-it/markdown-it) — MIT
- [highlight.js](https://github.com/highlightjs/highlight.js) — BSD-3-Clause

## Para continuar o projeto

Leia o [AGENTS.md](AGENTS.md) antes de mexer em qualquer coisa — tem as regras
e as decisões importantes que já foram tomadas.
