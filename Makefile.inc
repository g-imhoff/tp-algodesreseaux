#
# Ce fichier est destiné à être inclus par les fichiers Makefile
# des exercices, avec comme répertoire courant le répertoire de
# chaque exercice.
#

# Sources C (un ou plusieurs)
C	= $(wildcard *.c)

# Le nom de l'exécutable à construire par défaut dérive des noms des sources C
EXE	= $(C:%.c=%)

# Options par défaut pour tous les exécutables
# (note : --std=c11 refuse les barrières)
CFLAGS	:= -g -Wall -Wextra -Werror -pedantic

TEST	= tests.sh

all::	$(EXE)

test:	all
	sh $(TEST)

# Règle générique pour exécuter un test spécifique
test%:	all
	@sh $(TEST) $(subst test,,$@)

.PHONY:	clean
clean::
	rm -f $(EXE)
