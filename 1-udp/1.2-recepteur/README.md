# Algorithmes des réseaux

## Récepteur UDP

L'objectif de ce TP est de compléter le programme `receiver-udp.c` pour réceptionner un message texte via le protocole UDP. Le message reçu ainsi que les informations de l'expéditeur (adresse IP et port) seront affichés sur la sortie standard.

### Commande d'exécution

Le programme prend en argument le numéro de port à utiliser localement :

```sh
./receiver-udp port_number
```

### Exemple de sortie attendue

Lorsque le programme reçoit un message, la sortie doit être de la forme suivante :

```sh
./receiver-udp 10001
::ffff:127.0.0.1 1234 a envoyé : hello world
```

Ici, *hello world* est le message reçu, et `::ffff:127.0.0.1` et `1234` sont respectivement l'adresse IP et le port de l'expéditeur du message.

### Objectifs

- Configurer un `socket` en double pile IPv4 et IPv6.

- Savoir réceptionner un message texte en UDP.

- Afficher les informations de l'expéditeur.

### Marche à suivre

Vous devez réaliser le complément de l'exercice précédent (1.1) en suivant les étapes ci-dessous :

#### 1. Préparation de l'adresse locale

Complétez une structure d'adresse correspondant à l'hôte local en utilisant la fonction `getaddrinfo` :

```c
int getaddrinfo(const char *hostname, const char *servname, const struct addrinfo *hints, struct addrinfo **res)
```

- Pour l'adresse IP, passez le pointeur `NULL` et utilisez le flag `AI_PASSIVE` pour indiquer que le programme doit utiliser toutes les adresses disponibles de la machine.

- Convertissez le port en format adéquat (comme dans l'exercice précédent avec le champ `ai_flags`).

#### 2. Création du socket

Créez un socket à partir des informations collectées par `getaddrinfo` avec la primitive suivante :

```c
int socket(int domain, int type, int protocol)
```

#### 3. Configuration du socket

Configurez ce `socket` pour accepter les transmissions en IPv4 et en IPv6 :

```c
int value = 0;
CHK(setsockopt(sockfd, IPPROTO_IPV6, IPV6_V6ONLY, &value, sizeof value));
```

#### 4. Association du socket à l'adresse et au port

Associez le `socket` avec l'adresse et le port obtenus via `getaddrinfo` :

```c
int bind(int socket, const struct sockaddr *address, socklen_t address_len)
```

#### 5. Réception du message

Recevez un message avec la primitive suivante :

```c
ssize_t recvfrom(int socket, void *restrict buffer, size_t length, int flags, struct sockaddr *restrict address, socklen_t *restrict address_len)
```

- Le paramètre `buffer` contiendra les octets reçus en cas de succès.

- Les paramètres `address` et `address_len` seront automatiquement complétés par le système avec les informations de l'expéditeur. Prévoyez de la place pour stocker une structure d'adresse (utilisez une structure de type `struct sockaddr_storage`).

#### 6. Conversion des informations de l'expéditeur

Convertissez l'adresse IP et le port de l'expéditeur en chaînes de caractères avec la fonction suivante :

```c
int getnameinfo(const struct sockaddr *sa, socklen_t salen, char *host, socklen_t hostlen, char *serv, socklen_t servlen, int flags);
```

Consultez le manuel utilisateur (`man`) pour connaître les options possibles et comment traiter les erreurs associées à cette fonction.

#### 7. Gestion des erreurs

Veillez à gérer les erreurs à chaque étape du processus (appel de `getaddrinfo`, création du `socket`, envoi du message). Si une fonction échoue, affichez un message d'erreur approprié et terminez le programme proprement.

#### 8. Test du programme

Testez votre programme avec le programme réalisé dans l'exercice précédent ou en utilisant `netcat` (`nc`en pratique) dans un autre terminal.

- Lancez votre programme dans un terminal.

- Exécutez les commandes suivantes dans un second terminal pour envoyer le message hello world en UDP :

    - Transmission IPv4 :

    ```sh
    echo "hello world" | nc -4u -w1 127.0.0.1 port_du_prog -p port_local_pour_netcat
    ```

    - Transmission IPv6 :

    ```sh
    echo "hello world" | nc -6u -w1 ::1 port_du_prog -p port_local_pour_netcat
    ```

- Vérifiez que l'adresse IP et le port affichés par votre programme sont conformes à ceux utilisés par l'expéditeur.

- Commentez le format de l'adresse dans le cas d'une transmission IPv4.

- Consultez les messages échangés avec un analyseur réseau (`wireshark, tshark, tcpdump`).

### Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant. Pour vérifier cela, il suffit de `commit/push` le fichier source pour déclencher le *pipeline*  de compilation et de tests.
