# Algorithmes des réseaux

## Transmission d'une large quantité de données

L'objectif de ce TP est d'envoyer une large quantité de données entre deux hôtes en UDP. Vous devrez écrire deux programmes, l'un pour l'expéditeur et l'autre pour le récepteur.

### Objectifs

- Savoir transmettre de large quantité de données en UDP.
- Comprendre le fonctionnement de la primitive `connect` sur un `socket` UDP.
- Comprendre une transmission en *mode paquet*.

### Marche à suivre

Reprenez les programmes `sender-udp` et `receiver-udp` que vous avez développés pour les exercices 1.1 et 1.2. Modifiez ces programmes pour que :
- l'expéditeur envoie toutes les données lues sur l'entrée standard au récepteur via le `socket UDP`,
- le récepteur écrive toutes les données reçues sur le `socket` sur sa sortie standard. Vous supprimerez l'affichage des informations de l'expéditeur.

#### 1. Copie des données

La copie des données depuis l'entrée standard vers le `socket` (sur l'émetteur) et depuis le `socket` vers la sortie standard (sur le récepteur) devra utiliser la fonction suivante :

```c
void copie(int src, int dst)
```

qui prend en argument deux descripteurs avec :
- `src` qui correspond au descripteur sur lequel lire les données,
- `dst` qui correspond au descripteur sur lequel écrire les données lues.

Vous pouvez reprendre la fonction que vous aviez écrite lors des TP de programmation système en L2S4. Vous veillerez à utiliser la même taille de tampon pour l'émission et la réception.

#### 2. Terminaison du programme receiver-udp 

Le programme `receiver-udp` doit *boucler* sur la réception de données sur le socket car on ne connaît pas à l'avance la quantité de données attendues. Pour arrêter le programme proprement, vous modifierez l'action associée à la réception du signal `SIGTERM` pour appeler la fonction :

```c
void quit(int signo)
{
    (void)signo;
    exit(EXIT_SUCCESS);
}
```

#### 3. Primitive connect

La primitive `connect` est prévue pour offrir un service orienté connexion. En l'utilisant sur un socket UDP, il est possible de *privatiser* ce socket pour communiquer *exclusivement* avec l'hôte distant dont les paramètres sont passés lors de l'appel de la primitive :

```c
 int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
```

En cas de succès, il est désormais possible d'utiliser les primitives `send` et `recv`, et même `write` et `read` sur le socket (sans préciser le destinataire/émetteur grâce à la *privatisation* du `socket`).

#### 4. Gestion des erreurs

Veillez à gérer les erreurs à chaque étape du processus (appel de `getaddrinfo`, création du `socket`, envoi du message). Si une fonction échoue, affichez un message d'erreur approprié et terminez le programme proprement. Un temporisateur qui expire ne constitue pas une erreur.

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

Réalisez le même test en IPv6. Consultez les messages échangés avec un analyseur réseau (`wireshark, tshark, tcpdump`).

#### 5. Spécificité du mode paquet et de la primitive connect

- Modifiez la taille du tampon côté récepteur afin qu'elle soit inférieure à celle de l'émetteur et lancez le test 4. Que constatez-vous ? Pourquoi ?

- Exécutez le programme `sender-udp` sans récepteur et envoyez au moins deux messages. Que constatez-vous ? Pourquoi ? Consultez les messages échangés avec un analyseur réseau (`wireshark, tshark, tcpdump`). Observe-t-on le même comportement sans l'utilisation de la primitive `connect` ?

### Validation

Votre programme doit réussir tous les tests sur GitLab avant de passer à l'exercice suivant. Pour cela, il suffit de `commit/push` le fichier source pour déclencher le *pipeline* de compilation et de tests.
