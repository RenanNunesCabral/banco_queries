
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
    """Insere <style> e <script> no HTML fornecido.
    - Se houver </head>, injeta o CSS antes.
    - Se houver </body>, injeta o JS antes.
    - Se o arquivo for apenas um fragmento (sem <html>), empacota como documento completo.
    """
    # Normaliza entradas
    index_html = index_html or ""
    css_block = f"<style>
{css or ''}
</style>"
    js_block = f"<script>
{js or ''}
</script>"

    html = index_html
    lower = html.lower()
    has_html_tag = "<html" in lower
    has_head_close = "</head>" in lower
    has_body_close = "</body>" in lower

    # Se for documento completo, injeta em head/body
    if has_html_tag:
        if has_head_close:
            # Injeta CSS antes de </head>
            html = html.replace("</head>", css_block + "
</head>", 1)
        else:
            # Se não tiver head, adiciona um
            html = html.replace("<html", f"<html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">{css_block}</head>", 1)
        if has_body_close:
            html = html.replace("</body>", js_block + "
</body>", 1)
        else:
            html = html + "
" + js_block
    else:
        # Fragmento: embala como documento completo
        html = (
            "<!DOCTYPE html>
"
            "<html lang="pt-BR">
"
            "<head>
"
            "  <meta charset="UTF-8">
"
            "  <meta name="viewport" content="width=device-width, initial-scale=1">
"
            f"  {css_block}
"
            "</head>
"
            "<body>
"
            f"{index_html}
"
            f"{js_block}
"
            "</body>
"
            "</html>
"
        )
    return html

# === Leitura dos arquivos locais ===
base = Path('.')
index_html = read_text_safe(base / 'index.html')
css = read_text_safe(base / 'styles.css')
js = read_text_safe(base / 'script.js')

if not (index_html or css or js):
    st.error("Arquivos não encontrados. Coloque index.html, styles.css e script.js na mesma pasta do app.py.")
else:
    # Controles de UI para altura e rolagem
    st.sidebar.header("Configurações do iframe")
    height = st.sidebar.slider("Altura (px)", min_value=400, max_value=2000, value=900, step=50)
    scrolling = st.sidebar.toggle("Habilitar rolagem", value=True)

    final_html = inject_assets(index_html, css, js)

    components.html(final_html, height=height, scrolling=scrolling)

    # Opcional: oferecer download do HTML compilado em um arquivo único
    st.download_button(
        label="Baixar página compilada (HTML único)",
        data=final_html,
        file_name="page_compiled.html",
        mime="text/html",
    )
