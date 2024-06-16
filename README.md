# ssh_decode

* sudo cryptsetup luksFormat /dev/sdXn - creates a LUKS-container on a disk where /dev/sdXn - this is a disk or section that you want to encrypt
* sudo cryptsetup luksOpen /dev/sdXn disk_name - opening a encrypted container where disk_name is the name of a encrypted container
* sudo mkfs.ext4 /dev/mapper/disk_name - formates an open container in the desired file system where disk_name is the name of a encrypted container
* sudo mkdir /mnt/mount_directory - creates a mount directory
* disk_name /dev/sdXn - luks,noauto (this instruction must be written in the file /etc/crypttab)
* /dev/mapper/disk_name /mnt/mount_directory ext4 defaults,noauto 0 0 (this instruction must be written in the file /etc/fstab where mount_directory is the name of a mount file)