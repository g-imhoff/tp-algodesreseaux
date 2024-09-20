#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
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
  fprintf(stderr, "usage: %s port_dest\n", msg);
  exit(EXIT_FAILURE);
}

struct addrinfo *config(const char *port) {
  struct addrinfo hints;
  hints.ai_flags = AI_PASSIVE;
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_DGRAM;
  hints.ai_protocol = IPPROTO_UDP;

  struct addrinfo *result;

  int err = getaddrinfo(NULL, port, &hints, &result);
  CHKA(err);

  return result;
}

int create_socket(struct addrinfo *host) {
  int fdsock = socket(host->ai_family, host->ai_socktype, host->ai_protocol);
  CHK(fdsock);

  int value = 0;
  CHK(setsockopt(fdsock, IPPROTO_IPV6, IPV6_V6ONLY, &value, sizeof value));

  return fdsock;
}

int main(int argc, char *argv[]) {
  if (argc != 2)
    usage(argv[0]);

  struct addrinfo *result = config(argv[1]);
  int fdsock = create_socket(result);
  CHK(bind(fdsock, result->ai_addr, result->ai_addrlen));
  char buffer[1024];
  socklen_t fromlen;
  struct sockaddr from;
  ssize_t size = recvfrom(fdsock, buffer, 1024, 0, &from, &fromlen);
  CHK(size);

  return 0;
}
