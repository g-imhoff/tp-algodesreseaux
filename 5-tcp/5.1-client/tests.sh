#!/bin/sh

PROG=${PROG:=./client-tcp}

# lire les variables et fonctions communes
. ../../test-inc.sh

#####################################################################
# Tests d'erreur sur les arguments
test_1()
{
    annoncer_test 1 "numéro de port invalide"
    nettoyer
    $PROG $IP4 -1 > $TMP.out 2> $TMP.err && fail "code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    nettoyer
    echo OK
}

test_2()
{
    annoncer_test 2 "adresse IP invalide"
    nettoyer
    $PROG a $PORT > $TMP.out 2> $TMP.err && fail "code retour du programme invalide"
    verifier_stderr $TMP "Name or service not known"
    nettoyer
    echo OK
}

test_3()
{
    annoncer_test 3 "connexion vers un hôte inexistant"
    nettoyer
    $PROG $IP4 $PORT > $TMP.out 2> $TMP.err && fail "code retour du programme invalide"
    verifier_stderr $TMP "Connection refused"
    nettoyer
    echo OK
}

##############################################################################
# Test le message reçu par un hôte IPv4
test_4()
{
    annoncer_test 4 "message envoyé"
    nettoyer
    local pid msg
    timeout 5 nc -4l $IP4 $PORT > $TMP.msg_r &
    pid=$!
    sleep 2
    $PROG $IP4 $PORT > $TMP.out 2> $TMP.err || fail "code retour du programme invalide"
    est_vide $TMP.err || fail "la sortie d'erreur doit être vide"
    est_vide $TMP.out || fail "la sortie standard doit être vide"
    wait $pid
    est_vide $TMP.msg_r && fail "aucune donnée reçue"
    msg=$(cat $TMP.msg_r)
    comparer "$msg" "hello world"
    nettoyer
    echo OK
}

##############################################################################
# Test transmission vers un hôte IPv6
test_5()
{
    annoncer_test 5 "transmission en IPv6"
    nettoyer
    local pid msg
    timeout 5 nc -6l $IP6 $PORT > $TMP.msg_r &
    pid=$!
    sleep 2
    $PROG $IP6 $PORT > $TMP.out 2> $TMP.err  || fail "code retour du programme invalide"
    est_vide $TMP.err || fail "la sortie d'erreur doit être vide"
    est_vide $TMP.out || fail "la sortie standard doit être vide"
    wait $pid
    est_vide $TMP.msg_r && fail "aucune donnée reçue"
    msg=$(cat $TMP.msg_r)
    comparer "$msg" "hello world"
    nettoyer
    echo OK
}

##############################################################################
# Test valgrind
test_6()
{
    annoncer_test 6 "valgrind"
    nettoyer
    local pid
    timeout 5 nc -4l $IP4 $PORT > $TMP.msg_r &
    pid=$!
    sleep 2
    tester_valgrind $PROG $IP4 $PORT
    wait $pid
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
