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

CPUS=$(nproc --all)
for (( c=1; c<=$CPUS; c++ ))
do
    cat <<EOF > /lib/systemd/system/locust-worker-$c.service
[Unit]
Description=Locust Service
Wants=network-online.target
Requires=network-online.target
After=network-online.target

[Service]
User=locust
Group=locust
Restart=always
ExecStart=/usr/local/bin/locust -f tasks.py --worker --master-host=${LOCUST_MASTER_IP}
WorkingDirectory=/home/locust
KillSignal=SIGKILL
SyslogIdentifier=locust-worker-$c
LimitNOFILE=1000000
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable locust-worker-$c
    systemctl restart locust-worker-$c
done
