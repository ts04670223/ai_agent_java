#!/bin/bash
# Prometheus 安裝和管理腳本

ACTION=${1:-status}

case "$ACTION" in
    install)
        echo "🚀 安裝 Prometheus..."
        kubectl apply -f /vagrant/prometheus/namespace.yaml
        kubectl apply -f /vagrant/prometheus/prometheus-rbac.yaml
        kubectl apply -f /vagrant/prometheus/prometheus-config.yaml
        kubectl apply -f /vagrant/prometheus/prometheus-deployment.yaml
        
        echo "⏳ 等待 Prometheus 啟動..."
        kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=120s
        
        echo "✅ Prometheus 安裝完成!"
        echo "📊 訪問地址: http://localhost:30090"
        ;;
        
    uninstall)
        echo "🗑️  卸載 Prometheus..."
        kubectl delete -f /vagrant/prometheus/prometheus-deployment.yaml
        kubectl delete -f /vagrant/prometheus/prometheus-config.yaml
        kubectl delete -f /vagrant/prometheus/prometheus-rbac.yaml
        kubectl delete -f /vagrant/prometheus/namespace.yaml
        echo "✅ Prometheus 已卸載"
        ;;
        
    restart)
        echo "🔄 重啟 Prometheus..."
        kubectl rollout restart deployment/prometheus -n monitoring
        kubectl rollout status deployment/prometheus -n monitoring
        echo "✅ Prometheus 已重啟"
        ;;
        
    status)
        echo "📊 Prometheus 狀態:"
        echo ""
        kubectl get pods -n monitoring -l app=prometheus
        echo ""
        kubectl get svc -n monitoring
        echo ""
        echo "🔗 訪問地址: http://localhost:30090"
        echo "🎯 Targets: http://localhost:30090/targets"
        echo "📈 Graph: http://localhost:30090/graph"
        ;;
        
    logs)
        kubectl logs -n monitoring -l app=prometheus --tail=100 -f
        ;;
        
    targets)
        echo "🎯 Prometheus 監控目標:"
        curl -s http://localhost:30090/api/v1/targets | \
            grep -o '"job":"[^"]*"' | \
            sort | uniq | \
            sed 's/"job":"/- /' | \
            sed 's/"$//'
        ;;
        
    reload)
        echo "🔄 重新加載配置..."
        kubectl apply -f /vagrant/prometheus/prometheus-config.yaml
        POD=$(kubectl get pod -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}')
        kubectl exec -n monitoring $POD -- wget --post-data="" -O- http://localhost:9090/-/reload
        echo "✅ 配置已重新加載"
        ;;
        
    *)
        echo "用法: $0 {install|uninstall|restart|status|logs|targets|reload}"
        echo ""
        echo "命令:"
        echo "  install    - 安裝 Prometheus"
        echo "  uninstall  - 卸載 Prometheus"
        echo "  restart    - 重啟 Prometheus"
        echo "  status     - 查看狀態"
        echo "  logs       - 查看日誌"
        echo "  targets    - 查看監控目標"
        echo "  reload     - 重新加載配置"
        exit 1
        ;;
esac
