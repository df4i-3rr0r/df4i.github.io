#binbash

rm -rf /usr/local/etc/xray/xray.crt

rm -rf /usr/local/etc/xray/xray.key

cd /usr/local/etc/xray/

wget https://github.com/df4i-3rr0r/df4i.github.io/blob/main/vpstool-script/multi-tool/xray.crt

chmod 755 /usr/local/etc/xray/xray.crt

wget https://github.com/df4i-3rr0r/df4i.github.io/blob/main/vpstool-script/multi-tool/xray.key

chmod 755 /usr/local/etc/xray/xray.key

cd

rm -rf /root/*

reboot
