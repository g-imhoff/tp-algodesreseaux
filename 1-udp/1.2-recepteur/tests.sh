#!/bin/sh

PROG=${PROG:=./receiver-udp}

# lire les variables et fonctions communes
. ../../test-inc.sh

#####################################################################
# Tests d'erreur sur les arguments
test_1()
{
    annoncer_test 1 "numéro de port invalide"
    nettoyer
    $PROG -1 > $TMP.out 2> $TMP.err && fail "code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    nettoyer
    echo OK
}

#####################################################################
# Tests d'erreur sur bind
test_2()
{
    annoncer_test 2 "adresse déjà utilisée"
    nettoyer
    local pid
    timeout 5 nc -6ul :: $PORT > /dev/null &
    pid=$!
    sleep 2
    lancer_timeout 5 $PROG $PORT
    verifier_stderr $TMP "Address already in use"
    wait $pid
    nettoyer
    echo OK
}

##############################################################################
# Test l'affichage en sortie
test_3()
{
    annoncer_test 3 "affichage du programme"
    nettoyer
    local lport pid r msg
    lport=$(($PORT + 1))
    timeout 5 $PROG $PORT > $TMP.out 2> $TMP.err &
    pid=$!
    sleep 2
    printf "hello world" | nc -4u -w1 $IP4 $PORT -p $lport
    wait $pid
    r=$?
    [ $r = 124 ]      && fail "Timeout de 5 sec dépassé"
    [ $r != 0 ]       && fail "code de retour du programme invalide"
    est_vide $TMP.err || fail "la sortie d'erreur doit être vide"
    est_vide $TMP.out && fail "aucune donnée reçue"
    msg=$(cat $TMP.out)
    comparer "$msg" "::ffff:127.0.0.1 $lport a envoyé : hello world"
    nettoyer
    echo OK
}

##############################################################################
# Test transmission en IPv6
test_4()
{
    annoncer_test 4 "transmission en IPv6"
    nettoyer
    local lport pid r msg
    lport=$(($PORT + 1))
    timeout 5 $PROG $PORT > $TMP.out 2> $TMP.err &
    pid=$!
    sleep 2
    printf "hello world" | nc -6u -w1 $IP6 $PORT -p $lport
    wait $pid
    r=$?
    [ $r = 124 ]      && fail "Timeout de 5 sec dépassé"
    [ $r != 0 ]       && fail "code de retour du programme invalide"
    est_vide $TMP.err || fail "la sortie d'erreur doit être vide"
    est_vide $TMP.out && fail "aucune donnée reçue"
    msg=$(cat $TMP.out)
    comparer "$msg" "::1 $lport a envoyé : hello world"
    nettoyer
    echo OK
}

##############################################################################
# Test valgrind
test_5()
{
    annoncer_test 5 "valgrind"

    local pid r
    valgrind \
	--leak-check=full \
	--errors-for-leak-kinds=all \
	--show-leak-kinds=all \
	--error-exitcode=100 \
	--log-file=$TMP.valgrind \
	$PROG $PORT > $TMP.out 2> $TMP.err &
    pid=$!
    sleep 2
    printf "hello world" | nc -4u -w1 $IP4 $PORT
    wait $pid
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
