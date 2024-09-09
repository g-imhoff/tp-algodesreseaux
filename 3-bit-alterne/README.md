# Algorithmes des réseaux

## Implémentation du Bit Alterné

Ce TP a pour objectif d'implémenter l'algorithme du *bit alterné* présenté en cours et en TD, en utilisant des sockets UDP. Un troisième programme simulera une liaison avec perte pour tester la robustesse de votre implémentation.

### Objectifs

- Mettre en œuvre un mécanisme ARQ (*Automatic Repeat reQuest*) pour assurer la transmission fiable de données sur une liaison sujette à des pertes.
- Développer un programme capable de simuler une liaison avec un taux de perte configurable.

### Marche  à suivre

Complétez le programme `medium` pour qu'il transmette les données reçues de l'émetteur au récepteur (et vice versa) avec une probabilité de perte définie par un paramètre $P$. Autrement dit, un message a une probabilité $1 - P$ d'être transmis correctement.

Le programme `medium` prendra les arguments suivants : le numéro de port local, l'adresse IP et le port de l'émetteur, l'adresse IP et le port du récepteur, ainsi que le taux de perte $P$ (compris entre 0 et 1) :

```sh
./medium port_local ip_emetteur port_emetteur ip_recepteur port_recepteur taux_perte
```

#### 1. Création des sockets

Vous devez créer deux sockets : l'un pour la communication avec l'émetteur et l'autre pour la communication avec le récepteur.

#### 2. Gestion de plusieurs descripteurs

Le programme `medium` doit être capable de recevoir des données depuis les deux sockets, sans présumer de l'ordre d'arrivée. Pour ce faire, utilisez la fonction poll :

```c
int poll(struct pollfd *fds, nfds_t nfds, int timeout)
```

Cette fonction vous permet de surveiller plusieurs descripteurs simultanément. Vous utiliserez la structure `struct pollfd` pour spécifier les descripteurs à surveiller :

```c
struct pollfd {
    int   fd;         /* Descripteur du socket             */
    short events;     /* Événements à surveiller           */
    short revents;    /* Événements survenus               */
};
```

Le champ `events` doit être configuré pour surveiller l'événement `POLLIN` (indiquant que des données sont disponibles en lecture sur le descripteur). Après l'appel à `poll`, vérifiez les champs `revents` pour déterminer sur quel descripteur un événement s'est produit.

#### 3. Gestion de la perte des messages

La perte d'un message est simulée en ne transmettant pas le message reçu. Pour générer un nombre pseudo-aléatoire dans l'intervalle [0,1], vous pouvez utiliser :

```c
double r = (double) rand() / RAND_MAX;
```

N'oubliez pas d'initialiser la graine du générateur pseudo-aléatoire avec `srand()`.

#### 4. Test préliminaire

Utilisez vos programmes `sender-udp` et `receiver-udp` de l'exercice précédent pour effectuer un test préliminaire.

Modifiez le programme `sender-udp` pour qu'il prenne en compte le numéro de port local à utiliser :

```sh
./sender-udp port_local ip_dest port_dest
```

Modifiez le programme `receiver-udp` pour désactiver la simulation de temps de traitement et la limitation du tampon de réception UDP, afin d'accélérer le déroulement des tests.

Testez vos programmes avec les commandes suivantes :

- Dans le premier terminal :

```sh
./receiver-udp $(($UID+6000)) > titi
```

- Dans un second terminal :

```sh
./medium $(($UID+6002)) ::1 $(($UID+6001)) ::1 $(($UID+6000)) 0
```

- Dans une troisième terminal :

```sh
dd if=/dev/random of="toto" bs=8k count=1 2> /dev/null
./sender-udp $(($UID+6001)) ::1 $(($UID+6002)) < toto
```

À la fin de l'exécution du programme `sender-udp`, quittez les programmes `medium` et `receiver-udp`, puis vérifiez que les fichiers `toto` et `titi` sont identiques :

```sh
cmp toto titi
```

Refaites le test en configurant un taux d'erreur non nul et constatez que les fichiers sont différents.

#### 5. Implémentation du mécanisme ARQ

Modifiez les programmes `sender-udp` et `receiver-udp` pour implémenter l'algorithme du *bit alterné*. Cet algorithme requiert l'envoi de messages de contrôle en plus des données. Vous pouvez définir une structure pour le format des messages.

La retransmission des messages perdus sera déclenchée par l'expiration d'un temporisateur côté émetteur. Pour ce faire, configurez le socket de l'émetteur de sorte qu'il retourne l'erreur `EAGAIN` si aucune donnée n'est reçue dans le délai imparti à l'aide de la primitive :

```c
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen)
```

Utilisez la constante `SO_RCVTIMEO` pour `optname`. Le temporisateur doit être réglé à 2 secondes. Référez-vous au manuel des sockets (`man 7 socket`) pour plus de détails sur son utilisation.

#### 6. Génération de traces des messages

Modifiez le programme medium pour qu'il génère sur la sortie standard une trace de chaque message reçu sous la forme suivante :

```sh
X->Y, seq=Z -> K
```

- `X` représente la source : `E` pour l'émetteur, `R` pour le récepteur.
- `Y` représente la destination : `E`pour l'émetteur, `R` pour le récepteur.
- `Z` représente le numéro de séquence du message.
- `K` indique si le message a été transmis ("transmis") ou perdu ("perte").

La génération de ces traces vous permettra de vérifier le bon déroulement de la transmission et de la perte des messages en fonction du taux de perte configuré. Assurez-vous que la génération de ces traces est précise et reflète exactement ce qui se passe au niveau du medium.

#### 7. Gestion des erreurs

Assurez-vous de gérer les erreurs à chaque étape du processus (appel à getaddrinfo, création des sockets, envoi des messages). Si une fonction échoue, affichez un message d'erreur approprié et terminez proprement le programme. Notez que l'expiration du temporisateur ne constitue pas une erreur.

#### 8. Test final

Reprenez le test réalisé à l'étape 4 et assurez-vous que les fichiers sont identiques, même en présence de pertes.

### Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant. Pour ce faire, il vous suffit de commit/push le fichier source pour déclencher le pipeline de compilation et de tests.
