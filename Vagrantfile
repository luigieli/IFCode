Vagrant.configure("2") do |config|
  config.vm.boot_timeout = 600
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "dev-vm"
  
  # Expor as portas de cada aplicação. (Altere o campo host caso alguma dessas portas esteja ocupada na sua máquina)
  # API Judge0
  config.vm.network "forwarded_port", guest: 2358, host: 2358
  # Banco de Dados da API Judge0 e Backend
  config.vm.network "forwarded_port", guest: 5432, host: 5433 
  # Backend Laravel
  config.vm.network "forwarded_port", guest: 8000, host: 8000
  # Frontend React
  config.vm.network "forwarded_port", guest: 5173, host: 5173
  
  # Recursos da máquina. São ajustáveis.
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    vb.cpus = 4
    vb.name = "ambiente-ifcodes-ubuntu22t"
    # vb.gui = true
  end
  
  # Sincroniza a pasta do projeto para /vagrant na VM
  config.vm.synced_folder ".", "/vagrant"

  # Provisionamento usando o script setup.sh
  config.vm.provision "shell", inline: <<-SHELL
    cd /vagrant
    chmod +x setup.sh
    ./setup.sh
  SHELL
end
