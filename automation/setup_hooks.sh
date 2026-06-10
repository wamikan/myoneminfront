#!/bin/bash

# Gitリポジトリのルートディレクトリを取得
REPO_ROOT=$(git rev-parse --show-toplevel)

# 各種ディレクトリパス
HOOK_DIR="$REPO_ROOT/.git/hooks"
CUSTOM_HOOK_DIR="$REPO_ROOT/automation/hooks"

mkdir -p "$HOOK_DIR"

for hook in "$CUSTOM_HOOK_DIR"/*; do
    hook_name=$(basename "$hook")
    target_path="$HOOK_DIR/$hook_name"
    backup_path="$HOOK_DIR/${hook_name}_bkup"

    # 既存のファイルまたはリンクがある場合にバックアップ
    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
        echo "Backing up existing hook: $target_path -> $backup_path"
        mv "$target_path" "$backup_path"
    elif [ -L "$target_path" ]; then
        # シンボリックリンクの場合もバックアップ
        echo "Backing up existing symlink: $target_path -> $backup_path"
        mv "$target_path" "$backup_path"
    fi

    # シンボリックリンクを作成
    ln -sf "$hook" "$target_path"
    chmod +x "$hook"
done

echo "Hooks installed from $CUSTOM_HOOK_DIR to $HOOK_DIR (with backup if needed)."
