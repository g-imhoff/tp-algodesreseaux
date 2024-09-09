#!/bin/sh

PROGS=${PROGS:=./sender-udp}
PROGR=${PROGR:=./receiver-udp}
MED=${MED:=./medium}

# lire les variables et fonctions communes
. ../test-inc.sh

#####################################################################
# Tests d'erreur sur les arguments
test_1()
{
    annoncer_test 1 "numéro de port invalide"
    nettoyer
    $PROGS -1 IP4 $PORT > $TMP.out 2> $TMP.err && fail "$PROGS code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    nettoyer
    $PROGS $PORT IP4 -1 > $TMP.out 2> $TMP.err && fail "$PROGS code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    nettoyer
    $PROGR -1 > $TMP.out 2> $TMP.err && fail "$PROGR code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    nettoyer
    $MED -1 $IP4 $PORT $IP4 $(($PORT+1)) 0 > $TMP.out 2> $TMP.err && fail "$MED code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    nettoyer
    $MED $PORT $IP4 -1 $IP4 $(($PORT+1)) 0 > $TMP.out 2> $TMP.err && fail "$MED code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    nettoyer
    $MED $PORT $IP4 $(($PORT+1)) $IP4 -1 0 > $TMP.out 2> $TMP.err && fail "$MED code retour du programme invalide"
    verifier_stderr $TMP "Servname not supported for ai_socktype"
    nettoyer
    echo OK
}

test_2()
{
    annoncer_test 2 "adresse IP invalide"
    nettoyer
    $PROGS $PORT a $(($PORT+1)) > $TMP.out 2> $TMP.err && fail "$PROGS code retour du programme invalide"
    verifier_stderr $TMP "Name or service not known"
    nettoyer
    $MED $PORT a $(($PORT+1)) $IP4 $(($PORT+2)) 0 > $TMP.out 2> $TMP.err && fail "$MED code retour du programme invalide"
    verifier_stderr $TMP "Name or service not known"
    nettoyer
    $MED $PORT $IP4 $(($PORT+1)) a $(($PORT+2)) 0 > $TMP.out 2> $TMP.err && fail "$MED code retour du programme invalide"
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
    timeout 4 nc -6ul :: $PORT > /dev/null &
    pid=$!
    sleep 2
    lancer_timeout 1 $PROGS $PORT $IP4 $(($PORT+1))
    verifier_stderr $TMP "Address already in use"
    wait $pid
    nettoyer
    timeout 4 nc -6ul :: $PORT > /dev/null &
    pid=$!
    sleep 2
    lancer_timeout 1 $PROGR $PORT
    verifier_stderr $TMP "Address already in use"
    wait $pid
    nettoyer
    timeout 4 nc -6ul :: $PORT > /dev/null &
    pid=$!
    sleep 2
    lancer_timeout 1 $MED $PORT $IP4 $(($PORT+1)) $IP4 $(($PORT+2)) 0
    verifier_stderr $TMP "Address already in use"
    wait $pid
    nettoyer
    echo OK
}

##############################################################################
# Transmission sans perte
test_4()
{
    annoncer_test 4 "transmission sans perte"
    nettoyer
    local pid_r pid_m
    generer_fichier_aleatoire $TMP.in 1

    for i in $(seq 0 7); do
        seq=$(($i % 2))
        echo "E->R, seq=$seq -> transmis" >> $TMP.trace
        echo "R->E, seq=$seq -> transmis" >> $TMP.trace
    done

    $PROGR $(($PORT)) > $TMP.out.rec 2> $TMP.err.rec &
    pid_r=$!
    $MED $(($PORT+2)) $IP4 $(($PORT+1)) $IP4 $(($PORT)) 0 > $TMP.out.med 2> $TMP.err.med &
    pid_m=$!
    sleep 2
    $PROGS $(($PORT+1)) $IP4 $(($PORT+2)) < $TMP.in > $TMP.out.send 2> $TMP.err.send
    sleep 1
    kill $pid_m $pid_r
    est_vide $TMP.err.rec  || fail "$PROGR la sortie d'erreur doit être vide"
    est_vide $TMP.err.send || fail "$PROGS la sortie d'erreur doit être vide"
    est_vide $TMP.err.med  || fail "$MED la sortie d'erreur doit être vide"
    est_vide $TMP.out.rec  && fail "$PROGR aucune donnée reçue"
    cmp $TMP.in $TMP.out.rec > $TMP.diff    || fail "les données reçues sont différentes des données envoyées"
    cmp $TMP.out.med $TMP.trace > $TMP.diff || fail "la trace produite par $MED ne correspond pas au scénario attendu"
    nettoyer
    echo OK
}

##############################################################################
# Transmission avec perte
test_5()
{
    annoncer_test 5 "transmission avec perte"
    nettoyer
    local pid_r pid_m
    generer_fichier_aleatoire $TMP.in 1
    $PROGR $(($PORT)) > $TMP.out.rec 2> $TMP.err.rec &
    pid_r=$!
    $MED $(($PORT+2)) $IP4 $(($PORT+1)) $IP4 $(($PORT)) 0.3 > $TMP.out.med 2> $TMP.err.med &
    pid_m=$!
    sleep 2
    $PROGS $(($PORT+1)) $IP4 $(($PORT+2)) < $TMP.in > $TMP.out.send 2> $TMP.err.send
    sleep 1
    kill $pid_m $pid_r
    est_vide $TMP.err.rec  || fail "$PROGR la sortie d'erreur doit être vide"
    est_vide $TMP.err.send || fail "$PROGS la sortie d'erreur doit être vide"
    est_vide $TMP.err.med  || fail "$MED la sortie d'erreur doit être vide"
    est_vide $TMP.out.rec  && fail "$PROGR aucune donnée reçue"
    cmp $TMP.in $TMP.out.rec > $TMP.diff    || fail "les données reçues sont différentes des données envoyées"
    verifier_trace $TMP.out.med || exit 1
    nettoyer
    echo OK
}


##############################################################################
# Test transmission en IPv6
test_6()
{
    annoncer_test 6 "transmission IPv6"
    nettoyer
    local pid_r pid_m
    generer_fichier_aleatoire $TMP.in 1
    $PROGR $(($PORT)) > $TMP.out.rec 2> $TMP.err.rec &
    pid_r=$!
    $MED $(($PORT+2)) $IP6 $(($PORT+1)) $IP6 $(($PORT)) 0.3 > $TMP.out.med 2> $TMP.err.med &
    pid_m=$!
    sleep 2
    $PROGS $(($PORT+1)) $IP6 $(($PORT+2)) < $TMP.in > $TMP.out.send 2> $TMP.err.send
    sleep 1
    kill $pid_m $pid_r
    est_vide $TMP.err.rec  || fail "$PROGR la sortie d'erreur doit être vide"
    est_vide $TMP.err.send || fail "$PROGS la sortie d'erreur doit être vide"
    est_vide $TMP.err.med  || fail "$MED la sortie d'erreur doit être vide"
    est_vide $TMP.out.rec  && fail "$PROGR aucune donnée reçue"
    cmp $TMP.in $TMP.out.rec > $TMP.diff    || fail "les données reçues sont différentes des données envoyées"
    verifier_trace $TMP.out.med || exit 1
    nettoyer
    echo OK
}

##############################################################################
# Test valgrind
test_7()
{
    annoncer_test 7 "valgrind"

    local pid_r pid_m r
    generer_fichier_aleatoire $TMP.in 1
    valgrind \
	--leak-check=full \
	--errors-for-leak-kinds=all \
	--show-leak-kinds=all \
	--error-exitcode=100 \
	--log-file=$TMP.valgrind_r \
	$PROGR $PORT > $TMP.out.rec 2> $TMP.err.rec &
    pid_r=$!
    valgrind \
	--leak-check=full \
	--errors-for-leak-kinds=all \
	--show-leak-kinds=all \
	--error-exitcode=100 \
	--log-file=$TMP.valgrind_m \
	$MED $(($PORT+2)) $IP4 $(($PORT+1)) $IP4 $(($PORT)) 0.3 > $TMP.out.med 2> $TMP.err.med &
    pid_m=$!
    sleep 2
    tester_valgrind $PROGS $(($PORT+1)) $IP4 $(($PORT+2)) < $TMP.in
    sleep 2
    kill $pid_m $pid_r
    wait $pid_m
    r=$?
    [ $r = 100 ] && fail "pb mémoire (cf $TMP.valgrind_m)"
    [ $r != 0 ]  && fail "erreur programme (code=$r) avec valgrind (cf $TMP.*)"
    wait $pid_r
    r=$?
    [ $r = 100 ] && fail "pb mémoire (cf $TMP.valgrind_r)"
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
    7) test_7 ;;
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

#nettoyer
echo "Tests ok"
exit 0
