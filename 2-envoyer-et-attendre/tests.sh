#!/bin/sh

PROGS=${PROGS:=./sender-udp}
PROGR=${PROGR:=./receiver-udp}

# lire les variables et fonctions communes
. ../test-inc.sh

#####################################################################
# Tests d'erreur sur les arguments
test_1()
{
    annoncer_test 1 "numéro de port invalide"
    nettoyer
    $PROGS $IP4 -1 > $TMP.out 2> $TMP.err && fail "$PROGS code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    nettoyer
    $PROGR -1 > $TMP.out 2> $TMP.err && fail "$PROGR code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    nettoyer
    echo OK
}

test_2()
{
    annoncer_test 2 "adresse IP invalide"
    nettoyer
    $PROGS a $PORT > $TMP.out 2> $TMP.err && fail "code retour du programme invalide"
    verifier_stderr $TMP "Name or service not known"
    nettoyer
    echo OK
}

#####################################################################
# Tests d'erreur sur bind
test_3()
{
    annoncer_test 3 "adresse déjà utilisée"
    nettoyer
    local pid
    timeout 5 nc -6ul :: $PORT > /dev/null &
    pid=$!
    sleep 2
    lancer_timeout 5 $PROGR $PORT
    verifier_stderr $TMP "Address already in use"
    wait $pid
    nettoyer
    echo OK
}

##############################################################################
# Transmission large quantité de données
test_4()
{
    annoncer_test 4 "transmission large quantité de données"
    nettoyer
    local pid
    generer_fichier_aleatoire $TMP.in 1
    $PROGR $PORT > $TMP.out.rec 2> $TMP.err.rec &
    pid=$!
    sleep 2
    $PROGS $IP4 $PORT < $TMP.in > $TMP.out.send 2> $TMP.err.send
    sleep 1
    kill $pid && wait $pid
    est_vide $TMP.err.send || fail "$PROGS la sortie d'erreur doit être vide"
    est_vide $TMP.err.rec  || fail "$PROGR la sortie d'erreur doit être vide"
    est_vide $TMP.out.rec  && fail "aucune donnée reçue"
    cmp $TMP.in $TMP.out.rec > $TMP.diff || fail "les données reçues sont différentes des données envoyées"
    nettoyer
    echo OK
}

##############################################################################
# Test transmission en IPv6
test_5()
{
    annoncer_test 5 "transmission IPv6"
    nettoyer
    local pid
    generer_fichier_aleatoire $TMP.in 1
    $PROGR $PORT > $TMP.out.rec 2> $TMP.err.rec &
    pid=$!
    sleep 2
    $PROGS $IP6 $PORT < $TMP.in > $TMP.out.send 2> $TMP.err.send || fail "$PROGS code retour du programme invalide"
    sleep 1
    kill $pid && wait $pid
    est_vide $TMP.err.send || fail "$PROGS la sortie d'erreur doit être vide"
    est_vide $TMP.err.rec  || fail "$PROGR la sortie d'erreur doit être vide"
    est_vide $TMP.out.rec  && fail "aucune donnée reçue"
    cmp $TMP.in $TMP.out.rec > $TMP.diff || fail "les données reçues sont différentes des données envoyées"
    nettoyer
    echo OK
}

##############################################################################
# Test valgrind
test_6()
{
    annoncer_test 6 "valgrind"

    local pid r
    generer_fichier_aleatoire $TMP.in 1
    valgrind \
	--leak-check=full \
	--errors-for-leak-kinds=all \
	--show-leak-kinds=all \
	--error-exitcode=100 \
	--log-file=$TMP.valgrind.rec \
	$PROGR $PORT < $TMP.in > $TMP.out.rec 2> $TMP.err.rec &
    pid=$!
    sleep 2
    tester_valgrind $PROGS $IP4 $PORT < $TMP.in
    sleep 1
    kill $pid && wait $pid
    r=$?
    [ $r = 100 ] && fail "pb mémoire (cf $TMP.valgrind)"
    [ $r != 0 ]  && fail "erreur programme (code=$r) avec valgrind (cf $TMP.*)"
    nettoyer
    echo OK
}

run_test()
{
    case $1 in
    1) test_1 ;;
    2) test_2 ;;
    3) test_3 ;;
    4) test_4 ;;
    5) test_5 ;;
    6) test_6 ;;
    *) echo "Test non reconnu : $1" ; exit 1 ;;
    esac
}

# Si un argument est passé, exécutez le test correspondant
if [ $# -eq 1 ]; then
    run_test $1
else
    for test_func in $(grep -E '^test_[0-9]+\(\)$' tests.sh | sed s/\(\)//g); do
        $test_func
    done
fi

nettoyer
echo "Tests ok"
exit 0
