// MDviu_HTML — logica do visualizador: drag-and-drop + recarregar com F5

const contentEl = document.getElementById("content");
const dropMsgEl = document.getElementById("dropzone-msg");

// Guarda a referencia do ultimo arquivo solto, para o F5 reler do disco.
// Quando o navegador suporta (Chrome/Edge), guardamos um "handle" de verdade,
// que permite reler o arquivo atualizado sem reabrir dialog nenhum.
let currentHandle = null; // FileSystemFileHandle, se suportado
let currentFile = null;   // File (sempre disponivel como alternativa/fallback)

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
        token.attrSet("target", "_blank");
        token.attrSet("rel", "noopener noreferrer");
    }
    return defaultLinkOpen(tokens, idx, options, env, self);
};

async function renderMarkdown(text, filename) {
    contentEl.innerHTML = md.render(text);
    dropMsgEl.style.display = "none";
    document.title = "MDviu — " + (filename || "sem nome");
}

async function loadFromHandle(handle) {
    const file = await handle.getFile();
    currentFile = file;
    const text = await file.text();
    await renderMarkdown(text, file.name);
}

async function loadFromFile(file) {
    currentFile = file;
    const text = await file.text();
    await renderMarkdown(text, file.name);
}

async function reloadCurrent() {
    if (currentHandle) {
        // Rele do disco: pega o conteudo atualizado, mesmo que o arquivo
        // tenha sido editado em outro programa desde a ultima leitura.
        await loadFromHandle(currentHandle);
    } else if (currentFile) {
        // Fallback (navegadores sem suporte a File System Access API):
        // rele o mesmo objeto File. Pode nao refletir edicoes externas
        // recentes em todos os navegadores.
        const text = await currentFile.text();
        await renderMarkdown(text, currentFile.name);
    }
}

async function handleDrop(event) {
    event.preventDefault();
    const item = event.dataTransfer.items && event.dataTransfer.items[0];

    if (item && typeof item.getAsFileSystemHandle === "function") {
        // Chrome/Edge: handle de verdade, permite reler do disco depois (F5)
        const handle = await item.getAsFileSystemHandle();
        if (handle.kind === "file") {
            currentHandle = handle;
            await loadFromHandle(handle);
            return;
        }
    }

    // Fallback: apenas o conteudo do arquivo no momento do drop
    const file = event.dataTransfer.files[0];
    if (file) {
        currentHandle = null;
        await loadFromFile(file);
    }
}

// Impede o navegador de tentar abrir o arquivo solto como navegacao
window.addEventListener("dragover", (e) => e.preventDefault());
window.addEventListener("drop", handleDrop);

// Intercepta F5 para recarregar o MESMO arquivo em vez de recarregar a pagina
window.addEventListener("keydown", (event) => {
    if (event.key === "F5") {
        event.preventDefault();
        reloadCurrent();
    }
});
