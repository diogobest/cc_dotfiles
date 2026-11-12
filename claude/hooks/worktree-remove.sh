#!/usr/bin/env bash
# Hook WorktreeRemove do Claude Code (substitui a remoção padrão: o hook precisa apagar o diretório).
# Em repositório com .git/hooks/worktree-db (SSCROP) derruba antes os bancos da worktree.
set -uo pipefail

path=$(jq -r '.worktree_path')
[ -d "$path" ] || exit 0

common=$(git -C "$path" rev-parse --path-format=absolute --git-common-dir) || exit 1
main=$(dirname "$common")
branch=$(git -C "$path" branch --show-current 2>/dev/null || true)

if [ -x "$common/hooks/worktree-db" ]; then
  "$common/hooks/worktree-db" remove "$path" --force || exit 1
else
  git -C "$main" worktree remove --force "$path" >&2 || exit 1
fi

# O Claude Code não apaga a branch de worktree criada por hook: apaga só a nossa (worktree-*)
# e só se já estiver mergeada (-d recusa caso contrário, preservando trabalho não integrado)
case "$branch" in
  worktree-*) git -C "$main" branch -d "$branch" >&2 2>/dev/null || true ;;
esac
exit 0
