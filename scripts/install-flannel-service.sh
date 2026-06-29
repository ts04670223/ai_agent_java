#!/bin/bash
# 安裝 flannel-subnet-env systemd oneshot service
# 用途：VM 重啟時自動在 /run/flannel/ 建立 subnet.env

cat > /usr/local/bin/create-flannel-subnet-env.sh << 'EOF'
#!/bin/bash
mkdir -p /run/flannel
cat > /run/flannel/subnet.env << SUBNET
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
SUBNET
EOF
chmod +x /usr/local/bin/create-flannel-subnet-env.sh

cat > /etc/systemd/system/flannel-subnet-env.service << 'EOF'
[Unit]
Description=Create Flannel subnet.env in /run (tmpfs)
Before=kubelet.service
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/create-flannel-subnet-env.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flannel-subnet-env.service
systemctl start flannel-subnet-env.service

echo "flannel-subnet-env.service 已安裝並啟用"
systemctl status flannel-subnet-env.service --no-pager
