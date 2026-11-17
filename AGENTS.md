# steering_engine engineering workflow

- Keep the core pure Dart: no runtime dependencies, Flutter imports, IO or network.
- Follow doc/architecture.md and the exact conventions in doc/behaviors.md.
- Preserve immutable vectors, validated snapshots and copied composition lists.
- Wander owns state: one instance per agent, one evaluation per simulation step.
- Validate numeric parameters in runtime code, not only assertions.
- Test through the public entry point using independent expected mathematics.
- Add a failing regression before changing existing behavior.
- Synchronize English and Portuguese docs, examples and Unreleased notes.
- Use semantic commits and record concise evidence in doc/engineering_log.md.
- Run CONTRIBUTING.md checks; distinguish local validation from remote CI.
- Never claim a pub.dev publication, release or score without verification.
- Do not change unrelated repositories or worktrees.
