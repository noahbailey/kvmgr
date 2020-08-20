# kvmgr

kvmgr is a humble shell script for quickly deploying Ubuntu VMs to a local KVM system. 

## Usage

The script is meant to be simple to use. The only strictly required parameter is the hostname for the new VM. 

    ./kvmgr.sh --name my-cool-virtual-machine

### Parameters

To specify the VM configuration the other command line parameters can be used: 

| Flag | Keyword | Default Value
| ---- | ------- | -------------
| -c   | --cpus  | 1
| -m   | --mem   | 512
| -d   | --disk  | 8G
| -i   | --net   | `default` (libvirt NAT)
| -o   | --os    | focal
| -n   | --name  | 

### Examples

1. Create a lightweight virtual machine using the latest LTS version: 

        kvmgr.sh --cpus 1 --mem 512 --disk 5G --os focal --name lightvm

2. Create a more powerful virtual machine using an earlier LTS distro: 

        kvmgr.sh --cpus 4 --mem 8192 --disk 60G --os bionic --name appserver1

3. Create a VM with the same options, but using the shorthand flags: 

        kvmgr.sh -c 4 -m 8192 -d 60G -o bionic -n appserver2

## Config Files

### defaults.conf

All of the default values can be tweaked by editing the `defaults.conf` file to set custom defaults. 

### user.conf

To configure the user authentication, create a `user.conf` file in the same directory. This file specifies three main parameters. 

* `AUTH_PASSWD` - The password for the default ubuntu@host user, meant for console login.
* `AUTH_USERNAME` - A user that will be created in the VM, meant for remote login with SSH.
* `AUTH_PUBKEY` - The SSH public key that will be added to the VM user. 

An example of the user.conf file: 

```
AUTH_PASSWD="changeme"
AUTH_USERNAME="gablogian"
AUTH_PUBKEY="ssh-ed25519 AAAAC3Nxxxxxx"
```
