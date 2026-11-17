#define _POSIX_C_SOURCE 200809L

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static void fail(const char *operation, const char *path) {
  fprintf(stderr, "merge_modules: %s %s: %s\n", operation, path,
          strerror(errno));
  exit(1);
}

static char *join(const char *directory, const char *name) {
  size_t size = strlen(directory) + strlen(name) + 2;
  char *path = malloc(size);
  if (!path)
    fail("allocate path for", name);
  snprintf(path, size, "%s/%s", directory, name);
  return path;
}

static void make_directory(const char *path) {
  char *prefix = strdup(path);
  if (!prefix)
    fail("allocate path for", path);
  for (char *p = prefix + 1; *p; ++p) {
    if (*p == '/') {
      *p = '\0';
      if (mkdir(prefix, 0777) && errno != EEXIST)
        fail("create", prefix);
      *p = '/';
    }
  }
  if (mkdir(prefix, 0777) && errno != EEXIST)
    fail("create", prefix);
  free(prefix);
}

static void copy_file(const char *source, const char *destination) {
  int input = open(source, O_RDONLY);
  if (input < 0)
    fail("open", source);
  int output = open(destination, O_WRONLY | O_CREAT | O_EXCL, 0644);
  if (output < 0)
    fail("create module (duplicate name?)", destination);

  char buffer[16384];
  ssize_t count;
  while ((count = read(input, buffer, sizeof(buffer))) > 0) {
    for (ssize_t written = 0; written < count;) {
      ssize_t result = write(output, buffer + written, count - written);
      if (result <= 0)
        fail("write", destination);
      written += result;
    }
  }
  if (count < 0)
    fail("read", source);
  if (close(input))
    fail("close", source);
  if (close(output))
    fail("close", destination);
}

static void copy_modules(const char *source_directory,
                         const char *output_directory) {
  DIR *directory = opendir(source_directory);
  if (!directory)
    fail("open directory", source_directory);
  struct dirent *entry;
  while ((entry = readdir(directory))) {
    if (!strcmp(entry->d_name, ".") || !strcmp(entry->d_name, ".."))
      continue;
    char *source = join(source_directory, entry->d_name);
    char *destination = join(output_directory, entry->d_name);
    struct stat mode;
    if (stat(source, &mode))
      fail("stat", source);
    if (!S_ISREG(mode.st_mode)) {
      fprintf(stderr, "merge_modules: unexpected non-file module %s\n", source);
      exit(1);
    }
    copy_file(source, destination);
    free(source);
    free(destination);
  }
  if (closedir(directory))
    fail("close directory", source_directory);
}

int main(int argc, char **argv) {
  if (argc != 2 || argv[1][0] != '@') {
    fprintf(stderr, "merge_modules: expected one @parameter-file argument\n");
    return 1;
  }
  FILE *parameters = fopen(argv[1] + 1, "r");
  if (!parameters)
    fail("open", argv[1] + 1);

  char *line = NULL;
  size_t capacity = 0;
  if (getline(&line, &capacity, parameters) < 0) {
    fprintf(stderr, "merge_modules: missing output directory\n");
    return 1;
  }
  line[strcspn(line, "\r\n")] = '\0';
  char *output_directory = strdup(line);
  if (!output_directory)
    fail("allocate path for", line);
  make_directory(output_directory);
  while (getline(&line, &capacity, parameters) >= 0) {
    line[strcspn(line, "\r\n")] = '\0';
    copy_modules(line, output_directory);
  }
  if (ferror(parameters))
    fail("read", argv[1] + 1);
  if (fclose(parameters))
    fail("close", argv[1] + 1);
  free(output_directory);
  free(line);
  return 0;
}
