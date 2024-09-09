# Algorithmes des réseaux

## Chat multi-utilisateur avec TCP

Dans ce TP vous allez vous familiariser avec la création, la gestion et la communication via un serveur TCP capable de gérer plusieurs clients simultanément. Vous allez développer un programme `client-tcp` et un programme `serveur-tcp`. Ce dernier devra gérer plusieurs connexions clientes de manière concurrente en utilisant la primitive `poll`.

### Objectifs
- Créer et gérer des sockets TCP.
- Utiliser la primitive `poll` pour la gestion simultanée de plusieurs descripteurs de fichiers.
- Diffuser des messages à plusieurs clients.
- Analyser des échanges réseau avec des outils comme tshark et tcpdump.
- Comprendre le fonctionnement du protocole TCP en mode flux, avec et sans l'algorithme de Nagle.

### Marche à suivre

#### 1. Implémentation du client

Reprenez le code source `client-tcp.c` de l'exercice 5.1. Modifiez ce programme pour qu'il écoute simultanément sur l'entrée standard et sur le socket connecté au serveur en utilisant la primitive poll :

```c
int poll(struct pollfd *fds, nfds_t nfds, int timeout)
```
Lorsque des données sont disponibles sur l'entrée standard, elles doivent être envoyées au serveur via le socket. De même, si des données sont reçues sur le socket, elles doivent être affichées sur la sortie standard.

Le programme client doit se terminer lorsque l'entrée standard est fermée ou lorsque le serveur ferme la connexion.

Note : `poll` a un comportement différent si le descripteur sur lequel on attend en lecture est un tube ou un fichier. Dans le cas de la fermeture d'un tube, `poll` se débloque et retourne l'événement `POLLHUP` pour ce descripteur.

#### 2. Implémentation du serveur

Reprenez le code source `serveur-tcp.c` de l'exercice 5.2. Supprimez les affichages des informations sur les connexions clientes lors de leur arrivée.

- Initialisation : Le serveur doit utiliser `poll` pour écouter sur l'entrée standard et sur le socket acceptant les connexions entrantes.
- Gestion des connexions : Lorsqu'un nouveau client se connecte, ajoutez le socket créé par `accept` à la liste des descripteurs surveillés par `poll`. Si un client se déconnecte, retirez le socket correspondant de cette liste.
- Diffusion des messages :

    - Lorsque le serveur reçoit un message sur l'entrée standard, il doit le diffuser à tous les clients connectés.
    - Lorsque le serveur reçoit un message d'un client, il doit le diffuser à tous les autres clients et l'afficher sur la sortie standard.
    - Le serveur se termine après la déconnexion du dernier client.

- Gestion des erreurs et des limites : Le serveur doit gérer un maximum de `MAX` clients simultanés. Si cette limite est atteinte, les nouvelles connexions doivent échouer avec un message d'erreur affiché sur la sortie d'erreur du serveur. Le serveur ne doit pas se terminer pour autant. Pour simplifier les tests, on fixera `MAX` à 2.

#### 3. Gestion des erreurs

Assurez-vous de gérer les erreurs à chaque étape du processus : création du socket, appel à `poll`, réception des messages, etc. En cas d'erreur, affichez un message approprié et terminez proprement le programme.

#### 4. Test du programme

- Test en environnement multi-client : Exécutez le serveur dans un terminal et au moins deux clients dans d'autres terminaux. Assurez-vous que les messages envoyés par un client sont bien reçus par les autres clients connectés.

- Test de transmission de fichier : Testez la capacité d'un client à transmettre un fichier au serveur :

    - pour le serveur :

    ```sh
    ./serveur-tcp port_local > titi
    ```

    - pour le client :

    ```sh
    dd if=/dev/random of="toto" bs=8k count=2 2> /dev/null
    ./client-tcp ::1 port_du_serveur < toto
    ```

    - vérifiez que les fichiers `toto` et `titi` sont identiques :

    ```sh
    cmp toto titi
    ```

#### 5. Analyse du mode flux de TCP

Contrairement à UDP, TCP est un protocole en mode flux. Cela signifie que l'envoi de données via un socket TCP est géré par TCP lui-même, et non par l'application :

- un appel à `send` ne provoque pas nécessairement l'émission d'un segment
- un appel à `recv` peut retourner des données provenant de plusieurs segments

En pratique, l'émission des segments TCP est gérée par l'algorithme de [Nagle](https://www.ietf.org/rfc/rfc0896.txt). Pour le mettre en évidence, modifiez la taille du buffer du client pour forcer TCP à envoyer des petits segments :
```c
#define BUFSIZE 2
```

Répétez le test de transmission de fichier et analysez le trafic réseau avec tshark ou tcpdump pour observer comment les données sont segmentées et envoyées.

```sh
tshark -i lo -f "tcp and ip6"
```

Combien de segments sont envoyés pour transmettre l'intégralité du fichier ? Ont-ils tous la même taille ? Combien de fois la primitive `read/recv` est-elle appelée pour reconstituer l'intégralité du fichier (vous pouvez préfixer le programme serveur par la commande `strace`) ? Combien d'octets sont récupérés à chaque appel ?

Désactivez l'algorithme de Nagle sur le client en utilisant `setsockopt` avec l'option `TCP_NODELAY` :

```c
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen)
```

Utilisez `IPPROTO_TCP` pour le paramètre `level`.  Vous devez ajouter en plus le fichier d'inclusion :

```c
#include <netinet/tcp.h>
```

Répétez l'analyse du trafic avec tshark après avoir désactivé Nagle et comparez les résultats avec ceux obtenus précédemment. Le comportement du serveur a-t-il changé ? Quelle version de la transmission est la plus efficace ?

### Validation

Votre programme doit obligatoirement passer tous les tests sur GitLab. Pour ce faire, commit et push votre fichier source sur le dépôt GitLab, ce qui déclenchera le pipeline de compilation et de tests.
