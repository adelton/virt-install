
# Create virtual machine using virt-install

While it is easy to get environments of different operating systems
than the GitHub Actions runners with `podman` or `docker`, sometimes
containers are not enough and a true virtual machine (VM) is needed.

This action fetches a VM image from a URL provided as input, then creates
and runs a virtual machine using
[virt-install](https://github.com/virt-manager/virt-manager/blob/main/man/virt-install.rst).

Example of getting an AlmaLinux 10 VM:
```
jobs:
  virt-install-almalinux:
    runs-on: ubuntu-latest
    steps:
      - uses: adelton/virt-install@master
        with:
          disk-url: https://repo.almalinux.org/almalinux/10.1/cloud/x86_64/images/AlmaLinux-10-GenericCloud-10.1-20251125.0.x86_64.qcow2
      - run: ssh root@vm1.example.com cat /etc/os-release
```

This action was tested on the `ubuntu-22.04` (`ubuntu-latest`) runners.

Before running `virt-install`, this action
- installs the needed packages;
- fetches the image from the provided URL (input `disk-url`);
- generates an SSH key;
- creates a cloud-init config on a
  [CD-ROM filesystem](https://docs.cloud-init.io/en/latest/reference/datasources/nocloud.html#source-2-drive-with-labeled-filesystem)
  to set up [SSH authorized_keys and enable SSH access to
  root](https://cloudinit.readthedocs.io/en/latest/reference/modules.html#ssh);
- enables access to the `virbr0` bridge to use system libvirtd's
  networking and DHCP.

Then `virt-install` is run, creating the VM in `qemu:///session`.
Name of the VM can be controlled by the `vm-name` input.

After creating the virtual machine, the action will

- wait for the `login:` prompt on the VM console;
- determine the IP address that the VM got from DHCP;
- add an entry to `/etc/hosts` for the VM name provided (input `vm-name`);
- SSH to the VM as root to test the setup.

## Inputs

### disk-url

The URL of a QCOW2 image to fetch and use for the virtual machine.

Required; no default.

Example:
```
      - uses: adelton/virt-install@master
        with:
          disk-url: https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img
```

### vm-name

Name of the virtual machine (libvirt domain) to use. It will be also
used to set up hostname resolution to the VM IP address in `/etc/hosts`,
so after
```
      - uses: adelton/virt-install@master
        with:
          disk-url: https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img
          vm-name: ubuntu.example.test
```
steps like
```
      - run: ssh root@ubuntu.example.test cat /etc/os-release
```
or
```
      - run: virsh dumpxml ubuntu.example.test
```
can be used.

Default: `vm1.example.com`.

Allowed characters: lowercase alphanumeric, dot, dash, and underscore only.

### osinfo

Since `virt-install` requires the `--osinfo` option, this allows it to
be explicitly specified.

Example:
```
      - uses: adelton/virt-install@master
        with:
          disk-url: https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2
          osinfo: fedora41
```

Default: `generic`.

## License

The code and documentation in this project are released
under the [BSD Zero Clause License](LICENSE).

