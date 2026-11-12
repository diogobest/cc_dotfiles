#!/usr/bin/env bash
# Hook WorktreeCreate do Claude Code (substitui a criação padrão: o hook cria a worktree e
# imprime o caminho no stdout; qualquer outra saída vai para stderr).
# Em repositório com .git/hooks/worktree-db (SSCROP): cria em .worktree/<nome>, e o post-checkout
# do git cria o banco. Nos demais: comportamento equivalente ao padrão (.claude/worktrees/<nome>).
set -euo pipefail

input=$(cat)
name=$(jq -r '.name' <<<"$input")
cwd=$(jq -r '.cwd' <<<"$input")

common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir)
main=$(dirname "$common")

if [ -x "$common/hooks/worktree-db" ]; then
  dir="$main/.worktree/$name"
else
  dir="$main/.claude/worktrees/$name"
fi
branch="worktree-$name"

# baseRef "fresh": parte do origin/<branch padrão>; sem remoto, do HEAD local
default=$(git -C "$main" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
if [ -n "$default" ]; then
  git -C "$main" fetch --quiet origin "${default#origin/}" >&2 || true
  base="$default"
else
  base=HEAD
fi

mkdir -p "$(dirname "$dir")"
# --no-track: senão a branch herda upstream origin/master e um `git push` vai para a master
if git -C "$main" show-ref --verify --quiet "refs/heads/$branch"; then
  git -C "$main" worktree add "$dir" "$branch" >&2
else
  git -C "$main" worktree add --no-track -b "$branch" "$dir" "$base" >&2
fi

echo "$dir"
