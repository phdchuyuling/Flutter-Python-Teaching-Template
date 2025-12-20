#!/bin/bash

# Flutter Reversi Server - 穩定版本
# 自動重啟和監控

PROJECT_DIR="/workspaces/Flutter-Python-Teaching-Template/build/web"
LOG_FILE="/tmp/flutter_server.log"
PID_FILE="/tmp/flutter_server.pid"

# 清理舊進程
cleanup() {
    echo "清理舊進程..."
    pkill -f "http.server" 2>/dev/null
    rm -f $PID_FILE
}

# 啟動服務器
start_server() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 啟動 HTTP 服務器..."
    cd $PROJECT_DIR
    python3 -m http.server 8080 >> $LOG_FILE 2>&1 &
    echo $! > $PID_FILE
    sleep 2
    
    if ps -p $(cat $PID_FILE) > /dev/null 2>&1; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ✓ 服務器啟動成功 (PID: $(cat $PID_FILE))"
        return 0
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ✗ 服務器啟動失敗"
        return 1
    fi
}

# 健康檢查
health_check() {
    if ps -p $(cat $PID_FILE 2>/dev/null) > /dev/null 2>&1; then
        if curl -s -o /dev/null -w "%{http_code}" http://10.0.3.48:8080/ | grep -q "200"; then
            return 0
        fi
    fi
    return 1
}

# 主程序
trap cleanup EXIT

cleanup
if start_server; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 服務器運行中..."
    echo "訪問地址: http://10.0.3.48:8080"
    
    # 監控循環
    while true; do
        sleep 10
        if ! health_check; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 警告: 服務器無回應，重新啟動..."
            cleanup
            start_server
        fi
    done
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 無法啟動服務器"
    exit 1
fi
