# Patches author: weishu <twsxtd@gmail.com>
# Shell authon: xiaoleGun <1592501605@qq.com>
# 20240107

# fs/ changes
## exec.c
if [ -z "$(grep "ksu" fs/exec.c)" ]; then
    sed -i '/static int do_execveat_common/i\extern bool ksu_execveat_hook __read_mostly;\nextern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,\n                        void *envp, int *flags);\nextern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename_ptr,\n                         void *argv, void *envp, int *flags);' fs/exec.c
    if grep -q "return __do_execve_file(fd, filename, argv, envp, flags, NULL);" fs/exec.c; then
        sed -i '/return __do_execve_file(fd, filename, argv, envp, flags, NULL);/i\    if (unlikely(ksu_execveat_hook))\n        ksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);\n    else\n        ksu_handle_execveat_sucompat(&fd, &filename, &argv, &envp, &flags);' fs/exec.c
    else
        sed -i '/if (IS_ERR(filename))/i\    if (unlikely(ksu_execveat_hook))\n        ksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);\n    else\n        ksu_handle_execveat_sucompat(&fd, &filename, &argv, &envp, &flags);\n' fs/exec.c
    fi
fi

## open.c
if [ -z "$(grep "ksu" fs/open.c)" ]; then
    if grep -q "long do_faccessat(int dfd, const char __user \*filename, int mode)" fs/open.c; then
        sed -i '/long do_faccessat(int dfd, const char __user \*filename, int mode)/i\extern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,\n			 int *flags);' fs/open.c
    else
        sed -i '/SYSCALL_DEFINE3(faccessat, int, dfd, const char __user \*, filename, int, mode)/i\extern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,\n			 int *flags);' fs/open.c
    fi
    sed -i '/if (mode & ~S_IRWXO)/i\    ksu_handle_faccessat(&dfd, &filename, &mode, NULL);\n' fs/open.c
fi

## read_write.c
if [ -z "$(grep "ksu" fs/read_write.c)" ]; then
    sed -i '/ssize_t vfs_read(struct file/i\extern bool ksu_vfs_read_hook __read_mostly;\nextern int ksu_handle_vfs_read(struct file **file_ptr, char __user **buf_ptr,\n        size_t *count_ptr, loff_t **pos);' fs/read_write.c
    sed -i '/if (unlikely(!access_ok(VERIFY_WRITE, buf, count)))/i\    if (unlikely(ksu_vfs_read_hook))\n        ksu_handle_vfs_read(&file, &buf, &count, &pos);' fs/read_write.c
fi

## stat.c
if [ -z "$(grep "ksu" fs/stat.c)" ]; then
    if grep -q "int vfs_statx(int dfd, const char __user \*filename, int flags," fs/stat.c; then
        sed -i '/int vfs_statx(int dfd, const char __user \*filename, int flags,/i\extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);' fs/stat.c
        sed -i '/unsigned int lookup_flags = LOOKUP_FOLLOW | LOOKUP_AUTOMOUNT;/a\\n    ksu_handle_stat(&dfd, &filename, &flags);' fs/stat.c
    else
        sed -i '/int vfs_fstatat(int dfd, const char __user \*filename, struct kstat *stat,/i\extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);' fs/stat.c
        sed -i '/if ((flag & ~(AT_SYMLINK_NOFOLLOW | AT_NO_AUTOMOUNT |/i\\n    ksu_handle_stat(&dfd, &filename, &flag);\n' fs/stat.c
    fi
fi

# drivers/input changes
## input.c
if [ -z "$(grep "ksu" drivers/input/input.c)" ]; then
    sed -i '/static void input_handle_event/i\extern bool ksu_input_hook __read_mostly;\nextern int ksu_handle_input_handle_event(unsigned int *type, unsigned int *code, int *value);' drivers/input/input.c
    sed -i '/if (disposition != INPUT_IGNORE_EVENT && type != EV_SYN)/i\    if (unlikely(ksu_input_hook))\n        ksu_handle_input_handle_event(&type, &code, &value);' drivers/input/input.c
fi

echo "Patch kernel is ok"
