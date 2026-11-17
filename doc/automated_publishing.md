# Automated publishing / Publicação automatizada

## Prepared state / Estado preparado

`.github/workflows/publish.yml` supports a read-only manual preflight and stable
version-tag releases. Actual publication is **disabled by default**: the publish
job requires a tag push and repository variable `PUB_DEV_PUBLISH_ENABLED=true`.
A manual run only validates; it never uploads, even if that variable is enabled.

O fluxo está preparado, mas preparar o arquivo não autoriza o repositório no
pub.dev. A versão 0.2.0 foi informada como publicada pelo mantenedor; a verificação
independente e a configuração da autorização continuam bloqueadas pelo acesso ao
domínio. Não recrie a tag 0.2.0 nem tente reenviar essa versão.

## Exact activation settings / Configuração exata para ativação

Review these settings before granting publishing access. This is a persistent
authorization: matching tag pushes can publish new package versions after checks.
No new permission has been granted merely by adding this workflow.

| Setting / Campo | Value / Valor |
| --- | --- |
| Package / Pacote | steering_engine |
| GitHub repository / Repositório | kleberandrade/steering-engine |
| pub.dev tag pattern / Padrão | `v{{version}}` |
| Required GitHub environment / Ambiente exigido | `pub.dev` |
| GitHub repository variable / Variável | `PUB_DEV_PUBLISH_ENABLED=true`, only after pub.dev authorization is confirmed |
| Authentication / Autenticação | Temporary GitHub OIDC, no personal token / temporária, sem token pessoal |

In the package's [Admin page](https://pub.dev/packages/steering_engine/admin),
enable publishing from GitHub Actions with that repository and pattern and require
the `pub.dev` environment. This requires an uploader or publisher administrator.
Confirm actual ownership before changing it; this workflow does not transfer a
package to a publisher.

Na página Admin, a autorização deve ser concedida explicitamente pelo mantenedor.
Depois configure o ambiente e a variável no GitHub. Ativar essa permissão permite
que quem pode enviar tags correspondentes publique versões; use revisores no
ambiente quando essa revisão fizer parte do processo da equipe.

## Release behavior / Comportamento

1. Prepare the new source version and changelog, keeping the already published
   version intact. / Prepare uma nova versão sem sobrescrever a anterior.
2. Run full CI and the workflow's manual preflight. The package must analyze/test
   on Dart 3.3 and stable; stable also runs `dart pub publish --dry-run`.
3. Push a stable tag such as `v0.2.1` only when pubspec version is exactly 0.2.1.
   The validation job rejects a mismatch. Prerelease tags are not configured.
4. If enabled, the official Dart reusable publishing workflow validates and
   packages the source and authenticates through OIDC in environment `pub.dev`.
5. Verify the resulting hosted version, publisher and pub.dev audit-log entry.
   A successful source tag or preflight is not proof of upload.

The existing 0.2.0 tag predates this workflow. Adding the file does not trigger a
retroactive publication. Do not force-move a released tag to make it run.

## Disable / Desativar

Set `PUB_DEV_PUBLISH_ENABLED` to `false` or remove the variable to stop this
workflow from requesting publication. Revoke the repository authorization in
pub.dev to remove its publishing authority independently of workflow contents.
Both actions are separate from deleting or unpublishing a package version.

## Sources / Fontes

- [Official Dart automated publishing](https://dart.dev/tools/pub/automated-publishing)
- [Official reusable workflow](https://github.com/dart-lang/setup-dart/blob/main/.github/workflows/publish.yml)

This repository follows the documented stable-tag/OIDC flow. Activation and an
actual future upload must be recorded separately after verification.
