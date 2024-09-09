#!/bin/sh

PROGS=${PROGS:=./sender-udp}
PROGR=${PROGR:=./receiver-udp}
MED=${MED:=./medium}

# lire les variables et fonctions communes
. ../test-inc.sh

# chercher la commande "time" POSIX et la mettre dans la variable TIME
commande_time

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
    echo OK
}

test_2()
{
    annoncer_test 2 "adresse IP invalide"
    nettoyer
    $PROGS $PORT a $(($PORT+1)) > $TMP.out 2> $TMP.err && fail "$PROGS code retour du programme invalide"
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

    $PROGR $(($PORT)) > $TMP.out.rec 2> /dev/null &
    pid_r=$!
    $MED $(($PORT+2)) $IP4 $(($PORT+1)) $IP4 $(($PORT)) 0 > $TMP.out.med 2> /dev/null &
    pid_m=$!
    sleep 2
    lancer_timeout 4 "$PROGS $(($PORT+1)) $IP4 $(($PORT+2)) < $TMP.in"
    sleep 1
    kill $pid_m $pid_r
    wait $pid_m ; wait $pid_r
    est_vide $TMP.err                    || fail "$PROGS la sortie d'erreur doit être vide"
    est_vide $TMP.out.rec                && fail "$PROGR aucune donnée reçue"
    cmp $TMP.in $TMP.out.rec > $TMP.diff || fail "les données reçues sont différentes des données envoyées"
    nettoyer
    echo OK
}

##############################################################################
# Transmission avec perte
test_5()
{
    annoncer_test 5 "transmission avec pertes"
    nettoyer
    local pid_r pid_m
    generer_fichier_aleatoire $TMP.in 1
    $PROGR $(($PORT)) > $TMP.out.rec 2> /dev/null &
    pid_r=$!
    $MED $(($PORT+2)) $IP6 $(($PORT+1)) $IP6 $(($PORT)) 0.3 > $TMP.out.med 2> /dev/null &
    pid_m=$!
    sleep 2
    lancer_timeout 15 "$PROGS $(($PORT+1)) $IP6 $(($PORT+2)) < $TMP.in"
    sleep 1
    kill $pid_m $pid_r
    est_vide $TMP.err                    || fail "$PROGS la sortie d'erreur doit être vide"
    est_vide $TMP.out.rec                && fail "$PROGR aucune donnée reçue"
    cmp $TMP.in $TMP.out.rec > $TMP.diff || fail "les données reçues sont différentes des données envoyées"
    nettoyer
    echo OK
}

##############################################################################
# Test temps de transmission
test_6()
{
    annoncer_test 6 "temps de transmission"
    nettoyer
    local t pid_r pid_m
    generer_fichier_aleatoire $TMP.in 2
    $PROGR $(($PORT)) > /dev/null 2>&1 &
    pid_r=$!
    $MED $(($PORT+2)) $IP6 $(($PORT+1)) $IP6 $(($PORT)) 0.2 > /dev/null 2>&1 &
    pid_m=$!
    sleep 2
    $TIME -p $PROGS $(($PORT+1)) $IP6 $(($PORT+2)) < $TMP.in > /dev/null 2> $TMP.time
    sleep 1
    kill $pid_m $pid_r
    wait $pid_m ; wait $pid_r
    t=$(duree $TMP.time)
    [ $t -ge 15000 ] && fail "la transmission est trop lente : pb avec la fenêtre d'émission ?"
    nettoyer
    echo OK
}

##############################################################################
# Test valgrind
test_7()
{
    annoncer_test 7 "valgrind"
    nettoyer
    local pid_r pid_m r
    generer_fichier_aleatoire $TMP.in 2
	$PROGR $PORT > /dev/null 2>&1 &
    pid_r=$!
	$MED $(($PORT+2)) $IP6 $(($PORT+1)) $IP6 $(($PORT)) 0.3 > /dev/null 2>&1 &
    pid_m=$!
    sleep 2
    valgrind \
	--leak-check=full \
	--errors-for-leak-kinds=all \
	--show-leak-kinds=all \
	--error-exitcode=100 \
	--log-file=$TMP.valgrind \
	$PROGS $(($PORT+1)) $IP6 $(($PORT+2)) < $TMP.in > /dev/null 2> $TMP.err
    r=$?
    kill $pid_m $pid_r
    wait $pid_m ; wait $pid_r
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
    7) test_7 ;;
    *) echo "Test non reconnu : $1" ; exit 1 ;;
    esac
}

# Si un argument est passé, exécute le test correspondant
if [ $# -eq 1 ]; then
    run_test $1
else
    for test_func in $(grep -E '^test_[0-9]+\(\)$' tests.sh | sed s/\(\)//g); do
        $test_func
    done
fi

echo "Tests ok"
exit 0
