mkdir -p ~/codes
cd ~/codes
sudo bash -c "apt update
ssh-keyscan github.com >> ~/.ssh/known_hosts
git clone git@github.com:Eggwardhan/bash_tools.git 
bash bash_tools/get_frp.sh
cd bash_tools/
bash install_vibecode"
