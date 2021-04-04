#!/usr/bin/env bash
# This userdata script will do the valheim initial install as well as set up the valheim systemd service
# When the service is restarted or the server shuts down the world files will be backed up to S3
# When the service starts the world files are restored from S3
# You must have world files in s3://<your bucket>/latest for the start script to succeed

# ===============
# initial install
# ===============
systemctl stop firewalld
useradd -m steam
cd /home/steam
yum update
yum install -y glibc.i686 libstdc++.i686
mkdir /home/steam/Steam && cd /home/steam/Steam
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
/home/steam/Steam/steamcmd.sh +login anonymous +force_install_dir /home/steam/Valheim +app_update 896660 +quit


# ===============
#  start script
# ===============
cat <<'EOF' > /home/steam/Valheim/start_valheim.sh
#!/bin/bash
export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970

# Tip: Make a local copy of this script to avoid it being overwritten by steam.
# NOTE: Minimum password length is 5 characters & Password cant be in the server name.
# NOTE: You need to make sure the ports 2456-2458 is being forwarded to your server through your local router & firewall.
/home/steam/Steam/steamcmd.sh +login anonymous +force_install_dir /home/steam/Valheim +app_update 896660 +quit

# restore data
aws s3 cp --recursive s3://${S3_BUCKET_NAME}/latest /home/steam/.config/unity3d/IronGate/Valheim/worlds

./valheim_server.x86_64 -name "${SERVER_NAME}" -port 2456 -world "${WORLD_NAME}" -password "${SERVER_PASSWORD}" -public 1 > /dev/null &

export LD_LIBRARY_PATH=$templdpath

echo "Server started"
echo ""

while :
do
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "valheim.service: timestamp $TIMESTAMP"
sleep 60
done
EOF


# ===============
#  stop script
# ===============
cat <<'EOF' > /home/steam/Valheim/stop_valheim.sh
#!/bin/bash
# backup data
aws s3 cp --recursive /home/steam/.config/unity3d/IronGate/Valheim/worlds s3://${S3_BUCKET_NAME}/latest
aws s3 cp --recursive /home/steam/.config/unity3d/IronGate/Valheim/worlds s3://${S3_BUCKET_NAME}/$(date -Iseconds)
EOF


# ==================
# script permissions
# ==================
chown -R steam:steam /home/steam
chmod +x /home/steam/Valheim/start_valheim.sh
chmod +x /home/steam/Valheim/stop_valheim.sh


# ===============
# systemd service
# ===============
cat <<EOF > /etc/systemd/system/valheim.service
[Unit]
Description=Valheim service
Wants=network.target
After=syslog.target network-online.target
[Service]
Type=simple
Restart=on-failure
RestartSec=10
User=steam
WorkingDirectory=/home/steam/Valheim
ExecStart=/home/steam/Valheim/start_valheim.sh
ExecStop=/home/steam/Valheim/stop_valheim.sh
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable valheim
sudo systemctl start valheim
sudo systemctl status valheim
