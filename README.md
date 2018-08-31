## One click installation script:

Installation script is build for Linux Ubuntu 16.04 (systemd required).

This script has been tested for the following VPS providers but may be compatible with others:

| Provider | Result |
| :---: | :---: |
| OVH  | OK |
| Scaleway  | OK |
| DigitalOcean | OK |
| Vultr  | OK |

Certain VPS providers configure Linux operating system in their own way which can cause errors in this script. Please report if you encounter errors on the above providers, or if you are successful with others.

To start the one click masternode setup, please connect to your VPS and run the below:

```bash
wget https://raw.githubusercontent.com/Bitglo/masternode_setup/master/install.sh && sudo chmod +x install.sh && sudo ./install.sh
```

Follow and complete the on-screen instructions.


---

## Once click update (wallet and masternode) script:

To start the one click update process, please connect to your VPS and run the below:

```bash
wget https://raw.githubusercontent.com/Bitglo/masternode_setup/master/update.sh && sudo chmod +x update.sh && sudo ./update.sh
```

Follow and complete the on-screen instructions.

