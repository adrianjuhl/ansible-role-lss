# Ansible role: lss (local secret store)

Installs a simple script that helps store, with encryption, secrets/passwords locally and retrieve them to assist with task/script automation, etc.

The basic workings consists of:
  - a master password that is used to encrypt secrets when storing them and decrypt them on retrieval
  - a store of secrets, contained in the directory ~/.lss-secrets
  - the lss script that performs the functions set out below

Once installed, the 'lss' command will provide the following commands:
  - lss get     - to return a secret, decrypted with the master password
  - lss put     - to store a secret, encrypted with the master password
  - lss unlock  - prompts for the master password and records that in a file in /run (making it temporary until the next restart)
  - lss list    - list the set of stored secrets

## Requirements

The script depends on jasypt and other resources provided by the [adrianjuhl.jasypt](https://github.com/adrianjuhl/ansible-role-jasypt) ansible role, which can be installed via an ansible playbook that includes the ansible role, or via a stand-alone install script.

## Role Variables

None.

## Dependencies

None.

## Example Playbook
```
- hosts: servers
  roles:
    - { role: adrianjuhl.lss }

or

- hosts: servers
  tasks:
    - name: Install lss
      include_role:
        name: adrianjuhl.lss
```

## Extras

### Install script

For convenience, a bash script is also supplied that facilitates easy installation of lss on localhost (the script executes ansible-galaxy to install the role and then executes ansible-playbook to run a playbook that includes the lss role).

The script can be run like this:
```
$ git clone git@github.com:adrianjuhl/ansible-role-lss.git
$ cd ansible-role-lss
$ .extras/bin/install_lss.sh
```

## License

MIT

## Author Information

[Adrian Juhl](http://github.com/adrianjuhl)
