#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#define BUFFERLEN 1024
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

int create_socket(const struct addrinfo *host) {
  int fdsock = socket(host->ai_family, host->ai_socktype, host->ai_protocol);
  CHK(fdsock);

  int value = 0;
  CHK(setsockopt(fdsock, IPPROTO_IPV6, IPV6_V6ONLY, &value, sizeof value));

  return fdsock;
}

void receive_and_print(const int fdsock) {
  char buffer[BUFFERLEN];
  struct sockaddr_storage from; // To handle both IPv4 and IPv6 addresses
  socklen_t fromlen = sizeof(from);

  // Receive data from the client
  ssize_t size = recvfrom(fdsock, buffer, BUFFERLEN - 1, 0,
                          (struct sockaddr *)&from, &fromlen);
  CHK(size);
  buffer[size] = '\0'; // Null-terminate the received message

  // Get the sender's address and port
  char host[NI_MAXHOST], serv[NI_MAXSERV];
  int flags = NI_NUMERICHOST | NI_NUMERICSERV;
  CHKA(getnameinfo((struct sockaddr *)&from, fromlen, host, sizeof(host), serv,
                   sizeof(serv), flags));

  // Print the sender's IP, port, and the message
  printf("%s %s a envoyé : %s\n", host, serv, buffer);
}

int main(int argc, char *argv[]) {
  if (argc != 2)
    usage(argv[0]);

  struct addrinfo *result = config(argv[1]);

  int fdsock = create_socket(result);

  CHK(bind(fdsock, result->ai_addr, result->ai_addrlen));

  receive_and_print(fdsock);

  freeaddrinfo(result);
  close(fdsock);

  return 0;
}
