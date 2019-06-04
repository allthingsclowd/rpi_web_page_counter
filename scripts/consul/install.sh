#!/usr/bin/env bash

create_service () {
  if [ ! -f /etc/systemd/system/${1}.service ]; then
    

    
    sudo tee /etc/systemd/system/${1}.service <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload

  fi

}

create_service_user () {
  
  if ! grep ${1} /etc/passwd >/dev/null 2>&1; then
    echo "Creating ${1} user to run the consul service"
    sudo useradd --system --home /etc/${1}.d --shell /bin/false ${1}
    sudo mkdir --parents /opt/${1} /usr/local/${1} /etc/${1}.d
    sudo chown --recursive ${1}:${1} /opt/${1} /etc/${1}.d /usr/local/${1}
    sudo touch /etc/${1}.d/server.hcl /etc/${1}.d/consul.hcl
    sudo chmod 640 /etc/${1}.d/consul.hcl /etc/${1}.d/server.hcl
  fi

}

create_consul_agent_configuration_file () {

  sudo tee /etc/consul.d/consul.hcl <<EOF
    primary_datacenter = allthingscloud1"
    data_dir = "/opt/consul"
    encrypt = "PzEnZw0DHr9YH5QoF38yzA=="
    retry_join = ["192.168.1.200","192.168.1.205","192.168.1.206"]
    performance {
        raft_multiplier = 1
    }
EOF

}

create_consul_server_configuration_file () {

  sudo tee /etc/consul.d/server.hcl <<EOF
    server = true
    bootstrap_expect = 3
    ui = true
EOF

}


verify_consul_version () {
    # check consul is installed and it's the correct version - if not then install it
    consul version 2>&1 | grep "${consul_version}" || install_consul_binary

}

install_consul_binary () {

    echo 'consul missing or incorrect version - installing Consul version '${consul_version}' now...'
    # install consul binary
    pushd /usr/local/bin
    [ -f consul_${consul_version}_${architecture}.zip ] || {
        sudo wget -q https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_${architecture}.zip
    }
    sudo unzip -o consul_${consul_version}_${architecture}.zip
    sudo chmod +x consul
    sudo rm consul_${consul_version}_${architecture}.zip
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





setup_environment
verify_consul_version
create_service_user consul
create_service consul
create_consul_agent_configuration_file
create_consul_server_configuration_file
exit 0
