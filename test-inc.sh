#!/bin/sh

#
# Définitions de fonctions et de variables communes à tous les
# scripts de tests.
#
# Note sur l'utilisation des scripts de tests (scripts tests.sh dans les
# répertoires des exercices) :
#
# - Si tout se passe bien, le script doit afficher "Tests ok" à la fin
# - Dans le cas contraire, le nom du test échoué s'affiche.
# - Les fichiers sont laissés dans /tmp/test*, vous pouvez les examiner
# - Pour avoir plus de détails sur l'exécution du script, vous pouvez
#   utiliser :
#	sh -x ./test.sh
#   Toutes les commandes exécutées par le script sont alors affichées.
#

TMP=${TMP:=/tmp/test.$USER}     # chemin des logs de test

# Conserver la locale d'origine
OLDLOCALE=$(locale)

# Pour éviter les différences de comportement suivant la locale courante
LC_ALL=POSIX
export LC_ALL

# Les arguments pour les programmes
IP4="127.0.0.1"
IP6="::1"
PORT=`shuf -i 10000-65000 -n 1`

# erreur si accès variable non définie
set -u

fail()
{
    local msg="$1"

    echo FAIL
    echo "$msg"
    echo "Voir les fichiers suivants :"
    ls -dp $TMP*
    exit 1
}

# longueur (en nb de caractères, pas d'octets) d'une chaîne UTF-8
# Note : la locale doit être en UTF-8
strlen()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE strlen"
    local str="$1"
    (
	eval $OLDLOCALE
	printf "%s" "$str" | wc -m
    )
}

# Annonce un test
# $1 = numéro du test
# $2 = intitulé
annoncer_test()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE annoncer_test"
    local num="$1" msg="$2"
    local debut nbcar nbtirets

    # echo '\c', bien que POSIX, n'est pas supporté sur tous les Shell
    # POSIX recommande d'utiliser printf
    # Par contre, printf ne gère pas correctement les caractères Unicode
    # donc on est obligé de recourrir à un subterfuge pour préserver
    # l'alignement des "OK"
    debut="Test $num - $msg"
    nbcar=$(strlen "$debut")
    nbtirets=$((80 - 6 - nbcar))
    printf "%s%-${nbtirets}.${nbtirets}s " "$debut" \
	"...................................................................."
}

# Teste si un fichier est vide (ne fait que tester, pas d'erreur renvoyée) 
est_vide()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE est_vide"
    [ ! -s $1 ]
}

# Vérifie que le message d'erreur est envoyé sur la sortie d'erreur
# et non sur la sortie standard
# $1 = nom du fichier de log (sans .err ou .out)
# $2 (optionnel) = motif devant se trouver sur la sortie d'erreur
verifier_stderr()
{
    [ $# != 1 -a $# != 2 ] && fail "ERREUR SYNTAXE verifier_stderr"
    local base="$1" msg=""

    est_vide $base.err \
	&& fail "Le message d'erreur devrait être sur la sortie d'erreur"
    est_vide $base.out \
	|| fail "Rien ne devrait être affiché sur la sortie standard"

    if [ $# = 2 ]; then
	grep -q "$2" $base.err \
	    || fail "le motif \"$2\" n'est pas sur la sortie d'erreur"
    fi
}

# Vérifie que le résultat est envoyé sur la sortie standard
# et non sur la sortie d'erreur
# $1 = nom du fichier de log (sans .err ou .out)
# $2 (optionnel) = motif devant se trouver sur la sortie standard
verifier_stdout()
{
    [ $# != 1 -a $# != 2 ] && fail "ERREUR SYNTAXE verifier_stdout"
    local base="$1" msg=""

    est_vide $base.out \
	&& fail "Le résultat devrait être sur la sortie standard"
    est_vide $base.err \
	|| fail "Rien ne devrait être affiché sur la sortie d'erreur"

    if [ $# = 2 ]; then
	grep -q "$2" $base.out \
	    || fail "le motif \"$2\" n'est pas sur la sortie standard"
    fi
}

# génère un fichier pseudo-aléatoire
# $1 = nom
# $2 = taille (en multiples de 1 Mio)
generer_fichier_aleatoire()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE generer_fichier_aleatoire"

    local nom="$1" taille="$2"
    local random=/dev/urandom

    if [ ! -c $random ]
    then echo "Pas de driver '$random'. Arrêt" >&2 ; exit 1
    fi

    dd if=$random of="$nom" bs=8k count="$taille" 2> /dev/null
}

comparer()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE comparer"

    [ "$1" !=  "$2" ] \
	&& fail "le message reçu est différent de \"hello world\"" 
}

# la commande "timeout" n'est pas POSIX, mais on fait comme si
# $1 = délai max en secondes
# $2 ... := commande et arguments
lancer_timeout ()
{
    [ $# -le 1 ] && fail "ERREUR SYNTAXE lancer_timeout"

   local delai="$1" ; shift

    local r

    timeout "$delai" sh -c "$*" > $TMP.out 2> $TMP.err
    r=$?
    [ $r = 124 ] && fail "Timeout de $delai sec dépassé pour : $*"
    return $r
}

# Lancer valgrind avec toutes les options
tester_valgrind()
{
    local r
    valgrind \
	--leak-check=full \
	--errors-for-leak-kinds=all \
	--show-leak-kinds=all \
	--error-exitcode=100 \
	--log-file=$TMP.valgrind \
	"$@" > $TMP.out 2> $TMP.err
    r=$?
    [ $r = 100 ] && fail "pb mémoire (cf $TMP.valgrind)"
    [ $r != 0 ]  && fail "erreur programme (code=$r) avec valgrind (cf $TMP.*)"
    return $r
}

verifier_trace()
{
    [ $# -ne 1 ] && fail "ERREUR SYNTAXE verifier_trace"

     awk -v fichier="$1" '
    /perte/ { 
        if (getline nextLine && nextLine !~ /^E/) {
            print "FAIL"
            print "une ligne suivant une 'perte' ne commence pas par 'E'"
            print "Voir le fichier suivant : " fichier
            exit 1
        }
    }
    ' "$1"
}

# Chercher la commande "time" POSIX et la mettre dans la variable TIME
commande_time ()
{
    TIME=$(command -v -p time)
    if [ "$TIME" = "" ]
    then echo "Commande 'time' non trouvée" >&2  ; exit 1 ;
    fi
}

# récupère la durée en ms à partir de /usr/bin/time -p (POSIX)
# $1 = nom du fichier contenant le résultat de time -p
duree ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE duree"

    local fichier="$1"
    local duree_s

    duree_s=$(sed -n 's/real *//p' "$fichier" | sed 's/,/\./')
    echo "$duree_s*1000" | bc | sed 's/\..*//'
}

nettoyer()
{
    rm -rf $TMP*
}
