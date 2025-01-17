#!/usr/bin/env bash
set -x
apt update
apt upgrade -y
groupadd -f locust
useradd -m locust -g locust || echo "user already exists"
apt install -y htop emacs-nox wget iftop iotop python3-pip
pip install locust
echo '* - nofile 1000000' >> /etc/security/limits.conf
echo '* - nproc 1000000' >> /etc/security/limits.conf

# Download tasks
wget -O /home/locust/tasks.py ${TASKS_URL}
chown -R locust:locust /home/locust

cat <<EOF > /lib/systemd/system/locust-master.service
[Unit]
Description=Locust Service
Wants=network-online.target
Requires=network-online.target
After=network-online.target

[Service]
User=locust
Group=locust
Restart=always
ExecStart=/usr/local/bin/locust -f tasks.py --master --web-auth ${LOCUST_USERNAME}:${LOCUST_PASSWORD}
WorkingDirectory=/home/locust
KillSignal=SIGKILL
SyslogIdentifier=locust
LimitNOFILE=1000000
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable locust-master
systemctl restart locust-master
