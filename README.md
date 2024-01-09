# Tomcat Docker Image

Das hier ist mein Docker Image für Tomcat (10.1.18 mit Java 21 (von https://bell-sw.com)).
Die Basis ist Ubuntu 22.04. Deutsche Locale und Uhrzeit sind vorkonfiguriert.
Die Jakarta Standard Tag Library habe ich integriert (API: 3.0.0, IMPL: 3.0.1).
In diesem Tomcat ist außerdem CDI 2.0 integriert (OpenWebBeans 4.0.1).

Ich habe einen Datenbankpool für Postgres vorkonfiguriert, der über Umgebungsvariablen beeinflussbar ist
(Benutzername, Passwort, Hostname, Port, Schema, max Connections, idle Connections). Der JDBC-Treiber ist in Version 42.7.1 enthalten. Der Resource-Name ist fest verdrahtet (`jdbc/postgres`).

Für diese Datenbankresource ist standardmäßig ein SHA-512 DataSourceRealm konfiguriert.

Außerdem ist ein `keystore` und ein `truststore` vorkonfiguriert.
Der `keystore` enthält ein selbst erstelltes Zertifikat, damit man lokale Tests mit HTTPS machen kann.
Der `truststore` enthält lediglich das Root und Intermediate Zertifikat von Let's Encrypt.
Will man Tomcat produktiv über HTTPS erreichen, muss man mindestens einen eigenen `keystore` erstellen und den von "außen" in den Container reingeben (`/opt/tomcat/conf/keystore.jks` und `/opt/tomcat/conf/cacerts.jks`). Oder man macht das anders (Reverse Proxy, der selbst HTTPS macht). Tomcat lauscht auf 8080 (HTTP) und 8443 (HTTPS).
Passwort (Key- und Truststore) und Alias (Keystore) sind über Umgebungsvariablen steuerbar (siehe Beispiel `docker-compose.yml`). Das Passwort für Key- und Truststore ist `changeit`.

In meinem Tomcat ist eine Erweiterung enthalten, die es erlaubt `_FILE`-Umgebungsvariablen in XML-Konfigurationen zu verwenden (siehe: https://github.com/schipplock/tomcat-environment-property-source-file).

Den `manager` und `host-manager` habe ich aus meinem Tomcat entfernt, weil ich das nicht benötige und es nicht zu der Art passt, wie ich Webanwendungen mit diesem Tomcat-Image "deploye". Docs und Examples habe ich auch gelöscht.

Aus Sicherheitsgründen deployt Tomcat nur beim Start eine vorhandene *.war. Nachträglich abgelegte *.war-Dateien werden nicht berücksichtigt. Der Shutdown-Port ist deaktiviert.

Datei-Uploads können im Ordner `/opt/tomcat/uploads` abgelegt werden. Dieser Ort ist in der Umgebungsvariable `TOMCAT_UPLOAD_DIR` hinterlegt.
Für diesen Ordner ist ein eigener Context konfiguriert, den man unter `/_files` über HTTP/HTTPS erreicht (kein DirectoryListing aktiviert).
Nutzt man diesen Ordner, muss man zwingend ein Volume dafür definieren, da die Dateien sonst beim erneuten Erstellen des Containers weg sind.

## Wichtig!

`REMOTE_DEBUG_ENABLED` und `REMOTE_JMX_ENABLED` in der `docker-compose.yml` sollten in einer produktiven Umgebung auf
gar keinen Fall auf `true` gesetzt werden. Es können zum Beispiel die Zugangsdaten der Datenquelle ausgelesen werden.
Diese beiden Umgebungsvariablen sollen nur für die lokale Entwicklung genutzt werden.

Wenn man sich natürlich ganz sicher ist, mit Firewall und so, von mir aus. Ich könnte JMX auch "sicher" machen, mit
Zertifikaten und SSL, Benutzernamen und Passwort, aber ich benötige es nur lokal. Vielleicht ein anderes Mal.

JMX funktioniert nur, wenn der RMI-Port auch freigegeben wurde. So wie in der `docker-compose.yml` auch beispielhaft
gezeigt. Ich erwähne es aber dennoch, weil der Port sinnlos zu wirken scheint. Er existiert aber aus realen Gründen :).
Ich nutze JMX mit VisualVM (https://visualvm.github.io/) und manchmal auch nur mit `jconsole`.

## Wie benutze ich das Image?

**Ich verpacke meine .war einfach in ein eigenes Docker-Image:**

```dockerfile
FROM ghcr.io/schipplock/tomcat-docker-image:v10.1.18
COPY target/foobar-0.0.1.war /opt/tomcat/webapps/ROOT.war
```

**Ich erstelle dann das Docker-Image:**

```bash
docker build --no-cache --network=host --force-rm -t local/foobar:0.0.1 .
```

## Das Image bauen

Wenn man das Image selber bauen will:

```bash
docker build --no-cache --network=host --force-rm -t ghcr.io/schipplock/tomcat-docker-image:v10.1.18 .
```