#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#include <fstream>
#include <string>

#ifdef _WIN32
#include <direct.h>
#include <io.h>
#endif

static void fail(const char *operation, const char *path) {
  fprintf(stderr, "merge_modules: %s %s: %s\n", operation, path,
          strerror(errno));
  exit(1);
}

static void create_directory(const char *path) {
#ifdef _WIN32
  int result = _mkdir(path);
#else
  int result = mkdir(path, 0777);
#endif
  if (result && errno != EEXIST)
    fail("create", path);
}

static void make_directory(const std::string &path) {
  for (size_t end = path.find('/', 1); end != std::string::npos;
       end = path.find('/', end + 1))
    create_directory(path.substr(0, end).c_str());
  create_directory(path.c_str());
}

static FILE *create_module(const char *path) {
#ifdef _WIN32
  int fd = _open(path, _O_WRONLY | _O_CREAT | _O_EXCL | _O_BINARY,
                 _S_IREAD | _S_IWRITE);
#else
  int fd = open(path, O_WRONLY | O_CREAT | O_EXCL, 0644);
#endif
  if (fd < 0)
    fail("create module (duplicate name?)", path);
#ifdef _WIN32
  FILE *file = _fdopen(fd, "wb");
#else
  FILE *file = fdopen(fd, "wb");
#endif
  if (!file)
    fail("open module stream", path);
  return file;
}

static void copy_file(const char *source, const char *destination) {
  FILE *input = fopen(source, "rb");
  if (!input)
    fail("open", source);
  FILE *output = create_module(destination);

  char buffer[16384];
  size_t count;
  while ((count = fread(buffer, 1, sizeof(buffer), input)) != 0)
    if (fwrite(buffer, 1, count, output) != count)
      fail("write", destination);
  if (ferror(input))
    fail("read", source);
  if (fclose(input))
    fail("close", source);
  if (fclose(output))
    fail("close", destination);
}

static bool read_path(std::ifstream &parameters, std::string &path) {
  if (!std::getline(parameters, path))
    return false;
  if (!path.empty() && path.back() == '\r')
    path.pop_back();
  return true;
}

int main(int argc, char **argv) {
  if (argc != 2 || argv[1][0] != '@') {
    fprintf(stderr, "merge_modules: expected one @parameter-file argument\n");
    return 1;
  }
  std::ifstream parameters(argv[1] + 1);
  if (!parameters)
    fail("open", argv[1] + 1);

  std::string output_directory;
  if (!read_path(parameters, output_directory)) {
    fprintf(stderr, "merge_modules: missing output directory\n");
    return 1;
  }
  make_directory(output_directory);
  std::string source;
  while (read_path(parameters, source)) {
    std::string name = source.substr(source.find_last_of('/') + 1);
    copy_file(source.c_str(), (output_directory + "/" + name).c_str());
  }
  if (!parameters.eof())
    fail("read", argv[1] + 1);
  return 0;
}
