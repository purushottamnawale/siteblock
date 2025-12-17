sudo nano /usr/local/bin/siteblock
sudo chmod +x /usr/local/bin/siteblock
nano ~/.bashrc
alias blocksites="sudo siteblock block"
alias unblocksites="sudo siteblock unblock"
alias sitestatus="siteblock status"
source ~/.bashrc
sitestatus