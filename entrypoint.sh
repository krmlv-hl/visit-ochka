#!/bin/bash


if [[ -z "${vrsn}" ]]; then
  vrsn="latest"
fi
echo ${vrsn}

if [[ -z "${vlph}" ]]; then
  vlph="/s233"
fi
echo ${vlph}

if [[ -z "${vluid}" ]]; then
  vluid="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
echo ${vluid}

if [[ -z "${vmph}" ]]; then
  vmph="/s244"
fi
echo ${vmph}

if [[ -z "${vmuid}" ]]; then
  vmuid="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
echo ${vmuid}

if [[ -z "${shph}" ]]; then
  shph="/share233"
fi
echo ${shph}

if [ "$vrsn" = "latest" ]; then
  vrsn=`wget -qO- "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | sed -n -r -e 's/.*"tag_name".+?"([vV0-9\.]+?)".*/\1/p'`
  [[ -z "${vrsn}" ]] && vrsn="v1.2.2"
else
  vrsn="v$vrsn"
fi

mkdir /v2bin
cd /v2bin
RAY_URL="https://github.com/XTLS/Xray-core/releases/download/${vrsn}/Xray-linux-64.zip"
echo ${RAY_URL}
wget --no-check-certificate ${RAY_URL}
unzip Xray-linux-64.zip
rm -f Xray-linux-64.zip
chmod +x ./xray
ls -al

cd /wwwroot
tar xvf wwwroot.tar.gz
rm -rf wwwroot.tar.gz


sed -e "/^#/d"\
    -e "s/\${vluid}/${vluid}/g"\
    -e "s|\${vlph}|${vlph}|g"\
    -e "s/\${vmuid}/${vmuid}/g"\
    -e "s|\${vmph}|${vmph}|g"\
    /conf/v2.template.json >  /v2bin/config.json
echo /v2bin/config.json
cat /v2bin/config.json

if [[ -z "${ProxySite}" ]]; then
  s="s/proxy_pass/#proxy_pass/g"
  echo "site:use local wwwroot html"
else
  s="s|\${ProxySite}|${ProxySite}|g"
  echo "site: ${ProxySite}"
fi

sed -e "/^#/d"\
    -e "s/\${PORT}/${PORT}/g"\
    -e "s|\${vlph}|${vlph}|g"\
    -e "s|\${vmph}|${vmph}|g"\
    -e "s|\${shph}|${shph}|g"\
    -e "$s"\
    /conf/nginx.template.conf > /etc/nginx/conf.d/ray.conf
echo /etc/nginx/conf.d/ray.conf
cat /etc/nginx/conf.d/ray.conf

[ ! -d /wwwroot/${shph} ] && mkdir -p /wwwroot/${shph}
sed -e "/^#/d"\
    -e "s|\${_vlph}|${vlph}|g"\
    -e "s|\${_vmph}|${vmph}|g"\
    -e "s/\${_vluid}/${vluid}/g"\
    -e "s/\${_vmuid}/${vmuid}/g"\
    -e "$s"\
    /conf/share.html > /wwwroot/${shph}/index.html
echo /wwwroot/${shph}/index.html
cat /wwwroot/${shph}/index.html

cd /v2bin
./xray run -c ./config.json &
rm -rf /etc/nginx/sites-enabled/default
nginx -g 'daemon off;'
