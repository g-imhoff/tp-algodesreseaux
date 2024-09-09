# Algorithmes des Réseaux

## Envoyer et Attendre

Dans cet exercice, le récepteur n'est pas toujours prêt à recevoir. L'objectif de ce TP est d'implémenter l'algorithme *envoyer et attendre* présenté en cours et en TD, en utilisant un socket UDP, afin de s'adapter aux capacités de traitement du récepteur (contrôle de flux).

### Objectifs

- Transmettre de grandes quantités de données via UDP.
- Implémenter un mécanisme de contrôle de flux.

### Marche à suivre

Reprenez les programmes `sender-udp` et `receiver-udp` de l'exercice précédent.

#### 1. Simulation du temps de traitement

Pour simuler le temps de traitement des données côté récepteur, appelez la fonction `process_data` après chaque réception de données et avant chaque écriture sur la sortie standard. Cette fonction est déjà implémentée.

#### 2. Tampon de réception

Ajustez la taille du tampon de réception du socket afin de provoquer des pertes en l'absence d'un mécanisme de contrôle de flux. Ce tampon stocke les messages UDP reçus et non encore traités par un appel à `recvfrom`. Si des nouvelles données arrivent alors qu'il est plein, ces dernières sont perdues. Fixez sa taille à `BUFSIZE` (déjà définie) octets en utilisant la primitive suivante :

```c
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen)
```

Utilisez la constante `SO_RCVBUF` pour `optname`. Référez-vous au manuel des sockets (man 7 socket) pour plus de détails sur son utilisation.

#### 3. Contrôle de flux

Implémentez un mécanisme de contrôle de flux selon l'algorithme envoyer et attendre :

- Le récepteur envoie un message à l'expéditeur lorsqu'il est prêt à recevoir de nouvelles données.
- L'expéditeur attend la confirmation du récepteur avant d'envoyer plus de données (sauf pour la première transmission).

#### 4. Gestion des erreurs

Gérez les erreurs à chaque étape du processus (appel à getaddrinfo, création du socket, envoi du message). Si une fonction échoue, affichez un message d'erreur approprié et terminez le programme proprement. Notez que l'expiration d'un temporisateur ne constitue pas une erreur.

#### 5. Test des programmes

- Lancez le programme `receiver-udp` dans un terminal :

```sh
./receiver-udp $(($UID+6000)) > titi
```

- Exécutez les commandes suivantes dans un second terminal :

```sh
dd if=/dev/random of="toto" bs=8k count=1 2> /dev/null
./sender 127.0.0.1 $((UID+6000)) < toto
```

Vérifiez que les fichiers `toto` et `titi` sont identiques à l'aide de la commande :

```sh
cmp toto titi
```

Réalisez le même test en IPv6. Consultez les messages échangés avec un analyseur réseau (wireshark, tshark, tcpdump).

### Validation

Votre programme doit obligatoirement passer tous les tests sur GitLab avant de passer à l'exercice suivant. Pour cela, il suffit de `commit/push` le fichier source pour déclencher le pipeline de compilation et de tests.
