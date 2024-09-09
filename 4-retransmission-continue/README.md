# Algorithmes des Réseaux

## Retransmission Continue

Ce TP a pour objectif d'implémenter les mécanismes d'anticipation à l'émission (_pipelining_) et de retransmission continue (_Go-Back-N_) vus en cours et en TD, en utilisant des sockets UDP. Un troisième programme simulera une liaison avec pertes pour tester la robustesse de votre implémentation.

### Objectifs

- Implémenter l'anticipation à l'émission afin d'améliorer l'efficacité de la transmission sur une liaison sujette à des pertes.
- Mettre en œuvre un mécanisme de retransmission continue pour garantir l'intégrité des données en cas de perte de paquets.

### Marche à Suivre

Vous allez reprendre vos programmes `sender-udp`, `receiver-udp` et `medium` de l'exercice précédent. Seul le programme `sender-udp` nécessite des modifications pour ce TP.

#### 1. Fenêtre d'émission

L'émetteur utilise une fenêtre d'émission de taille `WNDSIZE`. Ce mécanisme lui permet d'envoyer jusqu'à `WNDSIZE` messages avant de recevoir un accusé de réception. Chaque accusé de réception, en acquittant de nouvelles données, déplace la fenêtre pour permettre l'envoi de nouveaux messages. Les accusés de réception sont cumulatifs : recevoir l'accusé de réception numéro $X$ signifie que tous les messages numérotés jusqu'à $X-1$ ont bien été reçus, et que le récepteur attend désormais le message numéro $X$.

Exemple : Si la taille de la fenêtre est de 4, l'émetteur peut envoyer les messages 0 à 3. Après réception d'un accusé de réception avec le numéro 3, l'émetteur sait que les messages 0 à 2 ont été reçus et qu'il peut décaler la fenêtre pour envoyer les messages 4, 5 et 6.

Note : La gestion des accusés de réception doit prendre en compte la numérotation modulo $N$ des numéros de séquence.

#### 2. Gestion des pertes

Comme dans l'exercice précédent, les pertes de messages sont gérées à l'aide d'un temporisateur. En cas d'expiration du temporisateur, tous les messages actuellement dans la fenêtre d'émission doivent être retransmis.

Exemple : Si la fenêtre d'émission contient les messages 3, 4, 5 et 6, et que le temporisateur expire, l'émetteur doit retransmettre ces quatre messages.

#### 3. Terminaison

Le programme `sender-udp` doit se terminer lorsqu'il n'y a plus de données à envoyer et que tous les messages envoyés ont été acquittés.

#### 5. Gestion des erreurs

Assurez-vous de gérer les erreurs à chaque étape du processus (appel à getaddrinfo, création des sockets, envoi des messages). Si une fonction échoue, affichez un message d'erreur approprié et terminez proprement le programme. Notez que l'expiration du temporisateur ne constitue pas une erreur.

#### 6. Test préliminaire

Testez votre programme avec les commandes suivantes :

- Dans le premier terminal :

```sh
./receiver-udp $(($UID+6000)) > titi
```

- Dans un second terminal :

```sh
./medium $(($UID+6002)) ::1 $(($UID+6001)) ::1 $(($UID+6000)) 0.3
```

- Dans une troisième terminal :

```sh
dd if=/dev/random of="toto" bs=8k count=2 2> /dev/null
./sender-udp $(($UID+6001)) ::1 $(($UID+6002)) < toto
```

À la fin de l'exécution du programme `sender-udp`, quittez les programmes `medium` et `receiver-udp`, puis vérifiez que les fichiers `toto` et `titi` sont identiques :

```sh
cmp toto titi
```

Comparez le temps d'exécution du programme `sender-udp` avec celui de l'exercice précédent (via la commande `time`) pour une même taille de fichier et un même taux d'erreur. Que pouvez-vous en déduire ?

### Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant. Pour ce faire, il vous suffit de commit/push le fichier source pour déclencher le pipeline de compilation et de tests.
