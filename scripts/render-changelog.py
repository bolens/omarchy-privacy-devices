#!/usr/bin/env python3
"""Render CHANGELOG.md as a dependency-free Pages document."""

from __future__ import annotations
import argparse
import html
import re
from pathlib import Path

REPOSITORY_URL = ""


def markdown_link(match: re.Match[str]) -> str:
    target = match.group(2)
    if not target.startswith(("http://", "https://", "/", "#")):
        target = f"{REPOSITORY_URL}/blob/main/{target}"
    return f'<a href="{target}">{match.group(1)}</a>'


def inline(text: str) -> str:
    text = html.escape(text.strip())
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    text = re.sub(
        r"\[([^]]+)\]\((https?://[^ )]+|[./A-Za-z0-9_-][^: )]*)\)",
        markdown_link,
        text,
    )
    return re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)


def markdown(source: str) -> str:
    out, pending, paragraph = [], [], []
    in_list = False

    def flush() -> None:
        nonlocal in_list
        if pending:
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append(f"<li>{inline(' '.join(pending))}</li>")
            pending.clear()

    def close() -> None:
        nonlocal in_list
        flush()
        if in_list:
            out.append("</ul>")
            in_list = False

    def flush_paragraph() -> None:
        if paragraph:
            out.append(f"<p>{inline(' '.join(paragraph))}</p>")
            paragraph.clear()

    for raw in source.splitlines()[1:]:
        line = raw.rstrip()
        if re.match(r"^\[[^]]+\]:\s+", line):
            continue
        heading = re.match(r"^(#{2,3})\s+(.+)$", line)
        bullet = re.match(r"^-\s+(.+)$", line)
        if heading:
            flush_paragraph()
            close()
            marks, label = heading.groups()
            label = label.replace("[", "").replace("]", "")
            slug = re.sub(r"[^a-z0-9]+", "-", label.lower()).strip("-")
            out.append(
                f'<h2 id="{slug}">{inline(label)}</h2>'
                if marks == "##"
                else f"<h3>{inline(label)}</h3>"
            )
        elif bullet:
            flush_paragraph()
            flush()
            pending.append(bullet.group(1))
        elif line.startswith(("  ", "\t")) and pending:
            pending.append(line.strip())
        elif not line:
            flush_paragraph()
            close()
        else:
            close()
            paragraph.append(line)
    flush_paragraph()
    close()
    return "\n".join(out)


def main() -> None:
    global REPOSITORY_URL
    p = argparse.ArgumentParser()
    p.add_argument("--name", required=True)
    p.add_argument("--base-url", required=True)
    p.add_argument("--accent", default="#7dd3fc")
    p.add_argument("--social-image", default="social-card.png")
    p.add_argument("--favicon", default="favicon.svg")
    p.add_argument("--docs-shell", action="store_true")
    p.add_argument("--source", type=Path, default=Path("CHANGELOG.md"))
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--check", action="store_true")
    a = p.parse_args()
    repo = a.base_url.rstrip("/").rsplit("/", 1)[-1]
    REPOSITORY_URL = f"https://github.com/bolens/{repo}"
    key = re.sub(r"[^a-z0-9]+", "-", a.name.lower()).strip("-") + "-changelog-mode"
    body = markdown(a.source.read_text(encoding="utf-8"))
    shell_assets = (
        '<script src="../assets/site.js" defer></script>' if a.docs_shell else ""
    )
    page = f'''<!doctype html><html lang="en" data-changelog-mode="system" data-color-mode-storage="{key}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="dark light"><meta name="theme-color" content="#09111d"><title>Changelog · {html.escape(a.name)}</title><meta name="description" content="Release history for {html.escape(a.name)}."><link rel="canonical" href="{a.base_url}changelog/"><meta property="og:type" content="website"><meta property="og:title" content="Changelog · {html.escape(a.name)}"><meta property="og:description" content="Release history for {html.escape(a.name)}."><meta property="og:url" content="{a.base_url}changelog/"><meta property="og:site_name" content="{html.escape(a.name)}"><meta property="og:image" content="{a.base_url}{a.social_image}"><meta property="og:image:width" content="1200"><meta property="og:image:height" content="630"><meta property="og:image:alt" content="{html.escape(a.name)} release history"><meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="Changelog · {html.escape(a.name)}"><meta name="twitter:description" content="Release history for {html.escape(a.name)}."><meta name="twitter:image" content="{a.base_url}{a.social_image}"><meta name="twitter:image:alt" content="{html.escape(a.name)} release history"><link rel="icon" href="../{a.favicon}">{shell_assets}<script>(()=>{{const r=document.documentElement,k='{key}',q=s=>typeof matchMedia==='function'?matchMedia(s):{{matches:false}},l=q('(prefers-color-scheme: light)'),d=q('(prefers-color-scheme: dark)');let m;try{{m=localStorage.getItem(k)}}catch{{}}if(!['system','time','light','dark'].includes(m))m='system';const x=()=>m==='time'?(new Date().getHours()>=7&&new Date().getHours()<19?'light':'dark'):m==='light'||m==='dark'?m:l.matches?'light':d.matches?'dark':'dark';const apply=()=>{{r.dataset.changelogMode=m;r.dataset.changelogScheme=x()}};apply();addEventListener('DOMContentLoaded',()=>{{const s=document.querySelector('[data-mode]');s.value=m;s.addEventListener('change',()=>{{m=s.value;try{{localStorage.setItem(k,m)}}catch{{}}apply()}})}});l.addEventListener?.('change',apply);d.addEventListener?.('change',apply);setInterval(()=>{{if(m==='time')apply()}},60000)}})()</script><style>
:root{{--accent:{a.accent};--bg:#09111d;--panel:#111d2d;--ink:#edf5ff;--muted:#9fb0c5;--line:#2a3c53;color-scheme:dark}}[data-changelog-scheme=light]{{--bg:#f5f7fa;--panel:#fff;--ink:#142033;--muted:#56677d;--line:#c8d2df;color-scheme:light}}*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--ink);font:16px/1.65 ui-sans-serif,system-ui,sans-serif}}a{{color:var(--accent)}}header{{position:sticky;top:0;z-index:2;display:flex;align-items:center;justify-content:space-between;gap:1rem;padding:.8rem max(1rem,calc((100vw - 74rem)/2));border-bottom:1px solid var(--line);background:color-mix(in srgb,var(--bg) 90%,transparent);backdrop-filter:blur(16px)}}header>a{{font-weight:800;text-decoration:none;color:var(--ink)}}nav,label{{display:flex;align-items:center;gap:.75rem}}label{{color:var(--muted);font-size:.8rem}}select{{max-width:9rem;padding:.45rem .6rem;border:1px solid var(--line);border-radius:.55rem;background:var(--panel);color:var(--ink)}}main{{width:min(74rem,calc(100% - 2rem));margin:auto;padding:clamp(2rem,6vw,5rem) 0}}.intro{{max-width:46rem;margin-bottom:2.5rem}}h1{{font-size:clamp(2.4rem,7vw,5.4rem);line-height:.95;letter-spacing:-.055em;margin:.2rem 0 1rem}}.intro p{{color:var(--muted);font-size:1.08rem}}h2{{display:inline-block;min-width:14rem;margin:2rem 2rem 1rem 0;padding-top:1.5rem;border-top:1px solid var(--line);font-size:1.15rem}}h3{{margin:1rem 0 .25rem;color:var(--accent);font-size:.78rem;text-transform:uppercase;letter-spacing:.12em}}p,ul{{max-width:52rem;overflow-wrap:anywhere;margin:.25rem 0 1rem}}li+li{{margin-top:.6rem}}code{{padding:.12rem .3rem;border-radius:.3rem;background:var(--panel)}}footer{{padding:2rem;text-align:center;color:var(--muted);border-top:1px solid var(--line)}}@media(max-width:700px){{header{{align-items:flex-start;flex-wrap:wrap}}nav{{flex-wrap:wrap}}label span{{position:absolute;width:1px;height:1px;overflow:hidden}}}}
</style></head><body><header><a href="../">{html.escape(a.name)}</a><nav><a aria-current="page" href="./">Changelog</a><a href="https://github.com/bolens/{repo}">GitHub</a><label><span>Theme</span><select data-mode aria-label="Color theme"><option value="system">System</option><option value="time">Day cycle</option><option value="light">Light</option><option value="dark">Dark</option></select></label></nav></header><main><div class="intro"><p>Release notes</p><h1>What changed.</h1><p>Generated from the project changelog whenever its release history changes.</p></div>{body}</main><footer><a href="../">Back to {html.escape(a.name)}</a></footer></body></html>'''
    page += "\n"
    if a.check:
        if not a.output.is_file() or a.output.read_text(encoding="utf-8") != page:
            raise SystemExit(f"{a.output}: stale; regenerate from {a.source}")
    else:
        a.output.parent.mkdir(parents=True, exist_ok=True)
        a.output.write_text(page, encoding="utf-8")


if __name__ == "__main__":
    main()
