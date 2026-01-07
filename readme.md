# Reverse SSH Proxy (Geautomatiseerd)
**Stapsgewijze installatieprocedure**

**Doel:** de Raspberry Pi kan worden ingericht als veilige remote access gateway, zodat beheerders locatie-onafhankelijk toegang verkrijgen tot de lokale virtuele machines en netwerkapparatuur met minimale kosten via Azure.  
**Versie:** 2 (Geautomatiseerd)  
**Maand en jaar van uitgave:** 01/2026

---

## Inhoudsopgave
* [Vereisten](#vereisten)
* [Stap 1 – Azure Infrastructuur Uitrollen (Azure CLI)](#stap-1--azure-infrastructuur-uitrollen-azure-cli)
* [Stap 2 – Azure VM Configureren](#stap-2--azure-vm-configureren)
* [Stap 3 – Raspberry Pi Configureren](#stap-3--raspberry-pi-configureren)
* [Stap 4 – Verbinden met de Raspberry Pi via de Azure VM](#stap-4--verbinden-met-de-raspberry-pi-via-de-azure-vm)
* [Stap 5 – Installatie Ongedaan Maken (Revert)](#stap-5--installatie-ongedaan-maken-revert)

---

## Vereisten
* Raspberry Pi met Linux (bijv. Raspberry Pi OS).
* Azure Dashboard / Cloud Shell toegang.
* Laptop of pc met SSH-client (bijvoorbeeld PuTTY of Windows Terminal).
* De map met scripts (`EPI`) beschikbaar op uw computer.
* Werkende internetverbinding op de te gebruiken machines.

Voor deze tutorial gebruiken we de geautomatiseerde scripts die te vinden zijn in de bijgeleverde map.

---

## Stap 1 – Azure Infrastructuur Uitrollen (Azure CLI)
In plaats van handmatig door het Azure Portal te klikken, gebruiken we een script om de Resource Group en de virtuele machine (Jump Host) aan te maken.

1. Ga naar [portal.azure.com](https://portal.azure.com) en open de **Cloud Shell** (icoon bovenaan, naast de zoekbalk). Zorg dat deze op **Bash** staat.
2. Open het bestand `AzureVM_verbose.AZ` uit de scriptmap op uw lokale computer.
3. Pas indien nodig de variabelen aan (zoals `ADMIN_PASS` en `LOCATION`).
4. Kopieer de gehele inhoud van het bestand.
5. Plak de inhoud in de Azure Cloud Shell en druk op Enter.

Het script zal nu automatisch:
* De Resource Group aanmaken.
* De VM ("JumpHostVM") aanmaken met de juiste specificaties (Standard_B1s, Ubuntu Minimal).
* SSH toegang en de tunnel-poort (2222) openzetten in de firewall.

*Noteer na afloop het **Public IP** dat door het script wordt getoond.*

---

## Stap 2 – Azure VM Configureren
Nu de VM bestaat, moeten we de SSH-daemon configureren om tunnels toe te staan.

1. Verbind met de nieuwe VM via SSH (gebruik het IP uit stap 1):
   `ssh azureuser@<AZURE_PUBLIC_IP>`
2. Upload of maak het script `setup_azure_vm_verbose.sh` op de VM. 
   *(U kunt de inhoud kopiëren, `nano setup_azure_vm_verbose.sh` typen, plakken, en opslaan met Ctrl+X, Y, Enter).*
3. Maak het script uitvoerbaar:
   `chmod +x setup_azure_vm_verbose.sh`
4. Voer het script uit met sudo rechten:
   `sudo ./setup_azure_vm_verbose.sh`

Het script zal automatisch:
* Systeemupdates uitvoeren.
* Instellingen in `/etc/ssh/sshd_config` aanpassen (o.a. `GatewayPorts yes`, `AllowTcpForwarding yes`).
* De SSH-service herstarten.

---

## Stap 3 – Raspberry Pi Configureren
Op de Raspberry Pi gebruiken we één script om het systeem te updaten, software te installeren en de persistente tunnel op te zetten.

1. Open de terminal op uw Raspberry Pi.
2. Zorg dat het bestand `setup_pi_verbose.sh` op de Pi staat. 
3. Maak het script uitvoerbaar:
   `chmod +x setup_pi_verbose.sh`
4. Voer het script uit:
   `sudo ./setup_pi_verbose.sh`

Het script zal u vragen om:
* **Azure VM Username**: (meestal `azureuser`)
* **Azure VM Public IP**: (uit Stap 1)
* **Wachtwoord**: (het wachtwoord dat u in `AzureVM_verbose.AZ` hebt ingesteld)
* **Remote Port**: (standaard `2222`)

Het script regelt vervolgens:
* Updates (apt update/upgrade).
* Installatie van `openssh-server` en `sshpass`.
* Aanmaken van het connectie-script in `/var/tmp/`.
* Installeren en starten van de `reverse-tunnel` systemd service.

Controleer de status aan het einde van het script; er moet `active (running)` staan.

---

## Stap 4 – Verbinden met de Raspberry Pi via de Azure VM
De verbinding wordt nu opgebouwd. U kunt verbinden via de 'Jump Host'.

1. Open uw SSH-client (bijv. PuTTY).
2. **Host Name**: Het publieke IP van de Azure VM.
3. **Port**: 2222 (of de poort die u koos).
4. Start de verbinding.
5. U verbindt nu door de tunnel naar de Raspberry Pi. Login met de **gebruikersnaam en het wachtwoord van de Raspberry Pi** zelf.

---

## Stap 5 – Installatie Ongedaan Maken (Revert)
Indien u de configuratie wilt verwijderen, zijn er opschoon-scripts beschikbaar in de map `revert`.

### Raspberry Pi opschonen
1. Kopieer `cleanup_pi.sh` naar de Raspberry Pi.
2. Voer uit: `sudo ./cleanup_pi.sh`
   * Dit stopt de tunnel, verwijdert de service, en deinstalleert de software.

### Azure VM opschonen (Configuratie)
1. Kopieer `cleanup_azure_vm.sh` naar de Azure VM.
2. Voer uit: `sudo ./cleanup_azure_vm.sh`
   * Dit herstelt de originele SSH-configuratie (indien de back-up nog bestaat).

### Azure Omgeving Verwijderen (Alles wissen)
**WAARSCHUWING:** Dit verwijdert de gehele Resource Group en de VM.
1. Open Azure Cloud Shell.
2. Gebruik de commando's uit `cleanup_azure.AZ`.
   * Dit voert een `az group delete` uit voor de Resource Group `EPI-ResourceGroup`.
