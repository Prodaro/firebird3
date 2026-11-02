# Firebird 3.0.14 für NAS-Systeme

Docker-Image mit Firebird 3.0.14 für QNAP (Container Station) und
Synology (Container Manager), verfügbar für **amd64 und arm64**.

Hintergrund: Für arm64-Linux existieren keine offiziellen Firebird-3-
Binärpakete (die arm64-Tarballs der Firebird-Releases sind Android-Builds).
Dieses Image kompiliert Firebird daher aus den unveränderten offiziellen
Quellen des [Firebird-Projekts](https://github.com/FirebirdSQL/firebird).

## Verwendung

```sh
docker run -d \
  --name firebird \
  --restart unless-stopped \
  -p 3050:3050 \
  -e FIREBIRD_ROOT_PASSWORD=IhrPasswort \
  -e TZ=Europe/Berlin \
  -v /pfad/zum/datenordner:/var/lib/firebird/data \
  ghcr.io/prodaro/firebird3:3.0.14
```

| Umgebungsvariable | Wirkung |
|---|---|
| `FIREBIRD_ROOT_PASSWORD` | setzt das SYSDBA-Passwort bei jedem Start |
| `FIREBIRD_DATABASE` | legt eine leere Datenbank dieses Namens im Datenordner an, falls nicht vorhanden |

Datenbanken liegen im eingebundenen Datenordner **außerhalb** des
Containers und überleben Update und Neuanlage des Containers.
Verbindung: `<NAS-IP>/3050:/var/lib/firebird/data/<Datenbank>`

## Hinweise

- `WireCrypt = Enabled` (verhandelbar): kompatibel auch mit Clients,
  die ohne Leitungsverschlüsselung arbeiten
- Authentifizierung: Srp
- Locale `C.UTF-8` statt der Standard-C-Locale, damit Clients mit
  Umlauten im Rechner- oder Benutzernamen nicht an der Zeichensatz-
  Umwandlung beim Verbinden scheitern
- ODS 12.0 — Datenbankdateien sind 1:1 zwischen Firebird-3-Systemen
  austauschbar (Windows/Linux, x86/ARM)
