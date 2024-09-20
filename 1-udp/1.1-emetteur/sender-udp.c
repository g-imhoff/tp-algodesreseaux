#include <netdb.h>
#include <netinet/in.h>
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
  fprintf(stderr, "usage: %s ip_dest port_dest\n", msg);
  exit(EXIT_FAILURE);
}

struct addrinfo *config(const char *host, const char *port) {
  struct addrinfo hints = {0};
  hints.ai_flags = 0;
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_DGRAM;
  hints.ai_protocol = IPPROTO_UDP;

  struct addrinfo *result = NULL;

  int err = getaddrinfo(host, port, &hints, &result);
  CHKA(err);

  return result;
}

int create_socket(struct addrinfo *host) {
  int fdsock = socket(host->ai_family, host->ai_socktype, host->ai_protocol);
  CHKA(fdsock);

  return fdsock;
}

int main(int argc, char *argv[]) {
  if (argc != 3)
    usage(argv[0]);

  struct addrinfo *host = config(argv[1], argv[2]);
  int fdsock = create_socket(host);

  char buff[12] = "hello world";
  int err =
      sendto(fdsock, buff, sizeof(buff), 0, host->ai_addr, host->ai_addrlen);
  CHKA(err);

  freeaddrinfo(host);
  close(fdsock);

  return EXIT_SUCCESS;
}
