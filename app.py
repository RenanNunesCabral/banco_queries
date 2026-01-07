
# app.py
import streamlit as st
import streamlit.components.v1 as components
from pathlib import Path

st.set_page_config(page_title="Repositório de Códigos SQL", page_icon="🗂️", layout="wide")

# === Utilidades ===
def read_text_safe(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""

def inject_assets(index_html: str, css: str, js: str) -> str:
    """
    Insere <style> e <script> no HTML fornecido.
    - Se houver </head>, injeta o CSS antes.
    - Se houver </body>, injeta o JS antes.
    - Se for fragmento (sem <html>), empacota como documento completo.
    """
    index_html = index_html or ""
    css_block = "<style>\n" + (css or "") + "\n</style>"
    js_block = "<script>\n" + (js or "") + "\n</script>"

    html = index_html
    lower = html.lower()
    has_html_tag = "<html" in lower
    has_head_close = "</head>" in lower
    has_body_close = "</body>" in lower

    if has_html_tag:
        if has_head_close:
            html = html.replace("</head>", css_block + "\n</head>", 1)
        else:
            # adiciona <head> se não existir
            html = html.replace(
                "<html",
                "<html><head><meta charset=\"UTF-8\">"
                "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
                + css_block +
                "</head>",
                1
            )
        if has_body_close:
            html = html.replace("</body>", js_block + "\n</body>", 1)
        else:
            html = html + "\n" + js_block
    else:
        # Fragmento: empacota como documento completo
        html = (
            "<!DOCTYPE html>\n"
            "<html lang=\"pt-BR\">\n"
            "<head>\n"
            "  <meta charset=\"UTF-8\">\n"
            "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
            + css_block + "\n"
            "</head>\n"
            "<body>\n"
            + index_html + "\n"
            + js_block + "\n"
            "</body>\n"
            "</html>\n"
        )
    return html

# === Leitura dos arquivos locais ===
base = Path(".")
index_html = read_text_safe(base / "index.html")
css = read_text_safe(base / "styles.css")
js = read_text_safe(base / "script.js")

if not (index_html or css or js):
    st.error("Arquivos não encontrados. Coloque index.html, styles.css e script.js na mesma pasta do app_v2.py.")
else:
    # Controles de UI para altura e rolagem
    st.sidebar.header("Configurações do iframe")
    height = st.sidebar.slider("Altura (px)", min_value=400, max_value=2000, value=900, step=50)
    scrolling = st.sidebar.toggle("Habilitar rolagem", value=True)

    final_html = inject_assets(index_html, css, js)
    components.html(final_html, height=height, scrolling=scrolling)

    # Download do HTML único (opcional)
    st.download_button(
        label="Baixar página compilada (HTML único)",
        data=final_html,
        file_name="page_compiled.html",
        mime="text/html",
    )
