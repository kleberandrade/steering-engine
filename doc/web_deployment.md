# Online laboratories / Laboratórios online

| Application / Aplicação | URL |
| --- | --- |
| Flutter steering laboratory | https://kleberandrade.github.io/steering-engine/ |
| Flame integration demo | https://kleberandrade.github.io/steering-engine/flame/ |
| Learning Wiki / Wiki didática | https://github.com/kleberandrade/steering-engine/wiki |

The main laboratory accepts a `mode` query parameter matching its dropdown label,
for example `?mode=Path%20following`, `?mode=Queue`, or `?mode=Flocking`. The query
is read once at startup. Unknown or missing values select Arrive. Existing pause,
step, reset and population controls remain available.

O parâmetro `mode` abre a cena correspondente ao capítulo. Recarregue o link para
trocar o modo inicial; valores ausentes ou desconhecidos abrem Arrive. O dropdown
continua permitindo trocar o comportamento sem recarregar.

## Deployment / Publicação

The Dart and Flutter CI workflow builds both applications with their hosting base
paths. After **all** Dart, Flutter and Flame checks pass on main, the Pages job
downloads those exact web artifacts, combines them into one site and deploys it.
Pull requests build/test but do not publish. Deployment concurrency serializes
site publication. No personal access token is stored in the repository.

O deploy usa os artefatos já testados, após todos os jobs passarem na main.
O laboratório fica na raiz do projeto, e Flame em `/flame/`. PRs não publicam.
O job de deploy tem permissões de Pages/OIDC; os outros continuam com leitura.

GitHub repository Settings → Pages must use **GitHub Actions** as its source.
The workflow environment `github-pages` exposes the actual deployment URL.
Verify the workflow and live app after each infrastructure change; source links
alone are not deployment evidence.

## Reproduce the hosted build / Reproduzir o build

From each app directory, using its supported Flutter SDK:

```sh
# example/flutter_lab
flutter pub get
flutter build web --no-web-resources-cdn --base-href /steering-engine/
```

```sh
# example/flame_lab
flutter pub get
flutter build web --no-web-resources-cdn --base-href /steering-engine/flame/
```

The base paths are specific to this project’s GitHub Pages URL. Use `/` or your
own path when hosting elsewhere. CanvasKit is included in the build rather than
loaded from the Flutter engine CDN. Browser/device performance still varies.

Os caminhos base devem acompanhar a hospedagem. Publicação web não publica o
package no pub.dev e não depende de um upload hospedado: ambos os apps usam o
package local durante o build.

Official references / Referências oficiais:

- [GitHub Pages custom workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
- [Flutter web deployment](https://docs.flutter.dev/deployment/web)
- [Flutter URL/base-path configuration](https://docs.flutter.dev/ui/navigation/url-strategies)
