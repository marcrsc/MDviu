// MDviu (Delphi) — logica de renderizacao dentro do WebView2.
// O Delphi chama renderMD() e setStyle() via ExecuteScript a cada carga e a cada F5
// (ele le o .md e o style.css direto do disco e injeta aqui, sem passar por rede/cache).

const contentEl = document.getElementById("content");

const md = window.markdownit({
    html: false,
    linkify: true,
    breaks: false,
});

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

// Chamado pelo Delphi (ExecuteScript) com o texto do .md e o nome do arquivo
function renderMD(text, filename) {
    contentEl.innerHTML = md.render(text);
    document.title = "MDviu - " + (filename || "sem nome");
}

// Chamado pelo Delphi (ExecuteScript) com o conteudo atual do style.css
function setStyle(css) {
    document.getElementById("user-style").textContent = css;
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
