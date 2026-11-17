# Teste de highlight de sintaxe

Um bloco de codigo por linguagem, pra conferir visualmente o highlight.js
nos dois temas (Claro/Escuro). Cada bloco usa o identificador de linguagem
que o `script.js` passa pro highlight.js (ver `lib\highlight.min.js` e a
tabela em `MDviu.md#abrir-codigo-fonte-direto`).

## Indice

- [Pascal Delphi](#pascal-delphi)
- [Python](#python)
- [HTML](#html)
- [JavaScript](#javascript)
- [ASP VB](#asp-vb)
- [CSS](#css)
- [PHP](#php)
- [SQL](#sql)
- [TypeScript](#typescript)
- [INI](#ini)

## Pascal Delphi

Extensoes `.pas`/`.dpr`/`.dfm` — linguagem `pascal` (alias de `delphi`).

```pascal
unit Exemplo;

interface

type
  TPessoa = class // classe de exemplo
  private
    FIdade: Integer;
  public
    constructor Create(AIdade: Integer);
  end;

implementation

constructor TPessoa.Create(AIdade: Integer);
begin
  FIdade := AIdade; // comentario
  if FIdade >= 18 then
    WriteLn('Maior de idade');
end;

end.
```

## Python

Extensao `.py` — linguagem `python`.

```python
class Pessoa:
    """Classe de exemplo com idade."""

    def __init__(self, idade=18):
        self.idade = idade  # idade em anos

    def saudacao(self):
        if self.idade >= 18:
            return f"Ola, {self.idade} anos!"
        return "Ola, menor!"
```

## HTML

Extensoes `.html`/`.htm` — linguagem `html` (alias de `xml`).

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>Exemplo</title>
</head>
<body>
  <!-- comentario -->
  <h1 class="titulo">Ola, mundo!</h1>
  <p>Idade: <span id="idade">18</span></p>
</body>
</html>
```

## JavaScript

Extensao `.js` — linguagem `javascript`.

```javascript
class Pessoa {
  constructor(idade = 18) {
    this.idade = idade; // idade em anos
  }

  saudacao() {
    if (this.idade >= 18) {
      return `Ola, ${this.idade} anos!`;
    }
    return "Ola, menor!";
  }
}
```

## ASP VB

Extensao `.asp` — linguagem `vbscript-html` (VBScript misturado com HTML;
nao existe alias `asp` na lib, ver nota em `MDviu.md`).

```vbscript-html
<%
  ' comentario em VBScript
  Dim idade
  idade = 18
  If idade >= 18 Then
    Response.Write("Ola, adulto!")
  Else
    Response.Write("Ola, menor!")
  End If
%>
<html>
<body>
  <p>Idade: <%= idade %></p>
</body>
</html>
```

## CSS

Extensao `.css` — linguagem `css`.

```css
/* estilo de exemplo */
.titulo {
  color: #1565c0;
  font-size: 1.5em;
  font-weight: bold;
}

#idade {
  background-color: #f0f0ff;
  padding: 0.2em 0.5em;
  border-radius: 3px;
}
```

## PHP

Extensao `.php` — linguagem `php`.

```php
<?php
class Pessoa {
    private int $idade; // idade em anos

    public function __construct(int $idade = 18) {
        $this->idade = $idade;
    }

    public function saudacao(): string {
        if ($this->idade >= 18) {
            return "Ola, {$this->idade} anos!";
        }
        return "Ola, menor!";
    }
}
```

## SQL

Extensao `.sql` — linguagem `sql`.

```sql
-- cria tabela de exemplo
CREATE TABLE pessoas (
  id INT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  idade INT DEFAULT 18
);

SELECT nome, idade
FROM pessoas
WHERE idade >= 18
ORDER BY nome;
```

## TypeScript

Extensao `.ts` — linguagem `typescript`.

```typescript
class Pessoa {
  private idade: number;

  constructor(idade: number = 18) {
    this.idade = idade; // idade em anos
  }

  saudacao(): string {
    if (this.idade >= 18) {
      return `Ola, ${this.idade} anos!`;
    }
    return "Ola, menor!";
  }
}
```

## INI

Extensao `.ini` — linguagem `ini`.

```ini
; configuracao de exemplo
[Geral]
Nome=Pessoa Exemplo
Idade=18
Ativo=true

[Conexao]
Servidor=localhost
Porta=1433
```
