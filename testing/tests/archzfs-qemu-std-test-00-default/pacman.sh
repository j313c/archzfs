# Requires the pacman cache and pacman package repos be mounted via NFS
test_pacman_config() {
    # $1 arch-chroot target directory
    arch_target_dir=""
    arch_packages="${test_archiso_packages}"
    if [[ -n $1 ]]; then
        arch_target_dir="${1}"
        arch_chroot="/usr/bin/arch-chroot ${1}"
    fi

    msg "Overriding mirrorlist"
    run_cmd "cp mirrorlist /etc/pacman.d/mirrorlist"

    msg "Installing archzfs repo into chroot"
    printf "\n%s\n%s\n" "[${test_archzfs_repo_name}]" "Server = file:///repo/\$repo/\$arch" >> ${arch_target_dir}/etc/pacman.conf

    msg2 "Setting up gnupg"
    run_cmd "${arch_chroot} dirmngr < /dev/null"

    msg2 "Installing the signer key"
    run_cmd "${arch_chroot} pacman-key -r 0EE7A126"
    if [[ ${run_cmd_return} -ne 0 ]]; then
        exit 1
    fi
    run_cmd "${arch_chroot} pacman-key --lsign-key 0EE7A126"
    if [[ ${run_cmd_return} -ne 0 ]]; then
        exit 1
    fi


    if [[ ! -n $1 ]]; then
        # Install the required packages in the image
        msg2 "Installing test packages"
        run_cmd "${arch_chroot} pacman -Sy --noconfirm ${arch_packages}"
        if [[ ${run_cmd_return} -ne 0 ]]; then
            exit 1
        fi
        msg2 "Loading zfs modules"
        run_cmd "modprobe zfs"
        if [[ ${run_cmd_return} -ne 0 ]]; then
            exit 1
        fi
    fi
}


test_pacman_pacstrap() {
    msg "bootstrapping the base installation"
    run_cmd "/usr/bin/pacstrap -c '${test_target_dir}/ROOT' base base-devel ${test_chroot_packages}"
    if [[ ${run_cmd_return} -ne 0 ]]; then
        exit 1
    fi
}
