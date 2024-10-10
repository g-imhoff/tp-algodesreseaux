#include "udp.h"
#include <bits/types/struct_iovec.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

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
  fprintf(stderr, "usage: %s ip_dest port_dest\n", msg);
  exit(EXIT_FAILURE);
}

void copie(int src, int dst) {
  char buffer[BUFFERLEN_SEND] = {0};
  size_t nb_bytes_read;
  while ((nb_bytes_read = read(src, buffer, (size_t)BUFFERLEN_SEND)) > 0) {
    CHK(write(dst, buffer, nb_bytes_read));
  }

  CHK((int)nb_bytes_read);
}

struct addrinfo *config(const char *host, const char *port) {
  struct addrinfo hints;
  hints.ai_flags = AI_NUMERICSERV | AI_NUMERICHOST;
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_DGRAM;
  hints.ai_protocol = IPPROTO_UDP;

  struct addrinfo *result;

  CHKA(getaddrinfo(host, port, &hints, &result));

  return result;
}

int create_socket(struct addrinfo *host) {
  int fdsock = socket(host->ai_family, host->ai_socktype, host->ai_protocol);
  CHK(fdsock);

  return fdsock;
}

int main(int argc, char *argv[]) {
  if (argc != 3)
    usage(argv[0]);

  struct addrinfo *host = config(argv[1], argv[2]);
  int fdsock = create_socket(host);
  CHK(connect(fdsock, host->ai_addr, host->ai_addrlen));

  copie(STDIN_FILENO, fdsock);

  freeaddrinfo(host);
  close(fdsock);
  return 0;
}
