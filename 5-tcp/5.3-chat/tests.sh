#!/bin/sh

PROGS=${PROGS:=./serveur-tcp}
PROGC=${PROGC:=./client-tcp}

# lire les variables et fonctions communes
. ../../test-inc.sh

#####################################################################
# Tests d'erreur sur les arguments
test_1()
{
    annoncer_test 1 "numéro de port invalide"
    nettoyer
    $PROGS -1 > $TMP.out 2> $TMP.err && fail "code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    nettoyer
    $PROGC $IP4 -1 > $TMP.out 2> $TMP.err && fail "code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    echo OK
}

test_2()
{
    annoncer_test 2 "adresse invalide"
    $PROGC a $PORT > $TMP.out 2> $TMP.err && fail "code retour du programme invalide"
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
    timeout 5 nc -6l :: $PORT > /dev/null &
    pid=$!
    sleep 2
    lancer_timeout 5 $PROGS $PORT
    verifier_stderr $TMP "Address already in use"
    wait $pid
    nettoyer
    echo OK
}

##############################################################################
# Test diffusion d'un message
test_4()
{
    annoncer_test 4 "diffusion d'un message"
    nettoyer
    local r msg pid1 pid2 pid3
    timeout 10 $PROGS $PORT < /dev/null > $TMP.out 2> $TMP.err &
    pid1=$!
    sleep 2
    mkfifo $TMP.input
    cat $TMP.input | $PROGC $IP6 $PORT > $TMP.out2 2> $TMP.err2 &
    pid3=$!
    sleep 2
    printf "hello world" | nc -w1 -4 $IP4 $PORT
    sleep 2
    printf "hello world" > $TMP.input
    sleep 2
    wait $pid1
    r=$?
    [ $r = 124 ]       && fail "Timeout de 10 sec dépassé"
    [ $r != 0 ]        && fail "code de retour du programme invalide"
    est_vide $TMP.err  || fail "$PROGS la sortie d'erreur doit être vide"
    est_vide $TMP.out  && fail "aucune donnée reçue sur le serveur"
    est_vide $TMP.out2 && fail "aucune donnée reçue sur le client"
    msg=$(cat $TMP.out)
    comparer "$msg" "hello worldhello world"
    msg=$(cat $TMP.out2)
    comparer "$msg" "hello world"
    nettoyer
    echo OK
}

##############################################################################
# Test limite MAX du nombre de clients
test_5()
{
    annoncer_test 5 "limite du nombre de clients"
    nettoyer
    local pid
    $PROGS $PORT < /dev/null > /dev/null 2> $TMP.err &
    pid=$!
    sleep 2
    mkfifo $TMP.input
    cat $TMP.input | $PROGC $IP6 $PORT > /dev/null 2>&1 &
    cat $TMP.input | $PROGC $IP6 $PORT > /dev/null 2>&1 &
    timeout 2 $PROGC $IP6 $PORT
    r=$?
    printf "hello world" > $TMP.input
    [ $r = 124 ]      && fail "client supplémentaire ne s'arrête pas"
    [ $r != 0 ]       && fail "code de retour du programme invalide"
    wait $pid 2> /dev/null
    est_vide $TMP.err && fail "$PROGS la sortie d'erreur ne doit pas être vide"
    nettoyer
    echo OK
}

##############################################################################
# Test valgrind
test_6()
{
    annoncer_test 6 "valgrind"
    nettoyer
    local pid r
    valgrind \
    --leak-check=full \
    --errors-for-leak-kinds=all \
    --show-leak-kinds=all \
    --error-exitcode=100 \
    --log-file=$TMP.valgrind \
    $PROGS $PORT < /dev/null > $TMP.out 2> $TMP.err &
    pid=$!
    sleep 2
    printf "hello world" | nc -w1 -4 $IP4 $PORT
    wait $pid
    r=$?
    [ $r = 100 ] && fail "$PROGS pb mémoire (cf $TMP.valgrind)"
    [ $r != 0 ]  && fail "$PROGS erreur programme (code=$r) avec valgrind (cf $TMP.*)"
    nettoyer
    $PROGS $PORT < /dev/null > $TMP.out 2> $TMP.err &
    pid=$!
    valgrind \
    --leak-check=full \
    --errors-for-leak-kinds=all \
    --show-leak-kinds=all \
    --error-exitcode=100 \
    --log-file=$TMP.valgrind \
    $PROGC $IP6 $PORT < README.md > $TMP.out 2> $TMP.err
    r=$?
    [ $r = 100 ] && fail "$PROGC pb mémoire (cf $TMP.valgrind)"
    [ $r != 0 ]  && fail "$PROGC erreur programme (code=$r) avec valgrind (cf $TMP.*)"
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
