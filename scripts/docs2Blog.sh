#!/bin/bash
#
# Use google docs and sheets to update a jekyll website and blog hosted on github pages
#
# Function for template option
sudo apt install pandoc > /dev/null
folder_path="/content/drive/MyDrive/Publishing"
template_func() {
    template_folder_path="$folder_path/Website"

    if [ ! -d "$template_folder_path" ]; then
        cd /tmp
        rm -rf ./docs2Blog
        git clone https://github.com/csymapp/docs2Blog.git 
        mkdir -p "$folder_path"
        rsync -av ./docs2Blog/Publishing/ "$folder_path"
    # else
    #     echo "The folder exists."
    fi
}

# Random string generation function
generate_random_string() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "${1:-10}" | head -n 1
}

# Function for ssh option
ssh_func() {
    ssh_folder_path="$folder_path/Website-private"

    if [ ! -f "$folder_path/Website-private/id_rsa" ]; then
        # sudo apt install xclip
        # read -p "Enter your email address: " email
        email="$1"
        # Define paths for the keys
        private_key_path="$ssh_folder_path/id_rsa"
        public_key_path="$ssh_folder_path/id_rsa.pub" > /dev/null
        ssh-keygen -t rsa -b 4096 -C "$email" -f "$private_key_path" -N "" > /dev/null
        touch /tmp/new_rsa
        # public_key=$(cat "$public_key_path")
        # echo "Public key has been generated. It is copied to the clipboard."
        # echo "$public_key" | xclip -selection clipboard
    # else
    #     echo "id_rsa exists."
    fi

    # ssh-keyscan GitHub.com >> /root/.ssh/known_hosts 2>&1 >/dev/null
    ## either ~ or /root is the correct directory. Use both just in case
    mkdir -p ~/.ssh
    mkdir -p /root/.ssh/
    mkdir -p /tmp/ssh
    rm -rf /tmp/ssh
    mkdir -p /tmp/ssh
    cp "$ssh_folder_path/id_rsa" /tmp/ssh/
    rsync -aq /tmp/ssh/  ~/.ssh/id_rsa
    rsync -aq /tmp/ssh/   /root/.ssh/id_rsa
    ssh-keyscan GitHub.com > /root/.ssh/known_hosts #2>&1 >/dev/null
    ssh-keyscan GitHub.com > ~/.ssh/known_hosts #2>&1 >/dev/null
    chmod 644 ~/.ssh/known_hosts
    chmod 600 ~/.ssh/id_rsa
    chmod 644 /root/.ssh/known_hosts
    chmod 600 /root/.ssh/id_rsa
}

ssh_setup() {
    # ssh-keyscan GitHub.com >> /root/.ssh/known_hosts 2>&1 >/dev/null
    ## either ~ or /root is the correct directory. Use both just in case
    ssh_folder_path="$folder_path/Website-private"
    mkdir -p ~/.ssh
    mkdir -p /root/.ssh
    mkdir -p /tmp/ssh
    rm -rf /tmp/ssh
    mkdir -p /tmp/ssh
    cp "$ssh_folder_path/id_rsa" /tmp/ssh/
    rsync -aq /tmp/ssh/  ~/.ssh/id_rsa/
    rsync -aq /tmp/ssh/   /root/.ssh/id_rsa/
    ssh-keyscan GitHub.com > /root/.ssh/known_hosts #2>&1 >/dev/null
    ssh-keyscan GitHub.com > ~/.ssh/known_hosts #2>&1 >/dev/null
    chmod 644 ~/.ssh/known_hosts
    chmod 600 ~/.ssh/id_rsa
    chmod 644 /root/.ssh/known_hosts
    chmod 600 /root/.ssh/id_rsa
}



# Function for docId option
site_func() {
    ./siteProcessor.sh
    # Add your code for the docId function here
}

# Function for all option
all_func() {
    echo "Running all function"
    # Add your code for the all function here
}

# Main script
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 [template|ssh <email>|sshsetup|all]"
    exit 1
fi

case $1 in
    "template")
        template_func
        ;;
    "ssh")
        ssh_func "$2"
        ;;
    "sshsetup")
        ssh_setup
        ;;
    "site")
        site_func
        ;;
    "all")
        all_func
        ;;
    *)
        echo "Invalid option"
        echo "Usage: $0 [template|ssh|docId <argument>|all]"
        exit 1
        ;;
esac