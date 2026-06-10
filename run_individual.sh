#! /bin/bash

# デバッグモードのフラグ
DEBUG_MODE=false

# コマンドライン引数を解析
while getopts "d" opt; do
    case $opt in
        d)
            DEBUG_MODE=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

declare -A user_to_port=(
        ["mj"]="9013"
        ["potato"]="9014"
        ["nago"]="9015"
        ["yoshi"]="9016"
        ["giraffe"]="9017"
)

# 現在のユーザー名を取得
CURRENT_USER=$(whoami)

# デバッグモードの場合は9012番ポートを使用
if [[ "$DEBUG_MODE" == true ]]; then
    PORT="9012"
    echo "Debug mode: Starting server on port $PORT"
    fvm flutter run -d web-server --web-port $PORT
else
    # ユーザーに対応するポート番号を取得
    if [[ -n "${user_to_port[$CURRENT_USER]}" ]]; then
        PORT="${user_to_port[$CURRENT_USER]}"
        echo "Starting server for user $CURRENT_USER on port $PORT"
        fvm flutter run -d web-server --web-port $PORT
    else
        echo "User $CURRENT_USER not found in user_to_port mapping"
        echo "Available users: ${!user_to_port[@]}"
    fi
fi
