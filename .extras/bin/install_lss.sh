#!/usr/bin/env bash

export ANSIBLE_ROLES_PATH=.extras/.ansible/roles/main/:.extras/.ansible/roles/external/

# Install the dependencies of the playbook:
ANSIBLE_ROLES_PATH=.extras/.ansible/roles/external/ ansible-galaxy install --role-file=.extras/.ansible/roles/requirements_lss.yml --force

ansible-playbook --inventory="localhost," --connection=local --ask-become-pass .extras/.ansible/playbooks/install_lss.yml
