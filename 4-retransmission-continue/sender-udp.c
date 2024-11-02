#include <asm-generic/socket.h>
#include <bits/types/struct_iovec.h>
#include <errno.h>
#include <netdb.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#define BUFSIZE 1024
#define MOD 8
#define WNDSIZE 4 // MOD doit être au moins égal à WNDSIZE

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

// struct
struct content {
  unsigned int compteur;
  unsigned int nb_bytes;
  char buffer[BUFSIZE];
};

struct ll_node {
  struct content message;
  struct ll_node *next;
};

struct ll_content {
  unsigned int max_length;
  unsigned int lenght;
  struct ll_node *head;
};

// code node
struct ll_node *node_init() { return (struct ll_node *)NULL; }

struct ll_node *node_add(struct ll_node *head, struct ll_node *next) {
  if (head == NULL) {
    return next;
  }

  struct ll_node *tmp = head;

  while (tmp->next != NULL) {
    tmp = tmp->next;
  }

  tmp->next = next;
  return head;
}

void node_free(struct ll_node *node) { free(node); }

struct ll_node *node_del(struct ll_node *head, unsigned int pos) {
  if (pos == 0) {
    struct ll_node *next = head->next;
    node_free(head);
    return next;
  }
  struct ll_node *tmp = head;

  for (unsigned int i = 0; i == pos - 1; tmp = tmp->next, i++)
    ;

  struct ll_node *del = tmp->next;
  struct ll_node *next = del->next;
  tmp->next = next;
  node_free(del);

  return head;
}

// code ll
struct ll_content ll_init() {
  struct ll_content result = {0};
  result.max_length = WNDSIZE;
  result.head = node_init();
  result.lenght = 0;

  return result;
}

struct ll_content ll_add(struct ll_content msg, int compteur,
                         char buffer[BUFSIZE], size_t nb_bytes_read) {
  if (msg.lenght >= msg.max_length) {
    printf("wndsize excess");
  }

  msg.lenght++;

  struct ll_node *next = malloc(sizeof(struct ll_node));
  next->message.compteur = compteur;
  next->message.nb_bytes = nb_bytes_read;
  next->next = NULL;

  for (unsigned int i = 0; i < nb_bytes_read; i++) {
    next->message.buffer[i] = buffer[i];
  }

  if (nb_bytes_read < BUFSIZE) {
    next->message.buffer[nb_bytes_read] = '\0';
  }

  msg.head = node_add(msg.head, next);

  return msg;
}

struct ll_content ll_del(struct ll_content msg, unsigned int pos) {
  if (msg.lenght < pos) {
    printf("deleting an node not existing");
    exit(EXIT_FAILURE);
  }
  msg.head = node_del(msg.head, pos);
  msg.lenght--;
  return msg;
}

struct ll_content ll_delunder(struct ll_content msg, unsigned int ack) {
  unsigned int i = 0;
  struct ll_node *head = msg.head;

  for (struct ll_node *tmp = head; tmp != NULL; tmp = tmp->next) {
    if (tmp->message.compteur < ack) {
      msg = ll_del(msg, i);
    } else {
      i++;
    }
  }

  if (msg.lenght == 0)
    msg.head = NULL;

  return msg;
}

bool ll_isfull(struct ll_content msg) { return msg.lenght == msg.max_length; }

// code socket
void copie(int src, int dst) {
  unsigned int compteur = 0;
  struct ll_content msg = ll_init();
  size_t nb_bytes_read = 1;

  while (nb_bytes_read > 0) {
    while ((nb_bytes_read > 0) && !ll_isfull(msg)) {
      char buffer[BUFSIZE];
      nb_bytes_read = read(src, buffer, sizeof(buffer));
      if (nb_bytes_read > 0) {
        msg = ll_add(msg, compteur, buffer, nb_bytes_read);
        compteur = (compteur + 1) % MOD;
      }
    }

    if (nb_bytes_read > 0) {
      for (struct ll_node *tmp = msg.head; tmp != NULL; tmp = tmp->next) {
        CHK(write(dst, &tmp->message,
                  tmp->message.nb_bytes + (2 * sizeof(unsigned int))));
      }

      unsigned int ack = -1;
      while (read(dst, &ack, sizeof(unsigned int)) == -1 && errno == EAGAIN) {
        for (struct ll_node *tmp = msg.head; tmp != NULL; tmp = tmp->next) {
          CHK(write(dst, &tmp->message,
                    tmp->message.nb_bytes + (2 * sizeof(unsigned int))));
        }
      }

      do {
        msg = ll_delunder(msg, ack);
      } while (read(dst, &ack, sizeof(unsigned int)) > 0);
    }
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

  // struct ll_content msg = ll_init();
  // msg = ll_add(msg, 0, "je suis 0");
  // msg = ll_add(msg, 1, "je suis 1");
  // msg = ll_add(msg, 2, "je suis 2");
  // msg = ll_add(msg, 3, "je suis 3");
  // msg = ll_delunder(msg, 1);
  // msg = ll_delunder(msg, 2);
  // msg = ll_delunder(msg, 3);
  // msg = ll_delunder(msg, 4);
  // msg = ll_add(msg, 4, "je suis 4");
  // msg = ll_add(msg, 5, "je suis 5");
  // msg = ll_add(msg, 6, "je suis 6");
  // msg = ll_add(msg, 7, "je suis 7");
  // msg = ll_delunder(msg, 5);
  // msg = ll_delunder(msg, 6);
  // msg = ll_delunder(msg, 7);
  // msg = ll_delunder(msg, 8);
  // msg = ll_add(msg, 0, "je suis 0");
  // msg = ll_add(msg, 1, "je suis 1");
  //
  // if (msg.head == NULL) {
  //   printf("tmp est NULL");
  // } else {
  //   for (struct ll_node *tmp = msg.head; tmp != NULL; tmp = tmp->next)
  //     printf("%s\n", tmp->message.buffer);
  // }

  int sockfd = create_socket();
  struct addrinfo *local = config(NULL, argv[1], true);
  CHK(bind(sockfd, local->ai_addr, local->ai_addrlen));
  freeaddrinfo(local);

  struct timeval tv = {0, 500};
  CHK(setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, (struct timeval *)&tv,
                 sizeof(struct timeval)));

  struct addrinfo *dest = config(argv[2], argv[3], false);
  CHK(connect(sockfd, dest->ai_addr, dest->ai_addrlen));
  freeaddrinfo(dest);

  copie(STDIN_FILENO, sockfd);

  close(sockfd);
  return 0;
}
