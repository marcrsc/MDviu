// MDviu (Delphi) — logica de renderizacao dentro do WebView2.
// O Delphi chama renderMD() e setStyle() via ExecuteScript a cada carga e a cada F5
// (ele le o .md e o style.css direto do disco e injeta aqui, sem passar por rede/cache).

const contentEl = document.getElementById("content");

// Flag unica pra desligar o highlight de bloco de codigo se precisar (sem
// interface pra isso por enquanto — so trocar aqui e recompilar).
const ENABLE_SYNTAX_HIGHLIGHT = true;

const md = window.markdownit({
    html: false,
    linkify: true,
    // quebra de linha simples (sem linha em branco) vira <br> — nao e o padrao
    // CommonMark (que ignora e junta num so fluxo), mas e como o usuario escreve.
    breaks: true,
    // Bloco de codigo (```lang) colorido via highlight.js (lib/highlight.min.js,
    // todas as linguagens). Retornar "" cai no escape padrao do markdown-it
    // (linguagem nao reconhecida, ou highlight desligado pela flag acima).
    highlight: function (code, lang) {
        if (!ENABLE_SYNTAX_HIGHLIGHT || !lang || !window.hljs || !window.hljs.getLanguage(lang)) {
            return "";
        }
        try {
            // Classe "hljs" no <code> (nao no <pre>) — e o que os temas da
            // propria lib esperam (ex.: "pre code.hljs{...}" no CSS do tema).
            return '<pre><code class="hljs">' +
                window.hljs.highlight(code, { language: lang, ignoreIllegals: true }).value +
                "</code></pre>";
        } catch (e) {
            return "";
        }
    },
});

// Quebras de linha em branco seguidas: o Markdown padrao ignora — 1 linha em
// branco ou 10 dao o mesmo paragrafo. Aqui, cada linha em branco ALEM da
// primeira vira um paragrafo vazio forcado (so um espaco invisivel "&nbsp;",
// pra nao depender de HTML cru/da caixa "HTML"). Nao mexe dentro de blocos de
// codigo (```/~~~) — la, linha em branco e conteudo literal.
function expandBlankLines(text) {
    const FENCE_RE = /(^ {0,3}(?:`{3,}|~{3,}).*$[\s\S]*?^ {0,3}(?:`{3,}|~{3,})[ \t]*$)/gm;
    return text
        .split(FENCE_RE)
        .map((part, i) => {
            if (i % 2 === 1) return part; // bloco de codigo capturado — nao mexe
            return part.replace(/\n{3,}/g, (match) => "\n\n" + "&nbsp;\n\n".repeat(match.length - 2));
        })
        .join("");
}

// Destaque de texto (<mark>), duas sintaxes aceitas: "==texto==" (nao existe
// no markdown-it nativo) e a tag HTML literal "<mark>texto</mark>" (precisa
// de regra propria porque "html: false" acima desliga HTML cru em geral —
// aqui so reconhecemos essas duas tags especificas, o resto continua escapado).
function markDelimTokenize(state, silent) {
    if (silent) return false;
    const start = state.pos;
    if (state.src.charCodeAt(start) !== 0x3d /* = */) return false;
    if (state.src.charCodeAt(start + 1) !== 0x3d) return false;

    const scanned = state.scanDelims(start, true);
    let len = scanned.length;
    if (len < 2) return false;

    let token;
    if (len % 2) {
        token = state.push("text", "", 0);
        token.content = "=";
        len -= 1;
    }
    // Cada marcador "==" vira seu PROPRIO token de texto (nao acumula em
    // state.pending): e assim que o markdown-it localiza, no postprocess,
    // o token exato que vira mark_open/mark_close sem apagar o texto entre eles.
    for (let i = 0; i < len; i += 2) {
        token = state.push("text", "", 0);
        token.content = "==";
        state.delimiters.push({
            marker: 0x3d,
            length: 0,
            jump: i,
            token: state.tokens.length - 1,
            end: -1,
            open: scanned.can_open,
            close: scanned.can_close,
        });
    }
    state.pos += scanned.length;
    return true;
}

function markDelimPostprocess(state) {
    const delimiters = state.delimiters;
    for (let i = 0; i < delimiters.length; i++) {
        const startDelim = delimiters[i];
        if (startDelim.marker !== 0x3d || startDelim.end === -1) continue;

        const endDelim = delimiters[startDelim.end];
        const openToken = state.tokens[startDelim.token];
        openToken.type = "mark_open";
        openToken.tag = "mark";
        openToken.nesting = 1;
        openToken.markup = "==";
        openToken.content = "";

        const closeToken = state.tokens[endDelim.token];
        closeToken.type = "mark_close";
        closeToken.tag = "mark";
        closeToken.nesting = -1;
        closeToken.markup = "==";
        closeToken.content = "";
    }
}

function markTagTokenize(state, silent) {
    const src = state.src;
    const pos = state.pos;

    if (src.slice(pos, pos + 6) === "<mark>") {
        if (!silent) state.push("mark_open", "mark", 1).markup = "<mark>";
        state.pos += 6;
        return true;
    }
    if (src.slice(pos, pos + 7) === "</mark>") {
        if (!silent) state.push("mark_close", "mark", -1).markup = "</mark>";
        state.pos += 7;
        return true;
    }
    return false;
}

md.inline.ruler.before("emphasis", "mark_delim", markDelimTokenize);
md.inline.ruler.before("emphasis", "mark_tag", markTagTokenize);
md.inline.ruler2.before("emphasis", "mark_delim", markDelimPostprocess);

// Classifica cada link como interno ou externo (ver secao 4 do style.css)
const defaultLinkOpen =
    md.renderer.rules.link_open ||
    function (tokens, idx, options, _env, self) {
        return self.renderToken(tokens, idx, options);
    };

md.renderer.rules.link_open = function (tokens, idx, options, env, self) {
    const token = tokens[idx];
    const hrefIndex = token.attrIndex("href");
    const href = hrefIndex >= 0 ? token.attrs[hrefIndex][1] : "";
    const isExternal = /^([a-z]+:)?\/\//i.test(href) || /^mailto:/i.test(href);

    token.attrJoin("class", isExternal ? "external-link" : "internal-link");
    if (isExternal) {
        // target=_blank sinaliza "nova janela" pro WebView2 (NewWindowRequested),
        // que o Delphi intercepta e sempre abre no navegador padrao do Windows.
        token.attrSet("target", "_blank");
        token.attrSet("rel", "noopener noreferrer");
    }
    return defaultLinkOpen(tokens, idx, options, env, self);
};

// Da um "id" a cada titulo (h1-h6), baseado no proprio texto, para os links
// internos (#ancora) rolarem ate o lugar certo na mesma janela.
const COMBINING_MARKS_RE = new RegExp(
    "[" + String.fromCharCode(0x0300) + "-" + String.fromCharCode(0x036f) + "]", "g"
);

function slugify(text) {
    const noAccents = text.normalize("NFD").replace(COMBINING_MARKS_RE, "");
    return noAccents
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9\s-]/g, "")
        .replace(/\s+/g, "-");
}

const defaultHeadingOpen =
    md.renderer.rules.heading_open ||
    function (tokens, idx, options, _env, self) {
        return self.renderToken(tokens, idx, options);
    };

md.renderer.rules.heading_open = function (tokens, idx, options, env, self) {
    const inlineToken = tokens[idx + 1];
    const text = inlineToken && inlineToken.type === "inline" ? inlineToken.content : "";
    tokens[idx].attrSet("id", slugify(text));
    return defaultHeadingOpen(tokens, idx, options, env, self);
};

// Posicao de rolagem de cada arquivo ja visitado nesta janela (guardada pelo
// proprio scroll do usuario, continuamente). Arquivo NOVO abre no topo; so o
// "Voltar" restaura onde a rolagem estava — F5/troca de estilo (mesmo arquivo)
// nao mexe em nada, fica onde esta.
const scrollPositions = {};
let currentPath = "";

window.addEventListener("scroll", () => {
    if (currentPath) scrollPositions[currentPath] = window.scrollY;
});

// Trocar de estilo (ou ligar/desligar a caixa "HTML") re-renderiza o MESMO
// arquivo, mas tamanhos/espacamentos mudam (ex.: Compacto) — a posicao em
// pixels de antes nao aponta mais pro mesmo trecho do texto. Em vez de guardar
// um pixel, guarda-se QUAL bloco (paragrafo, titulo, tabela, etc. — filho
// direto de #content) esta encostado no topo da tela, e o quanto ja se rolou
// pra dentro dele; depois do re-render, rola ate esse MESMO bloco (mesmo
// indice — o texto nao muda, so o CSS, entao a ordem dos blocos e identica).
//
// IMPORTANTE: a captura tem que acontecer ANTES do Delphi trocar o CSS
// (setStyle). O Delphi chama prepareScrollAnchor() antes de setStyle(); se a
// captura so acontecesse dentro de renderMD() (chamado depois de setStyle),
// mediria o conteudo ANTIGO ja com o CSS NOVO aplicado — todo encolhido —
// e acharia o bloco errado (foi o bug real: "pulava" pro fim do arquivo).
let pendingScrollAnchor = null;

function captureScrollAnchor() {
    const children = contentEl.children;
    let anchor = null;
    for (let i = 0; i < children.length; i++) {
        const top = children[i].getBoundingClientRect().top;
        if (top <= 1) {
            anchor = { index: i, offset: -top };
        } else {
            break;
        }
    }
    return anchor;
}

function restoreScrollAnchor(anchor) {
    if (!anchor) {
        window.scrollTo(0, 0);
        return;
    }
    const el = contentEl.children[anchor.index];
    if (!el) return;
    const absoluteTop = window.scrollY + el.getBoundingClientRect().top;
    window.scrollTo(0, absoluteTop + anchor.offset);
}

// Chamado pelo Delphi (ExecuteScript) ANTES de setStyle(), so quando vai
// re-renderizar o mesmo arquivo (troca de estilo ou caixa "HTML").
function prepareScrollAnchor(fullPath) {
    pendingScrollAnchor = fullPath === currentPath ? captureScrollAnchor() : null;
}

// Cauda comum a renderMD/renderSource: titulo da janela e rolagem (mesmo
// arquivo re-renderizado -> volta pro bloco de antes; "Voltar" -> posicao
// salva; arquivo novo -> topo). Ver comentario de scrollPositions acima.
function finishRender(fullPath, filename, isBack, anchor) {
    const isSameFile = fullPath === currentPath;
    document.title = "MDviu - " + (filename || "sem nome");

    if (isSameFile) {
        restoreScrollAnchor(anchor);
    } else if (isBack && scrollPositions[fullPath] !== undefined) {
        window.scrollTo(0, scrollPositions[fullPath]);
    } else {
        window.scrollTo(0, 0);
    }
    currentPath = fullPath || "";
}

// Chamado pelo Delphi (ExecuteScript) com o texto do .md, o nome do arquivo,
// se a caixinha "HTML" esta marcada (libera HTML cru so pra esta renderizacao —
// o <mark>/==texto== continua funcionando igual, nao depende disso), o caminho
// completo do arquivo (chave da rolagem) e se esta navegacao e um "Voltar".
function renderMD(text, filename, allowHtml, fullPath, isBack) {
    const anchor = pendingScrollAnchor;
    pendingScrollAnchor = null;

    md.set({ html: !!allowHtml });
    contentEl.innerHTML = md.render(expandBlankLines(text));
    finishRender(fullPath, filename, isBack, anchor);
}

function escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// Chamado pelo Delphi (ExecuteScript) quando o arquivo aberto NAO e .md, mas
// tem extensao reconhecida (uMain.pas/LanguageForExtension) — ex.: abrir um
// .pas direto, ou clicar num link local dentro de um .md que aponta pra um
// .pas. Mostra o arquivo inteiro como UM bloco de codigo (sem passar pelo
// markdown-it — nao faz sentido interpretar "==", "_", tabela etc. dentro de
// codigo-fonte).
function renderSource(text, filename, fullPath, isBack, lang) {
    const anchor = pendingScrollAnchor;
    pendingScrollAnchor = null;

    if (ENABLE_SYNTAX_HIGHLIGHT && window.hljs && window.hljs.getLanguage(lang)) {
        contentEl.innerHTML = '<pre><code class="hljs">' +
            window.hljs.highlight(text, { language: lang, ignoreIllegals: true }).value +
            "</code></pre>";
    } else {
        contentEl.innerHTML = "<pre><code>" + escapeHtml(text) + "</code></pre>";
    }
    finishRender(fullPath, filename, isBack, anchor);
}

// Chamado pelo Delphi (ExecuteScript) com o conteudo atual do style.css.
// Junto, liga o tema de highlight.js (claro/escuro, lib/highlight-*.min.css,
// embutidos no Shell como <style> separados) que combina com --mdviu-theme
// declarado no proprio style.css — sem precisar editar o style.css em si.
function setStyle(css) {
    document.getElementById("user-style").textContent = css;

    const theme = getComputedStyle(document.documentElement)
        .getPropertyValue("--mdviu-theme")
        .trim();
    const isDark = theme === "dark";
    document.getElementById("hljs-light-theme").disabled = isDark;
    document.getElementById("hljs-dark-theme").disabled = !isDark;
}

// Arrastar um arquivo nao e suportado (desativado de proposito: o F5 depois
// nao conseguiria relê-lo do disco, so o duplo clique/botao "Abrir..." sabem
// o caminho real). So evita que o navegador tente navegar pro arquivo solto.
window.addEventListener("dragover", (e) => e.preventDefault());
window.addEventListener("drop", (e) => e.preventDefault());

// Link interno pra OUTRO arquivo .md (ex.: "[veja](outro.md)"): intercepta o
// clique e avisa o Delphi, que resolve o caminho e decide mesma janela ou nova
// (caixinha "Nova janela"). Ancora pra mesma pagina (#...) o proprio navegador
// ja resolve sozinho, nao precisa de nada daqui.
document.addEventListener("click", (e) => {
    const link = e.target.closest("a");
    if (!link) return;

    const href = link.getAttribute("href") || "";
    if (href === "" || href.charAt(0) === "#") return;
    if (link.classList.contains("external-link")) return;

    e.preventDefault();
    if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage(JSON.stringify({ href: href }));
    }
});
