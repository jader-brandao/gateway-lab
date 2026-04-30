Comando para instalação.
Execute no Terminal da sua VPS:

bash -c "$(curl -fsSL https://raw.githubusercontent.com/gatewaylab-hub/gateway/main/install.sh)"

bash -c "$(curl -fsSL https://raw.githubusercontent.com/jader-brandao/gateway-lab/main/install.sh)"

Importante: você precisa fazer upload dos arquivos para um novo repositorio no GitHub.
(Quando for fazer a instalação ou atualização, deixe o repositório público temporariamente)

-------------

Comando para Atualização:

bash -c "$(curl -fsSL https://raw.githubusercontent.com/gatewaylab-hub/gateway/main/update.sh)"

bash -c "$(curl -fsSL https://raw.githubusercontent.com/jader-brandao/gateway-lab/main/update.sh)"

Qualquer modificação que você fizer no código, após finalizado, basta subir o repositorio para o github novamente, usando o GitHub Desktop ou pelo comando no terminal 
git add .
git commit -m update
git push

