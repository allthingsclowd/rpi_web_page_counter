#!/usr/bin/env bash

display_command_line_help () {
    echo "Vault Installer"
    echo " "
    echo "install.sh [options]"
    echo " "
    echo "options:"
    echo "-h, --help         show brief help"
    echo "-s, --server       specify to install vault agent in server mode"
    echo "-c, --client       specify to install vault agent in client mode"
    exit 0
}

process_commandline_inputs() {

    if test ${1} -eq 0; then
        display_command_line_help
    fi

    case "${2}" in
            -h|--help)
                    display_command_line_help
                    ;;
            -s|--server)
                    export SERVERMODE=true
                    echo "Vault Installer Running in Server Mode"
                    break
                    ;;
            -c|--client)
                    export SERVERMODE=false
                    echo "Vault Installer Running in Client Mode"
                    break
                    ;;
            *)
                    display_command_line_help
                    ;;
    esac

}

create_service () {
    
    sudo tee /etc/systemd/system/${1}.service <<EOF
[Unit]
Description="HashiCorp Vault - A Centralised Secret Service"
Documentation=https://www.vaultproject.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl

[Service]
User=vault
Group=vault
ExecStart=/usr/local/bin/vault agent -config-dir=/etc/consul.d/ -client='0.0.0.0'
ExecReload=/usr/local/bin/vault reload
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

}

create_service_user () {
  
  if ! grep ${1} /etc/passwd >/dev/null 2>&1; then
    echo "Creating ${1} user to run the consul service"
    sudo useradd --system --home /etc/${1}.d --shell /bin/false ${1}
    sudo mkdir --parents /opt/${1} /usr/local/${1} /etc/${1}.d
    sudo chown --recursive ${1}:${1} /opt/${1} /etc/${1}.d /usr/local/${1}
  fi

}

create_consul_agent_configuration_file () {

    [ -f /etc/consul.d/consul.hcl ] &>/dev/null || {
        [ -d /etc/consul.d ] &>/dev/null || {
            sudo mkdir --parents /etc/consul.d
        }
        sudo touch /etc/consul.d/consul.hcl
        sudo chmod 640 /etc/consul.d/consul.hcl
        sudo chown --recursive consul:consul /etc/consul.d

    }

    sudo tee /etc/consul.d/consul.hcl <<EOF
        primary_datacenter = "allthingscloud1"
        data_dir = "/opt/consul"
        encrypt = "PzEnZw0DHr9YH5QoF38yzA=="
        retry_join = [$consul_cluster_servers]
        performance {
            raft_multiplier = 1
        }
EOF

    sudo chown consul:consul /etc/consul.d/consul.hcl

}

create_consul_server_configuration_file () {

    [ -f /etc/consul.d/server.hcl ] &>/dev/null || {
        [ -d /etc/consul.d ] &>/dev/null || {
            sudo mkdir --parents /etc/consul.d
        }
        sudo touch /etc/consul.d/server.hcl
        sudo chmod 640 /etc/consul.d/server.hcl
        sudo chown --recursive consul:consul /etc/consul.d

    }

  sudo tee /etc/consul.d/server.hcl <<EOF
    server = true
    bootstrap_expect = 3
    ui = true
EOF

    sudo chown consul:consul /etc/consul.d/server.hcl
}

verify_vault_version () {
    # check consul is installed and it's the correct version - if not then install it
    vault version 2>&1 | grep "${vault_version}" || install_vault_binary

}

install_vault_binary () {

    echo 'vault missing or incorrect version - installing Vault version '${vault_version}' now...'
    # install vault binary
    pushd /usr/local/bin
    [ -f vault_${vault_version}_${architecture}.zip ] || {
        sudo wget -q https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_${architecture}.zip
    }
    sudo unzip -o vault_${vault_version}_${architecture}.zip
    sudo chmod +x vault
    sudo rm vault_${vault_version}_${architecture}.zip
    popd

    # install consul-template binary
    echo 'installing Consul-Template version '${consul_template_version}' now...'
    pushd /usr/local/bin
    [ -f consul-template_${consul_template_version}_${architecture}.zip ] || {
        sudo wget -q https://releases.hashicorp.com/consul-template/${consul_template_version}/consul-template_${consul_template_version}_${architecture}.zip
    }
    sudo unzip -o consul-template_${consul_template_version}_${architecture}.zip
    sudo chmod +x consul-template
    sudo rm consul-template_${consul_template_version}_${architecture}.zip
    popd

    # check envconsul binary
    echo 'installing envconsul version '${env_consul_version}' now...'
    pushd /usr/local/bin
    [ -f envconsul_${env_consul_version}_${architecture}.zip ] || {
        sudo wget -q https://releases.hashicorp.com/envconsul/${env_consul_version}/envconsul_${env_consul_version}_${architecture}.zip
    }
    sudo unzip -o envconsul_${env_consul_version}_${architecture}.zip
    sudo chmod +x envconsul
    sudo rm envconsul_${env_consul_version}_${architecture}.zip
    popd

}

setup_environment () {
  set -x
  
  source ../../var.env
  
}

start_consul () {
    sudo systemctl enable consul
    sudo systemctl start consul
    sudo systemctl status consul
}

process_commandline_inputs $# $@
setup_environment
verify_vault_version
# create_service_user consul
# create_service consul
# create_consul_agent_configuration_file
# if [ "${SERVERMODE}" = true ]; then create_consul_server_configuration_file; fi
# start_consul
exit 0
