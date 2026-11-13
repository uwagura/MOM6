# Commits and pull requests

## Branches

- Work on a fork, branching from its default branch (e.g. `dev/gfdl`, `dev/ncar`).
- Never rebase a branch that has been pushed.
- PRs go to the fork's default branch; merges to `main` are by consortium consensus.

## Commit messages

```
*+Short imperative summary (50 chars if possible)

Explanation wrapped at 72 characters: what changed and why.
Reference issues with #NNN.
All answers are bitwise identical.
```

Title prefixes:

- `*`: changes numerical answers
- `+`: adds a public interface or runtime parameter
- `*+` / `+*`: both
- none: bitwise-identical refactoring, cleanup, or comments

Always state the answer impact in the body.

## Structuring changes

- In multi-commit PRs, add infrastructure in one commit and use it in the next.
- Keep public scope minimal; drop symbols from `public` once they are internal-only.
- Label closing `enddo`/`endif` of non-trivial nests, e.g. `enddo ! n-loop for segments`.

## PR descriptions

1. Lead with what changed and why.
2. Quantify scope ("across 26 files", "in 7 places").
3. For answer-changing PRs, give the scientific justification and name the `_BUG` or
   `ANSWER_DATE` parameter that preserves the old answers.
4. State the bitwise-identical guarantee, or what changes and why.
