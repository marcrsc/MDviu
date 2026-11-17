# Titulo nivel 1

## Titulo nivel 2

### Titulo nivel 3

#### Titulo nivel 4

##### Titulo nivel 5

###### Titulo nivel 6

Paragrafo normal com **negrito**, *italico*, ***negrito e italico***, `codigo inline`,
~~riscado~~ e um texto bem mais longo so pra ver como a linha quebra e como fica
o espacamento entre as linhas dentro do mesmo paragrafo quando o texto nao cabe
inteiro na largura da janela.

Segundo paragrafo, separado do primeiro, pra ver o espaco entre paragrafos.

## Listas

Lista sem ordem:

- Item 1
- Item 2
  - Subitem 2.1
  - Subitem 2.2
- Item 3

Lista numerada:

1. Primeiro
2. Segundo
   1. Segundo A
   2. Segundo B
3. Terceiro

## Links

[Link interno (rola ate Secao de tabelas)](#secao-de-tabelas)

[Link para outro arquivo .md local (pagina_a.md)](pagina_a.md)

[Link para subpasta com barra normal (subpasta/dentro.md)](subpasta/dentro.md)

[Link externo (Google)](https://www.google.com)

[Link externo (GitHub)](https://github.com)

## Citacao

> Uma citacao de bloco.
> Segunda linha, ainda dentro da mesma citacao.
>
> Paragrafo novo, dentro da mesma citacao.

## Codigo

Bloco de codigo com linguagem marcada:

```python
def soma(a, b):
    return a + b

print(soma(2, 3))
```

Bloco de codigo sem linguagem marcada:

```
texto simples
sem syntax highlight
```

## Destaque

Destaque via sintaxe `==texto==`: ==texto destacado==.

Destaque via HTML `<mark>`: <mark>texto destacado</mark>.

Os dois devem aparecer com o mesmo fundo amarelo (estilo `mark` do CSS).

Destaque aninhado dentro de negrito: **isto e negrito com ==destaque== dentro**.

Destaque no fim da linha: isto e <mark>so destaque</mark> no fim da linha.

Seguranca — qualquer outra tag HTML deve aparecer como texto literal, sem
executar nada: `<script>alert(1)</script>` escrito direto (sem crase) fica
assim: <script>alert(1)</script>. E uma tag qualquer sem crase: <b>isto
tambem literal</b> (nao deve ficar em negrito).

## Regua horizontal

Texto antes da regua.

---

Texto depois da regua.

## Seção de tabelas

| Coluna A | Coluna B | Coluna C |
| :--- | :---: | ---: |
| 1 | 2 | 3 |
| Texto curto | Um texto um pouco mais longo | X |
| `codigo inline` | **negrito** | *italico* |

| Coluna A | Coluna B | Coluna C | Coluna D | Coluna E | Coluna F | Coluna G | Coluna H | Coluna I | Coluna J |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |

## Imagens

![Imagem local JPG](imagem.jpg)
Imagem local JPG

![Imagem local PNG](imagem.png)
Imagem local PNG

![Imagem de exemplo](https://via.placeholder.com/300x120)
Imagem na web

![Imagem externa https](https://arquivo.com.br/imagens/Selo_50_Anos.png)
Imagem na web

<img width="100" src="https://arquivo.com.br/imagens/Selo_50_Anos.png">
Imagem na web via HTML inserido

---

Uma linha
Linha seguinte

Pula uma linha


Pula duas linhas



*Fim do arquivo de teste.*


