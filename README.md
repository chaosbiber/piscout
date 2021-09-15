# pi-gen tree for 'piscout' - Nightscout Image for Raspberry Pi 3 + 4

Fork of [pi-gen](https://github.com/RPi-Distro/pi-gen/tree/arm64) used to create Raspberry Pi OS images. (Previously known as Raspbian).

## English docs in the future, testing currently focused on German community

## Disclaimer

Auslöser für mich, die Arbeit an einer einfachen Lösung Nightscout auf einem Raspberry Pi betreiben zu können fortzusetzen, waren neben Interesse und spontaner Zeit zwar die notwendige Kommerzialisierung um [ns.10be.de](https://ns.10be.de/de/index.html). Doch möchte ich klarstellen, dass selbst ohne Beta-Status dieses Projekt niemals die Funktionalitäten von Martins Dienst ersetzen könnten. Das Projekt kann eher eine Alternative für Heroku/MongoDB Atlas werden, und sich an Leute richten, die mit etwas Bastel- oder Wartungsaufwand leben können und eventuell einen Raspberry Pi 3 oder 4 übrig haben. Vorteil ist die Datenhoheit, Nachteil u.A. die höhere Gefahr seine Daten wegen technischen Defekten oder Fehlern dauerhaft zu verlieren.

Also: die einfachste Lösung wird auf lange Zeit [ns.10be.de](https://ns.10be.de/de/index.html) bleiben!

## Aktueller Stand

Frühe **Beta**, diese erstellt (soweit getestet) verlässlich ein lauffähiges Image mit vorinstalliertem und automatisch startenden Nightscout, allerdings gibt es noch keine Wartungs-Funktionen (Plugins (de-)aktivieren, Im- und Export, Backup) per Browser und **von produktiver Nutzung wird entsprechend abgeraten!**

Für Leute die sich mit Raspberry Pis auskennen ist das Image (Link für fertigen Build unter Quickstart) schon jetzt ein schneller und bequemer Weg Nightscout zu installieren, ein Ersatz für andere Dienste mit bequemen Webinterfaces oder ausführlichen Anleitungen ist dies so nicht.

Ein Update-Pfad ist derzeit auch noch nicht in Planung, neue Images überschreiben alte Daten solange es kein Backup gibt. Manuell per SSH-Zugriff oder angeschlossener Tastatur kann natürlich `mongodump` und `mongorestore` verwendet und die Umgebungsvariablen in `/home/pi/.piscout/nightscout.env` angepasst werden, um Plugins und andere nightscout-Einstellungen festzulegen. Anschließenden Neustart per `sudo systemctl restart nightscout.service`. Wem das nichts sagt: Finger weg!

## Quickstart

### Beenötigte Hardware

- Raspberry Pi 3 oder 4 mit mind. 1GB RAM
- Strom (offizielles Netzteil empfohlen)
- Netzwerkkabel zwischen Pi und Switch/Router ("Fritzbox") - WLAN-Einrichtung derzeit nur manuell
- microSD-Karte mit mindestens 8GB

### Aktuelles Image 

- entweder selber builden oder aktuelle Version unter https://notwait.in/files/image_2021-09-15-piscout-0.1.zip laden
- auf SD-Karte spielen, z.B. mit [balenaEtcher](https://www.balena.io/etcher/)
- oder [Raspberry Pi Imager](https://www.raspberrypi.org/software/) ('Use Custom')
- Karte einlegen, starten und nach erfolgreichem Boot plus etwa 30 Sekunden IP-Adresse des Pis (*piscout* statt *raspberrypi*) identifizieren (per `ping piscout`, DHCP-Leases im Router oder Netzwerkscan)
- http(s)://[ip]/piscout aufrufen um den API Schlüssel zu kopieren
- auf http(s)://[ip]/ läuft Nightscout

## TODO / Hilfe gesucht

Den Grundbau des Images konnte ich aus zeitlichen Gründen gut selber fertig stellen, für die nächsten Schritte würde ich mich aber über Input oder Hilfe freuen.

1. Webbasiertes Interface um nightscout-Einstellungen vornehmen zu können

Z.B. Plugins ein- und ausschalten, anschließend Neustart auslösen. In `.piscout/nightscout.env` (siehe `stage4/files`) werden entsprechende Wertepaare vorgehalten und exportiert, die Datei ließe sich ganz gut direkt anpassen. Bin für sprachagnostische Lösungen offen, das begonnene 10-Zeilen tool piscout-configurator ließt bisher lediglich den API key aus der Datei `.piscout/apisecret.env`. Neustart per Aufruf von `sudo systemctl restart nightscout.service` oder Wrapper-Skripten.

2. Im- und Export via Webinterface.

Als wichtigstes Import-Tool sollte direkt eine bestehende Nightscout-Installation angegeben werden können, als nächstes per komprimierten Ordnern von/für mongodump/mongorestore. Weitere je nachdem was die anderen Tools (MongoDB Atlas) für Formate bieten.

3. Automatischer Export/Backup auf USB-Stick und/oder remote-Speicher im Intranet oder Internet.

Ein eingeteckter USB-Stick könnte im Webinterface initialisiert werden, d.h. ggf. formatiert und ein Ordner angelegt. Findet ein cronjob externe Datenträger mit dem Ordner, führt er dumps durch. Uhrzeit/Frequenz einstellbar. Als Erweiterung könnten auch die Einstellungen mitgespeichert werden und das Init-Skript, falls die eigene Datenbank wegen frischer Image-Installation leer ist, den Dump vom USB-Stick mit Einstellungen wiederherstellen.

Für remote Backups kommen z.B. ssh/scp, samba, nfs oder Cloud-Speicher infrage. Die Datenbank kann jedoch, selbst gepackt, mehrere Dutzend oder Hunderte MB groß werden.

4. Automatisierte Builds oder Updates

Wenn es häufige Updates an der Konfigurationssoftware gibt machen automatische Builds Sinn, oder automatische Updates auf dem Pi selbst. Nightscout Updates würde ich wegen Auslastung und Speicherengpässen lieber nicht pauschal über das Webinterface erlauben. Dann lieber über neue Images, d.h. aber automatisierte Backups und Wiederherstellung müssen funktionieren.

## Dienste

- **http://[ip]:3000** - Nightscout
- **http://[ip]:8080/piscout** piscout-configurator - WIP-Tool in golang das derzeit nur den aktuellen API Schlüssel anzeigt
- **http://[ip] / https://[ip]** (80) - nginx als reverse proxy für Nightscout
- **http://[ip]/piscout / https://[ip]/piscout** (80) - nginx als reverse proxy für den piscout-configurator

## Zertifikate

self-signed Zertifikate werden beim ersten Start generiert und bei Bedarf (geänderte IP, Ablaufdatum) bei nachfolgenden Starts erneuert.

## Sonstiges Technisches

- ssh beim aktuellen Image enabled, wenn nicht auf der SD-Karte auf der Boot-Partition Datei 'ssh' erzeugen
- Standardnutzer und -Passwort wie bei originalen Images: `pi` / `raspberry`
- hostname ist `piscout`
- 64 bit System mit Debian buster (Beta), weil es für 32 bit kein MongoBD gibt, bei bullseye ist weder Rasperry Pi OS, noch MongoDB so weit
- nutzt MongoDB-repo für Ubuntu arm64, weil im Debian-repo für arm64 nur `mongo-mongosh` enthalten ist. Anpassen musste ich das systemd service file
- kein Ubuntu-basierter Build, weil ich dort keine Anleitung für ein custom build und schon gar nicht so ein tolles pi-gen Skript finden konnte

## Vorteile gegenüber [nightscout-installer](https://github.com/chaosbiber/nightscout-installer)

- Durchführbahrkeit: das `npm install` ist mit neueren nightscout-Versionen sehr zeitaufwändig direkt auf dem Pi auszuführen, mit 1GB RAM teilweise auch gar nicht mehr möglich
- Zeit: das Installationsskript lief sehr lange, musste auf automatische Updates Warten und war fehleranfällig. Das Image baut auch recht lange (30min+), ist aber nur ein mal nötig. Das fertige Image bietet einen verlässlicheren und schnell installierten Ausgangspunkt

## Build

Ich habe es auf MacOS und deshalb mithilfe des Docker-Skripts gebaut. Außerdem scheint es ein 64bit-Bug zu geben, der auch unter Linux docker empfehlenswert macht.

Mein Vorgehen:
- `docker-compose up -d` um apt-cacher zu starten
- `echo 'APT_PROXY=http://172.17.0.1:3142' >> config`
- `PRESERVE_CONTAINER=1 ./build-docker.sh`

Für Anpassungen:
- `touch stage0/SKIP stage1/SKIP stage2/SKIP stage3/SKIP` (z.B. um diese Stages nicht erneut zu builden)
- stage4 anpassen oder weitere hinzufügen
- `echo 'CLEAN=1' >> config`
- `PRESERVE_CONTAINER=1 CONTINUE=1 ./build-docker.sh` um nur stage4 von vorne zu builden

Ansonsten siehe Doku auf https://github.com/RPi-Distro/pi-gen/tree/arm64

Die stages 0-2 entsprechen dem originalen lite-image, die stages 3-5 die normalerweise für den Desktop verantwortlich sind habe ich gelöscht und durch eigene ersetzt.
