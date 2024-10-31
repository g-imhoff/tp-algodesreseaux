#include <bits/types/struct_iovec.h>
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

void copie(int src, int dst) {
  char buffer[BUFSIZE] = {0};
  size_t nb_bytes_read;

  if ((nb_bytes_read = read(src, buffer, (size_t)BUFSIZE)) > 0) {
    CHK(write(dst, buffer, nb_bytes_read));
  }

  while ((nb_bytes_read = read(src, buffer, (size_t)BUFSIZE)) > 0) {
    CHK(write(dst, buffer, nb_bytes_read));

    char ack;
    CHK(read(dst, &ack, 1));

    if (ack != 'A') {
      fprintf(stderr, "Error: Invalid acknowledgment\n");
      exit(1);
    } else {
      printf("\n got ack\n");
    }
  }

  CHK((int)nb_bytes_read);
}

struct addrinfo *config(const char *host, const char *port, bool local) {
  struct addrinfo hints;
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
  // création d'un socket IPv6 qui accepte les communications IPv4
  int sockfd, value = 0;
  CHK(sockfd = socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP));
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

  struct addrinfo *dest = config(argv[2], argv[3], false);
  CHK(connect(sockfd, dest->ai_addr, dest->ai_addrlen));
  freeaddrinfo(dest);

  copie(STDIN_FILENO, sockfd);

  close(sockfd);
  return 0;
}
