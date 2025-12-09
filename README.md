# 📌 IF Codes

## 🚀 Tecnologias Utilizadas

- [Laravel](https://laravel.com/) – Framework PHP para desenvolvimento web
- [Docker](https://www.docker.com/) – Containerização do ambiente
- [PostgreSQL](https://www.postgresql.org/) – Banco de dados relacional

---

# Guia de Instalação do Ambiente de Desenvolvimento

Este guia detalha o processo para configurar e iniciar o ambiente de desenvolvimento completo do projeto.

O sistema pode ser executado de duas formas:
1.  **Via Vagrant (Recomendado para Windows/Mac):** Cria uma máquina virtual Ubuntu automaticamente.
2.  **Via Instalação Manual (Recomendado para Linux):** Instalação direta em uma máquina Ubuntu 22.04 (local ou VPS).

---

## 1. Pré-requisitos

Certifique-se de ter o **Git** instalado para clonar o repositório.

### Estrutura de Pastas

1.  Crie uma pasta principal para o projeto (ex: `ifcodes-dev`).
2.  Dentro desta pasta, clone os repositórios do backend e frontend:

    ```bash
    mkdir ifcodes-dev
    cd ifcodes-dev
    git clone [URL_DO_REPO_BACKEND] back
    git clone [URL_DO_REPO_FRONTEND] front
    ```
3.  Copie os arquivos de configuração (`docker-compose.yml`, `setup.sh`, `judge0.conf`, `Vagrantfile`) para a raiz da pasta `ifcodes-dev/`.

---

## 2. Escolha seu Método de Instalação

### Opção A: Usando Vagrant (Windows / Mac)

Recomendado se você usa Windows ou não quer configurar seu próprio ambiente Linux.

1.  **Pré-requisitos:** Instale [VirtualBox](https://www.virtualbox.org/) e [Vagrant](https://developer.hashicorp.com/vagrant/downloads).
2.  No terminal, dentro da pasta do projeto, execute:
    ```bash
    vagrant up
    ```
3.  Aguarde o fim do processo. Se solicitado, reinicie a VM para aplicar configurações do Kernel (Judge0):
    ```bash
    vagrant reload
    ```
4.  Acesse a VM:
    ```bash
    vagrant ssh
    cd /vagrant
    ```
5.  Inicie os serviços:
    ```bash
    docker compose up -d
    ```

### Opção B: Instalação Manual / Linux Nativo (Ubuntu 22.04)

Recomendado se você usa Linux ou tem uma VM/VPS Ubuntu 22.04 pronta.

1.  Abra o terminal na pasta raiz do projeto.
2.  Dê permissão de execução e rode o script de setup:
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```
    *O script pedirá sua senha `sudo` para instalar o Docker e configurar o sistema.*
3.  **Reinicie o computador (ou VM)** para que as configurações do Kernel e grupos de usuário entrem em vigor.
4.  Após reiniciar, volte à pasta e inicie os serviços:
    ```bash
    docker compose up -d
    ```

---

## 3. Pós-Instalação (Migrações)

Com os contêineres rodando (seja no Vagrant ou Linux nativo), execute as configurações finais do Laravel:

1.  **Execute as Migrações:**
    ```bash
    docker exec laravel_app php artisan migrate:fresh --seed
    ```
2.  **Gere a Chave da Aplicação:**
    ```bash
    docker exec laravel_app php artisan key:generate
    ```

**Pronto!** O sistema está operacional.

---

## 4. Acessando os Serviços

* **Frontend (React):** `http://localhost:5173`
* **Backend (Laravel):** `http://localhost:8000`
* **API (Judge0):** `http://localhost:2358`

### Credenciais e Acesso ao Banco

O script de instalação gera senhas seguras automaticamente e as salva no arquivo `passwords.txt` na raiz do projeto.

* **Banco de Dados (Postgres):** Porta `5433` (Host) / `5432` (Container). Usuário: `integrador`. Senha: ver `passwords.txt`.
* **Configuração Automática:** O script já preencheu o arquivo `back/src/.env` e `judge0.conf` com estas senhas.

---

## 5. Dica de Performance (Windows + Vagrant)

Caso o sistema esteja lento no Windows com Vagrant, instale o plugin `vagrant-winnfsd` e edite o `Vagrantfile` para usar NFS (veja comentários no arquivo).
