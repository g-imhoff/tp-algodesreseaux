# Algorithmes des réseaux

## Client TCP

Complétez le programme `client-tcp` pour envoyer le message `hello world` avec un socket TCP.

### Commande d'exécution

Le programme admet en argument l'adresse IP et le numéro de port de l'hôte distant à contacter :

```sh
./client-tcp ip_dest port_dest
```

### Objectifs

- Transmettre un message texte en TCP.
- Comprendre la phase de connexion TCP.

### Marche à suivre

#### 1. Création du socket

Complétez une structure d'adresse correspondant à l'hôte distant avec la fonction `getaddrinfo` puis créez un socket TCP avec la primitive `socket`.

#### 2. Connexion au serveur

En TCP, avant de pouvoir transmettre un message, il faut en premier lieu que les clients se *connectent* au serveur. La primitive `connect` permet d'initier une connexion TCP avec un hôte distant :

```c
int connect (int socket, const struct sockaddr *address, socklen_t address_len)
```

Note : le comportement de cette primitive sur un socket UDP est différent de celui sur un socket TCP.

#### 3. Envoi du message

L'envoi du message se fait via la primitive :

```c
ssize_t send (int socket, const void *buffer, size_t length, int flags)
```

Sans option (`flags = 0`), cette primitive est équivalente à :

```c
ssize_t write (int fildes, const void *buf, size_t nbyte)
```

que vous pouvez utiliser si vous êtes nostalgique de l'UE programmation système.

#### 4. Gestion des erreurs

Veillez à gérer les erreurs à chaque étape du processus (appel de getaddrinfo, création du socket, envoi du message). Si une fonction échoue, affichez un message d'erreur approprié et terminez le programme proprement.

#### 5. Tests du programme

Testez votre programme en exécutant netcat (commande `nc`) dans un autre terminal pour écouter en TCP sur l'adresse et le port que vous spécifiez :

- Pour IPv4 :

```sh
nc -4l 127.0.0.1 port_number
```

- Pour IPv6 :

```sh
nc -6l ::1 port_number
```

Ensuite, lancez votre programme dans un autre terminal et vérifiez que le message `hello world` est bien affiché par netcat sur la sortie standard. Consultez les messages échangés avec un analyseur réseau (wireshark, tshark, tcpdump).

Ajoutez l'instruction `sleep(10)` entre l'appel à `connect` et l'envoi du message. Analysez les conséquence de l'appel à `connect` avec un analyseur réseau. Comparez avec l'usage de cette primitive sur un socket UDP.

### Validation

Votre programme doit obligatoirement passer tous les tests sur GitLab avant de passer à l'exercice suivant. Pour ce faire, commit et push votre fichier source sur le dépôt GitLab, ce qui déclenchera le pipeline de compilation et de tests.
