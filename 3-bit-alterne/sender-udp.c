#include <asm-generic/socket.h>
#include <bits/types/struct_iovec.h>
#include <errno.h>
#include <netdb.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#define BUFSIZE 1024
#define MOD 2

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
  fprintf(stderr, "usage: %s port_local ip_dest port_dest\n", msg);
  exit(EXIT_FAILURE);
}

struct content {
  unsigned int compteur;
  char buffer[BUFSIZE];
};

void copie(int src, int dst) {
  int compsize = sizeof(unsigned int);
  struct content msg = {0};
  size_t nb_bytes_read = -1;

  while ((nb_bytes_read = read(src, msg.buffer, (size_t)BUFSIZE)) > 0) {
    CHK(write(dst, &msg, nb_bytes_read + compsize));

    unsigned int ack = -1;
    while ((read(dst, &ack, sizeof(unsigned int)) == -1 && errno == EAGAIN) ||
           msg.compteur != ack) {
      CHK(write(dst, &msg, nb_bytes_read + compsize));
    }

    printf("\n got ack %d\n", msg.compteur);
    msg.compteur = (msg.compteur + 1) % MOD;
  }

  CHK((int)nb_bytes_read);
}

struct addrinfo *config(const char *host, const char *port, bool local) {
  struct addrinfo hints = {0};
  hints.ai_socktype = SOCK_DGRAM;

  if (local) {
    hints.ai_flags = AI_NUMERICSERV | AI_PASSIVE;
    hints.ai_family = AF_INET6;
  } else {
    hints.ai_flags = AI_NUMERICSERV | AI_NUMERICHOST;
    hints.ai_family = AF_UNSPEC;
  }

  struct addrinfo *result;
  CHKA(getaddrinfo(host, port, &hints, &result));

  return result;
}

int create_socket() {
  int sockfd = socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP);
  CHK(sockfd);
  int value = 0;
  CHK(setsockopt(sockfd, IPPROTO_IPV6, IPV6_V6ONLY, &value, sizeof value));

  return sockfd;
}

int main(int argc, char *argv[]) {
  if (argc != 4)
    usage(argv[0]);

  int sockfd = create_socket();
  struct addrinfo *local = config(NULL, argv[1], true);
  CHK(bind(sockfd, local->ai_addr, local->ai_addrlen));
  freeaddrinfo(local);

  struct timeval tv = {10, 0};
  CHK(setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, (struct timeval *)&tv,
                 sizeof(struct timeval)));

  struct addrinfo *dest = config(argv[2], argv[3], false);
  CHK(connect(sockfd, dest->ai_addr, dest->ai_addrlen));
  freeaddrinfo(dest);

  copie(STDIN_FILENO, sockfd);

  close(sockfd);
  return 0;
}
