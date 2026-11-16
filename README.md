# MDviu

Visualizador de Markdown leve e customizavel via CSS externo.

## Indice

- [Visao geral](#visao-geral)
- [Os dois apps deste repositorio](#os-dois-apps-deste-repositorio)
- [Estrutura do repositorio](#estrutura-do-repositorio)
- [Para continuar o projeto](#para-continuar-o-projeto)

## Visao geral

MDviu nasceu de um estudo sobre como fazer um leitor de Markdown rapido de abrir,
com controle total do visual via CSS (como se cada elemento — titulos, tabela,
links, blocos de codigo, destaques, regua horizontal — fosse estilizavel
igual a uma pagina HTML comum).

O repositorio guarda dois apps, nessa ordem de evolucao:

1. **MDviu_HTML** — protótipo em HTML/CSS/JS puro, sem instalação, usado pra
   desenhar o CSS sem precisar compilar nada.
2. **MDviu_Delphi** — o app de verdade: programa Windows nativo (Delphi +
   WebView2), com duplo clique, associação de arquivo, barra de ferramentas,
   multiplos estilos CSS trocaveis e exportação em PDF.

## Os dois apps deste repositorio

| App | Pasta | Detalhes |
|---|---|---|
| MDviu (Delphi) | [MDviu_Delphi/](MDviu_Delphi/) | [MDviu_Delphi/MDviu.md](MDviu_Delphi/MDviu.md) |
| MDviu_HTML (protótipo) | [MDviu_HTML/](MDviu_HTML/) | [MDviu_HTML/MDviu_HTML.md](MDviu_HTML/MDviu_HTML.md) |

## Estrutura do repositorio

```
MDviu/
├── MDviu_Delphi/       App de verdade (Delphi + WebView2)
│   ├── MDviu.md        Detalhes deste app
│   └── web/            CSS, script.js e markdown-it usados pelo app
├── MDviu_HTML/         Protótipo HTML/CSS/JS puro
│   └── MDviu_HTML.md   Detalhes deste protótipo
├── AGENTS.md           Regras e contexto pra quem (ou IA) continuar o projeto
└── README.md           Este arquivo
```

## Para continuar o projeto

Leia o [AGENTS.md](AGENTS.md) antes de mexer em qualquer coisa — tem as regras
e as decisões importantes que já foram tomadas.
