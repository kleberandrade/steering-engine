# Versioning and publishing / Versionamento e publicação

## Automatic bump / Bump automático

After a successful **push** CI run on current main, `.github/workflows/release.yml`
examines conventional commits since the tag matching the current pubspec version.
It refuses stale/dirty checkouts, missing base tags and existing next tags.
Only release metadata changes: `pubspec.yaml` and `CHANGELOG.md`.

Após o CI da main passar, o workflow calcula a versão pelos commits desde a
última tag correspondente ao pubspec. Não altera código de runtime, não move
uma tag já publicada e não interpreta cada commit como uma nova versão.

| Commit / Opção | Automatic result / Resultado automático |
| --- | --- |
| `fix: ...`, `perf: ...` | Patch: 0.2.0 → 0.2.1 |
| `feat: ...` | Minor: 0.2.0 → 0.3.0 |
| Header `!` or footer `BREAKING CHANGE:` | Major after 1.0; before 1.0, next minor / major após 1.0; minor antes de 1.0 |
| Only docs/test/chore/style/ci commits | No automatic release / sem release automática |
| Explicit manual `major` | May advance 0.x to 1.0.0 / pode avançar para 1.0.0 |

The highest applicable level wins. Existing Unreleased notes move into the dated
version section; if empty, commit summaries supply the notes. The date uses
America/Sao_Paulo. README hosted dependency pins are not blindly advanced before
hosted availability is verified.

Prevalece o maior nível. As notas de Unreleased migram para a nova versão. O
commit automático `chore(release): ...` não é um novo pedido de release.

## Execution chain / Encadeamento

1. Main source passes the complete Dart/Flutter/Flame CI.
2. The release job confirms that main still equals that exact validated commit.
   A newer main waits for its own CI. It accepts no PR/fork artifacts or code.
3. The metadata bump is validated again with Dart analysis/tests and package dry
   run. Metadata commit and annotated tag are pushed **atomically**, without force.
4. A GitHub source release is created from that tag.
5. If `PUB_DEV_PUBLISH_ENABLED=true`, the job explicitly dispatches `publish.yml`
   **on the tag**, with `publish=true`. Its own minimum/stable gates must pass.
6. Pub.dev's official Dart reusable workflow authenticates via OIDC in environment
   `pub.dev`. Confirm actual hosted metadata/audit log after publication.

O token padrão do GitHub não dispara outro workflow apenas por criar uma tag.
Por isso há um dispatch explícito na tag. O pub.dev aceita workflow_dispatch com
referência de tag, conforme a discussão do mantenedor ligada nas fontes. Não
se usa publicação a partir da referência main nem token pessoal persistente.

The explicit dispatch avoids GitHub's recursive-event suppression with its
standard token. Branch-based upload requests are rejected, not silently treated
as releases. Only a matching stable `vX.Y.Z` tag can reach the upload job.

## Manual preview and release / Prévia e release manual

Open Actions → **Automatic version and source release** → Run workflow on main.
Choose auto/patch/minor/major. `dry_run=true` is the default: it prints the planned
version without writing metadata, creating tags/releases or publishing.

Para uma release manual efetiva, selecione `dry_run=false` depois de o CI do
commit exato passar. Para apenas conferir o próximo patch, mantenha true e
selecione patch. Não recrie 0.2.0 nem reutilize uma versão já hospedada.

A manual run of **Prepare and publish to pub.dev** defaults to preflight only.
Upload is possible only when explicitly selecting an existing version tag,
`publish=true`, and the repository activation flag. The tag must match pubspec.

## Pub.dev activation / Ativação no pub.dev

The bump/source-release workflow is installed independently of hosted upload.
`AUTO_RELEASE_ENABLED=false` disables automatic bumps; manual previews remain
available. Hosted upload stays conditional on explicit external authorization.
No pub.dev trust grant or enabling variable has been set by merely adding YAML.

| Setting / Campo | Value / Valor |
| --- | --- |
| Package / Pacote | steering_engine |
| GitHub repository / Repositório | kleberandrade/steering-engine |
| Pub.dev tag pattern / Padrão | `v{{version}}` |
| Required environment / Ambiente exigido | `pub.dev` |
| Publish activation variable / Variável | `PUB_DEV_PUBLISH_ENABLED=true`, after authorization is confirmed |
| Authentication / Autenticação | Temporary GitHub OIDC; no personal token |

The [package Admin page](https://pub.dev/packages/steering_engine/admin) must
explicitly authorize this repository, tag pattern and environment. An uploader or
publisher administrator must grant that persistent publishing authority. Only
then enable the repository flag. Existing ownership must be verified separately;
this workflow does not transfer the package to kleberandrade.dev.

A autorização persistente permite publicar versões a quem pode enviar alterações
relevantes à main/tags, após os gates. A confirmação independente do publisher e
a ativação no pub.dev continuam pendentes enquanto o domínio estiver bloqueado.
Não adicione credenciais pessoais ao repositório para contornar esse bloqueio.

## Failure and recovery / Falhas e recuperação

- A concurrent main change or branch-protection rejection stops the atomic push;
  do not force-push or weaken repository rules to make the release succeed.
- A retry against an already tagged version has no new releasable commits and
  does not bump it again. Never move/recreate a published tag.
- If metadata/tag push succeeds but GitHub release creation or publisher dispatch
  fails, recover using that existing tag: create the missing GitHub release or
  manually dispatch the publisher on the tag after reviewing the failed run.
- A successful upload is immutable. Verify hosted state before retrying a failed
  upload job; do not treat source CI, a dry run or a tag as upload evidence.

A recuperação usa a tag existente; não gera outra versão para esconder uma falha.
O workflow ignora commits de documentação isolados e impede encadeamento recursivo.

## Evidence and sources / Evidência e fontes

Manual publishing preflight [44078811339](https://github.com/kleberandrade/steering-engine/actions/runs/44078811339)
passed Dart 3.3/stable before the automatic-bump addition; no upload occurred.
New bump policy and Git fixture tests execute in CI. Manual preview evidence is
recorded after the workflow has run, independently of pub.dev activation.

- [Dart automated publishing](https://dart.dev/tools/pub/automated-publishing)
- [Pub.dev maintainer discussion: tag dispatch](https://github.com/dart-lang/pub-dev/issues/8507)
- [GitHub token event behavior](https://docs.github.com/en/actions/concepts/security/github_token)
- [Official Dart reusable workflow](https://github.com/dart-lang/setup-dart/blob/main/.github/workflows/publish.yml)
