# Algorithmes des réseaux

## Serveur TCP

L'objectif de ce TP est de vous familiariser avec la création et la gestion d'un serveur TCP. Vous allez compléter un programme `serveur-tcp` capable de recevoir un message texte via un socket TCP.

### Commande d'exécution

Le programme doit être exécuté avec le numéro de port local en argument :

```sh
./serveur-tcp port_local
```

### Exemple de sortie attendue

Lorsque le programme reçoit un message, la sortie doit être sous la forme suivante :

```sh
./serveur-tcp 10001
::ffff:127.0.0.1 1234 a envoyé : hello world
```

Dans cet exemple :

- `hello world` est le message reçu.
- `::ffff:127.0.0.1` est l'adresse IP de l'expéditeur.
- `1234` est le port source utilisé par l'expéditeur.

### Objectifs

- Créer un socket TCP pour recevoir des messages.
- Comprendre et manipuler les états des connexions TCP.
- Analyser les échanges réseau avec des outils de diagnostic.

### Marche à suivre

#### 1. Création du socket

Complétez une structure d'adresse correspondant à l'hôte local avec `getaddrinfo`.

Créez un socket TCP avec la primitive `socket` qui supporte à la fois IPv4 et IPv6 (double pile).

Le protocole TCP met un temps non négligeable pour fermer un socket afin d'être sûr que tous les segments appartenant à la connexion qui vient de se terminer ne puissent pas être acceptés à tort par une nouvelle connexion avec le même quadruplet (adresse source, port source, adresse destination, port destination). Cela permet également de s'assurer que l'hôte distant a bien terminé la connexion. Cependant, ce mécanisme ralentit significativement les tests qui utilisent le même quadruplet à plusieurs reprises. Pour éviter cette attente, activez l'option `SO_REUSEADDR` sur le socket pour permettre la réutilisation rapide du port :

```c
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);
```

Consultez la page de manuel (`man 7 socket`) pour plus de détails sur cette primitive.

Associez le socket à l'adresse et au port avec `bind`.

### 2. Mise en attente d'une connexion

Le socket que vous venez de configurer ne sera utilisé que pour accepter les connexions entrantes (donc recevoir les messages *SYN* de TCP). Aucune donnée ne sera échangée sur ce socket. Une telle configuration est réalisée avec la primitive :

```c
int listen(int socket, int backlog);
```

Le paramètre `backlog` détermine le nombre de connexions en attente qui peuvent être maintenues en file d'attente.

Acceptez une connexion entrante avec `accept`, qui retourne un nouveau socket dédié à cette connexion :

```c
int accept(int socket, struct sockaddr *restrict address, socklen_t *restrict address_len);
```

En cas de succès, vous disposerez désormais de deux sockets :

- Le socket initial, utilisé pour accepter les nouvelles connexions.
- Le socket retourné par `accept`, utilisé pour communiquer exclusivement avec le client connecté.

#### 3. Réception et affichage du message

Utilisez la primitive `recv` pour lire le message envoyé par le client sur le socket retourné par `accept` :

```c
ssize_t recv (int socket, void *buffer, size_t length, int flags)
```

Obtenez les informations sur le client (adresse IP et port) à partir de la structure passée à `accept` (utilisez une structuture `struct sockaddr_storage`).

Convertissez ces informations en chaînes de caractères avec `getnameinfo` pour les afficher.

#### 4. Gestion des erreurs

Assurez-vous de gérer les erreurs à chaque étape du processus (appel à `getaddrinfo`, création du socket, réception du message). En cas d'échec, affichez un message d'erreur approprié et terminez proprement le programme.

#### 5. Tests du programme

Exécutez votre programme dans un terminal.

Dans un autre terminal, utilisez netcat pour envoyer un message au serveur :

- Pour IPv4 :

```sh
printf "hello world" | nc -4 127.0.0.1 port_number -p port_local_netcat
```

- Pour IPv6 :

```sh
printf "hello world" | nc -6 ::1 port_number -p port_local_netcat
```

Vérifiez que les informations affichées par votre programme sont exactes.

Analysez le trafic réseau échangé avec un outil comme `tshark` ou `tcpdump` :

```sh
tshark -i lo -f "tcp and ip6"
```

Identifiez la phase de connexion, l'envoi des données et la phase de fermeture. Quelles sont les options utilisées ? Quels sont les numéros de séquence choisis initialement ? (ajoutez `-V` pour avoir les entêtes complètes)

#### 6. Analyse de l'état TCP

Ouvrez un nouveau terminal et surveillez l'état de la connexion TCP avec netstat :

```sh
watch -n 1 netstat -tna
```

Exécutez votre programme dans un autre terminal et observez l'état de la connexion.

Copiez votre programme de l'exercice 5.1 dans le répertoire courant. Modifiez ce programme pour inclure `sleep(10)` entre la connexion et l'envoi du message, puis après l'envoi. Observez comment l'état TCP évolue.

### Validation

Votre programme doit obligatoirement passer tous les tests sur GitLab avant de passer à l'exercice suivant. Pour ce faire, commit et push votre fichier source sur le dépôt GitLab, ce qui déclenchera le pipeline de compilation et de tests.
