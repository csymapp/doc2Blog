#!/bin/bash
#
# Use google docs and sheets to update a jekyll website and blog hosted on github pages
#
# Function for template option

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
        echo "using email $email"

        # Define paths for the keys
        private_key_path="$ssh_folder_path/id_rsa"
        public_key_path="$ssh_folder_path/id_rsa.pub" > /dev/null 2>$1
        ssh-keygen -t rsa -b 4096 -C "$email" -f "$private_key_path" -N "" > /dev/null
        touch /tmp/new_rsa
        # public_key=$(cat "$public_key_path")
        # echo "Public key has been generated. It is copied to the clipboard."
        # echo "$public_key" | xclip -selection clipboard
    # else
    #     echo "id_rsa exists."
    fi
}

# Function for docId option
docId_func() {
    echo "Running docId function with argument: $1"
    # Add your code for the docId function here
}

# Function for all option
all_func() {
    echo "Running all function"
    # Add your code for the all function here
}

# Main script
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 [template|ssh|docId <argument>|all]"
    exit 1
fi

case $1 in
    "template")
        template_func
        ;;
    "ssh")
        ssh_func "$2"
        ;;
    "docId")
        if [[ $# -lt 2 ]]; then
            echo "Please provide an argument for docId option"
            exit 1
        fi
        docId_func "$2"
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