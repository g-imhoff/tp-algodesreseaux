# Algorithmes des réseaux

## Expéditeur UDP

L'objectif de ce TP est de compléter le programme `sender-udp.c` pour envoyer le message texte `hello world` via le protocole UDP à un hôte distant spécifié.

### Commande d'exécution

Le programme prend en argument l'adresse IP et le numéro de port de l'hôte distant à contacter :

```sh
./sender-udp ip_addr port_number
```

### Objectifs

- Savoir créer un `socket`.
- Transmettre un message texte en **UDP**.
- Comprendre la configuration d'une structure d'adresse pour la communication réseau.

### Marche à suivre

#### 1. Configuration de la structure d'adresse

Commencez par compléter une structure d'adresse correspondant à l'hôte distant. Pour ce faire, utilisez la fonction `getaddrinfo` :

```c
int getaddrinfo(const char *hostname, const char *servname, const struct addrinfo *hints, struct addrinfo **res)
```
Cette fonction permet de récupérer une liste chainée de structure `struct addrinfo` de la forme :

```c
struct addrinfo {
    int             ai_flags;      /* options supplémentaires                         */
    int             ai_family;     /* famille (AF_INET pour IPv4, AF_INET6 pour IPv6) */
    int             ai_socktype;   /* type (SOCK_DGRAM pour UDP)                      */
    int             ai_protocol;   /* protocole (IPPROTO_UDP pour UDP)                */
    size_t          ai_addrlen;    /* longueur de struct sockaddr                     */
    struct sockaddr *ai_addr;      /* adresse et port                                 */
    char            *ai_canonname; /* nom de l'hôte                                   */
    struct addrinfo *ai_next;      /* pointeur sur l'élément suivant                  */
};
```

Lors de l'appel à `getaddrinfo`, le système complète les différentes informations sur un hôte spécifique en réalisant soit :
- des requêtes **DNS**,
- des lectures dans des fichiers locaux tels que `/etc/hosts` pour les adresses IP ou `/etc/services` pour les numéros de ports,
- ou une simple conversion des informations passées à la fonction dans le format approprié.

Il est possible d'affiner la recherche réalisée par la fonction `getaddrinfo` en configurant correctement la structure référencée par `hints`. Dans le cas présent, il est nécessaire de définir les champs `ai_family`, `ai_socktype` et `ai_protocol` pour correspondre au protocole UDP, qu'il soit en IPv4 ou en IPv6. 
De plus, il faut compléter le champ `ai_flags` avec les bonnes options afin de s'assurer que `getaddrinfo` convertisse correctement l'adresse IP et le port dans le format adéquat (tous les deux fournis directement sous forme de chaîne de caractères à `getaddrinfo`).

#### 2. Création du socket

Une fois la structure d'adresse configurée, créez un socket à partir des informations collectées par `getaddrinfo` en utilisant la primitive suivante :

```c
int socket(int domain, int type, int protocol);
```

#### 3. Envoi du message

Envoyez le message *hello world* via le socket que vous avez créé en utilisant la fonction `sendto` :

```c
ssize_t sendto(int socket, const void *buffer, size_t length, int flags, const struct sockaddr *dest_addr, socklen_t dest_len)
```

#### 4. Gestion des erreurs

Veillez à gérer les erreurs à chaque étape du processus (appel de `getaddrinfo`, création du `socket`, et envoi du message). Si une fonction échoue, affichez un message d'erreur approprié et terminez le programme proprement.

#### 5. Test du programme

Testez votre programme en exécutant `netcat` (avec la commande `nc`) dans un autre terminal pour écouter en UDP sur l'adresse et le port que vous spécifiez :

- Pour IPv4 :

```sh
nc -4ul 127.0.0.1 port_number
```

- Pour IPv6 :

```sh
nc -6ul ::1 port_number
```

Ensuite, lancez votre programme dans un autre terminal et vérifiez que le message *hello world* est bien affiché par `netcat` sur la sortie standard. Consultez les messages échangés avec un analyseur réseau (`wireshark, tshark, tcpdump`).

### Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant. Pour cette validation à distance, il faut `commit/push` votre fichier source sur le dépôt, ce qui déclenchera le *pipeline* de compilation et de tests.
