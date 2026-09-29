---
name: commit
description: Commit, git commit, create a commit, or prepare commit messages. Use when asked to commit repository changes or propose a Conventional Commit message.
---

# Commit Changes

Create small, reviewable commits using Conventional Commits.

## Workflow

1. Inspect `git status`, staged and unstaged diffs, and recent commit subjects before staging anything.
2. Identify the changes that belong to the user's request. Do not alter or include unrelated worktree changes.
3. Check the selected diff for secrets, generated files, debugging code, and accidental artifacts.
4. Run the narrowest relevant tests or validation. If validation cannot run, state why.
5. Stage only the intended paths or hunks. Never use `git add .` or `git add -A` when unrelated changes exist.
6. Review the staged diff and diff stat before committing.
7. Create the commit with a concise Conventional Commit subject. Add a body only when it explains non-obvious motivation, constraints, or consequences.
8. Verify the resulting commit and report its short hash, subject, and validation performed.

Never amend, push, force-push, bypass hooks, or discard changes unless the user explicitly requests it. If a hook rejects the commit, fix the issue and create a new commit rather than bypassing the hook.

## Message Format

Use this subject format:

```text
<type>(<scope>): <imperative summary>
```

Omit the scope when it adds no useful context. Keep the subject lowercase after the colon, concise, and without a trailing period.

Choose the type by intent:

- `feat`: add or change user-visible behavior
- `fix`: correct faulty behavior
- `docs`: change documentation only
- `refactor`: restructure code without changing behavior
- `test`: add or revise tests only
- `perf`: improve performance
- `build`: change the build system or dependencies
- `ci`: change continuous integration
- `chore`: perform maintenance or repository housekeeping
- `style`: change formatting without affecting behavior
- `revert`: revert an earlier commit

Use repository scopes where applicable:

- `spec` for `spec.md` and related product specification work
- `models` for the `Models` package and `spec-data-models.md`

Examples:

```text
docs(spec): clarify workout completion behavior
feat(models): add workout set entity
fix(models): preserve exercise ordering
chore: update gitignore
```

For a breaking change, append `!` before the colon and explain the migration in the body:

```text
feat(models)!: replace workout identifier type
```

## Commit Boundaries

Prefer one commit when all changed files implement one cohesive intent. Split changes when they represent independently reviewable concerns, require different Conventional Commit types, or mix preparatory refactoring with behavior changes. Ask before splitting if the desired boundary is ambiguous.
