# Algorithmes des reseaux

Ce dépôt contient une liste d'exercices pratiques pour apprendre à utiliser l'API socket du langage C et ainsi implémenter les algorithmes vus en CM et TD. Les exercices sont progressifs et doivent être réalisés dans l'ordre.
Tous les exercices nécessitent une connectivité IPv6 locale pour fonctionner.

## Compilation

Un ou des squelettes de programme C sont fournis pour chaque exercice. Pour les compiler, vous pouvez simplement utiliser la commande `make`.

## Tests locaux natifs

Un script de tests est fourni pour chaque exercice. Vous pouvez lancer les tests avec la commande :

```sh
make test
```

Suivant les exercices, plusieurs tests sont réalisés et un `OK` indique que le test est réussi. Sinon, un court message vous indique la raison de l'échec, vous permettant de corriger les erreurs dans votre programme.

Vous pouvez lancer un test spécifique en indiquant son numéro :

```sh
make test1
make test2
...
```

L'exécution des tests en local nécessite les outils suivants :
- `valgrind` (cet outil n'existe pas sur OSX, vous pouvez néanmoins utiliser l'image docker, cf. ci-dessous)
- `netcat-openbsd`

## Tests locaux sur docker

Vous pouvez tester vos programmes dans une image `docker` (nécessite d'avoir `docker` installé sur votre système).

L'image `docker` configurée pour les exercices peut être récupérée localement et instanciée dans un conteneur via les commandes :

```sh
docker login registry.app.unistra.fr # utilisez votre login et mdp du serveur git.unistra.fr
docker pull registry.app.unistra.fr/montavont/img-docker/algodesreseaux:latest
cd chemin/vers/la/copie/locale/du/dépôt/git
docker run --name algres --rm -it -v $PWD:/home/alice registry.app.unistra.fr/montavont/img-docker/algodesreseaux # cherchez la définition des options avec --help
```

Lorsque vous aurez besoin de manipuler plusieurs terminaux vous pouvez utiliser la commande suivante (une fois le conteneur, nommé ici *algres*, exécuté avec la commande précédente) : `docker exec -it algres bash`

## Tests sur GitLab

Les tests peuvent également être directement exécutés par `gitlab` dans un conteneur `docker` exécuté sur un *runner* de GitLab. Tout `commit/push` sur l'un des fichiers source provoque sa compilation et l'exécution du script de tests. Vous pouvez configurer le dépôt GitLab pour être notifié en cas de succès (ou d'échec) des tests.

Sur l'interface de GitLab, il suffit d'aller dans `build/pipeline` pour visualiser le résultat des tests.
