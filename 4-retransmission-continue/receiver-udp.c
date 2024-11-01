#include <netdb.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#define BUFSIZE 1024
#define MOD 8

#define CHK(op)                                                                \
  do {                                                                         \
    if ((op) == -1) {                                                          \
      perror(#op);                                                             \
      exit(1);                                                                 \
    }                                                                          \
  } while (0)

#define CHKA(op)                                                               \
  do {                                                                         \
    int error = 0;                                                             \
    if ((error = (op)) != 0) {                                                 \
      fprintf(stderr, #op " %s\n", gai_strerror(error));                       \
      exit(EXIT_FAILURE);                                                      \
    }                                                                          \
  } while (0)

noreturn void usage(const char *msg) {
  fprintf(stderr, "usage: %s port_local\n", msg);
  exit(EXIT_FAILURE);
}

struct content {
  unsigned int compteur;
  unsigned int nb_bytes;
  char buffer[BUFSIZE];
};

void copie(int src, int dst) {
  struct content msg;
  unsigned int compteur = 0;
  int compsize = sizeof(unsigned int);
  size_t nb_bytes_read;
  struct sockaddr_storage addr;
  socklen_t len = sizeof(addr);

  while ((nb_bytes_read = recvfrom(src, &msg, sizeof(msg), 0,
                                   (struct sockaddr *)&addr, &len)) > 0) {

    if (msg.compteur % 2 == compteur % 2) {
      printf("\n %ld \n", nb_bytes_read);
      CHK(write(dst, msg.buffer, msg.nb_bytes));
      unsigned int sendcompt = compteur + 1;
      CHK(sendto(src, &sendcompt, compsize, 0, (struct sockaddr *)&addr, len));
      compteur = (compteur + 1) % MOD;
    } else {
      CHK(sendto(src, &compteur, compsize, 0, (struct sockaddr *)&addr, len));
    }
  }

  return;
}

void quit(int signo) {
  (void)signo;
  exit(EXIT_SUCCESS);
}

struct addrinfo *config(const char *port) {
  struct addrinfo hints = {0};
  hints.ai_flags = AI_PASSIVE | AI_NUMERICHOST;
  hints.ai_family = AF_INET6;
  hints.ai_socktype = SOCK_DGRAM;
  hints.ai_protocol = IPPROTO_UDP;

  struct addrinfo *result;

  int err = getaddrinfo(NULL, port, &hints, &result);
  CHKA(err);

  return result;
}

int create_socket(const struct addrinfo *host) {
  int fdsock = socket(host->ai_family, host->ai_socktype, host->ai_protocol);

  CHK(fdsock);
  int value = 0;
  CHK(setsockopt(fdsock, IPPROTO_IPV6, IPV6_V6ONLY, &value, sizeof value));

  value = BUFSIZE * 8;
  CHK(setsockopt(fdsock, SOL_SOCKET, SO_RCVBUF, &value, sizeof value));

  return fdsock;
}

int main(int argc, char *argv[]) {
  if (argc != 2)
    usage(argv[0]);

  struct addrinfo *result = config(argv[1]);
  int fdsock = create_socket(result);
  CHK(bind(fdsock, result->ai_addr, result->ai_addrlen));
  freeaddrinfo(result);

  struct sigaction sa;
  sa.sa_handler = quit;
  CHK(sigemptyset(&sa.sa_mask));
  sa.sa_flags = 0;
  CHK(sigaction(SIGTERM, &sa, NULL));

  sigset_t mask;
  CHK(sigfillset(&mask));
  CHK(sigdelset(&mask, SIGTERM));
  CHK(sigprocmask(SIG_BLOCK, &mask, NULL));

  while (1) {
    copie(fdsock, STDOUT_FILENO);
  }

  CHK(sigprocmask(SIG_SETMASK, NULL, NULL));
  close(fdsock);

  return EXIT_SUCCESS;
}
