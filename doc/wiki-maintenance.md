# Maintaining the learning wiki / Mantendo a Wiki didática

The reviewed source of truth is [doc/wiki/Home.md](wiki/Home.md). Each algorithm
chapter is bilingual and contains intuition, an exact conceptual SVG, pseudocode,
parameters, a Dart configuration, an experiment and limits. Use the same vocabulary
as Foundations and check the implementation before changing formulas.

As fontes revisadas ficam em `doc/wiki/`. Atualize português e inglês juntos;
diagramas mostram a geometria, não uma trajetória prometida. Não mantenha uma
segunda explicação manualmente na interface da Wiki.

## Review / Revisão

```sh
python3 tool/check_docs.py
python3 tool/generate_wiki_diagrams.py --check
```

The documentation checker validates local links, SVG XML, algorithm coverage and
navigation. It can extract self-contained Dart examples for analysis/execution:

```sh
python3 tool/check_docs.py --extract-dart /tmp/steering-doc-examples
```

Analise e execute os exemplos com a configuração de packages do repositório.
Read code snippets as configurations unless they include their own import and
function. Shared pseudocode uses helper definitions in Foundations.

## Publish / Publicar

GitHub Wiki is a separate Git repository. Create its first Home page in GitHub
before the first clone, as described in the [official instructions](https://docs.github.com/en/communities/documenting-your-project-with-wikis/adding-or-editing-wiki-pages).
The project wiki has already been initialized; normally just update the checkout.

```sh
git clone https://github.com/kleberandrade/steering-engine.wiki.git ../steering-engine.wiki
```

If the clone already exists, pull its current branch first. From this package:

```sh
git -C ../steering-engine.wiki pull --ff-only
python3 tool/sync_wiki.py ../steering-engine.wiki
git -C ../steering-engine.wiki diff --stat
git -C ../steering-engine.wiki add --all
git -C ../steering-engine.wiki commit -m "docs: sync reviewed learning guide"
git -C ../steering-engine.wiki push
python3 tool/sync_wiki.py ../steering-engine.wiki --check
```

Revise eventuais alterações manuais no clone antes de sincronizar: o comando
substitui os arquivos correspondentes às fontes. Não apaga outras páginas nem
faz operações de rede ou commits. URLs Markdown são adaptadas para a Wiki,
imagens são copiadas e links para guias externos ao handbook apontam ao repositório.
Review manual changes before syncing; matching files are overwritten. Other pages
are preserved. The tool itself never clones, commits, deletes or pushes.

Publish the package repository first, then the wiki mirror. Verify Home, a
chapter, an image and sidebar navigation in the browser. Do not claim publication
from a successful local export alone. No personal tokens or new permissions are
needed in this documentation source.
