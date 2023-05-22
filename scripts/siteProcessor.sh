%%bash
cd /content
docId="$docId"  
sheetId="$sheetId"

dirPath=""
if [ -d "/content/drive/MyDrive/Publishing/Website" ]
then
    dirPath="/content/drive/MyDrive/Publishing/Website"
else
    if [ -d "/content/drive/My Drive/Publishing/Website" ]
    then
        dirPath="/content/drive/My Drive/Publishing/Website"
    else
        exit
    fi
fi

#### download google sheet
## hardcode also folderId,,, let these be the first in the list....
rm -f logs1
wget --output-file="logs1" "https://docs.google.com/spreadsheets/d/$docId/export?format=csv&gid=$sheetId" -O "sheet.csv"
rm logs1

#### process sheet vars
# prelink=$(grep -rh "Github," sheet.csv | sed 's/Github,//')
#prelink=$(cat sheet.csv |grep -o 'Github,[^ ]*' | cut -d',' -f2 | tr -d '\r')
#prelink=$(cat sheet.csv | awk -F',' '/Github/ {print $2}') | tr -d '\r'
prelink=$(cat sheet.csv |grep -o 'Github,[^ ]*' | cut -d',' -f2 | tr -d '\r')
link="git@github.com:$prelink.git"
echo $link 
exit

GitCommitUser=$(grep -rh "GitCommitUser," sheet.csv | sed 's/GitCommitUser,//' | tr -d '\r'| sed 's/,//g')
GitCommitEmail=$(grep -rh "GitCommitEmail," sheet.csv | sed 's/GitCommitEmail,//'| tr -d '\r'| sed 's/,//g')
youtubeChannel=$(grep -rh "youtubeChannel," sheet.csv | sed 's/youtubeChannel,//'| tr -d '\r' | sed 's/,//g')
folderId=$(grep -rh "postsDirectoryId," sheet.csv | sed 's/postsDirectoryId,//'| tr -d '\r' | sed 's/,//g')
authorFolderId=$(grep -rh "authorDirectoryId," sheet.csv | sed 's/authorDirectoryId,//'| tr -d '\r' | sed 's/,//g')
pagesFolderId=$(grep -rh "pagesDirectoryId," sheet.csv | sed 's/pagesDirectoryId,//'| tr -d '\r' | sed 's/,//g')
rm sheet.csv


#### clone repo
rm -rf websiteRepo
mkdir -p websiteRepo

# ls -lha ~/.ssh
# echo "-------------"
# ls -lha /root/.ssh
# cat ~/.ssh/id_rsa
# cat ~/.ssh/known_hosts

git clone "$link" websiteRepo 


#### Download sheets
cd websiteRepo
mkdir -p "./configs/sheets"
rm -f logs
while IFS=, read -r docId sheetId; do
    wget --output-file="logs" "https://docs.google.com/spreadsheets/d/$docId/export?format=csv&gid=$sheetId" -O "./configs/sheets/$docId$sheetId.csv"
done < "./configs/datasheets.txt"
rm -f logs

## merge images
rsync -aq  /content/drive/MyDrive/Publishing/Website/img/ ./assets/img/


## Install pandoc to convert _posts to markdown
## To use pandoc, we will first need to convert the gdoc files to docx. This we reserve for later
#curl --silent "https://api.github.com/repos/jgm/pandoc/releases/latest"|   grep "browser_download_url.*amd64.deb" | head -n 1 | cut -d : -f 2,3 | tr -d \"  | xargs wget -O tmp.deb && sudo dpkg -i tmp.deb
rm -rf /tmp/_posts
mkdir -p /tmp/_posts
#ls -lha /content/drive/MyDrive/Publishing/Website/_posts
####### ls -lha /content/drive/MyDrive/Publishing/Website/_posts/
#### #### #### rsync -avz --ignore-errors  /content/drive/MyDrive/Publishing/Website/_posts/ /tmp/_posts/
# gdown --id 17yR0j6LMb6hG1E8DRz0tslvxCk4o5vMn -O /tmp/_posts

## this will fail for .gdown files. Just use it to get the docIds
gdown https://drive.google.com/drive/folders/$folderId -O /tmp --folder --continue > /tmp/filelist 2>/dev/null || true
currentDir=$(pwd)

## download conversion script
wget -q https://raw.githubusercontent.com/adventHymnals/resources/master/scripts/docx2md.sh -O /tmp/docx2md.sh
chmod +x /tmp/docx2md.sh
cd /tmp/_posts
cp /tmp/docx2md.sh ./docx2md.sh


while read -r docId; do
  echo "Exporting $docId"
  # Download a served file keeping its name.
  # wget --content-disposition --trust-server-names seems to be having some errors

  # wget --content-disposition --trust-server-names "https://docs.google.com/document/d/${docId}/export?format=docx" || true
  curl -sJLO "https://docs.google.com/document/d/${docId}/export?format=docx" || true
  addedFile=$(ls -t | head -n1)

  filename=$(basename "$addedFile" .docx)
  ./docx2md.sh "$filename"

  echo " " >> "$filename/README.md"
  echo "DocId: $docId" >> "$filename/README.md"

  # echo "Added FILE: $addedFile"
  # mv $addedFile "$docId:::$addedFile"
done < <(grep -o 'Processing file .*' /tmp/filelist |sed 's/Processing file //' | sed 's/ .*//') 

find . -name '*export?format=docx*' -type f -delete

# for file in /tmp/_posts/*.docx; do
#     filename=$(basename "$file" .docx)
#     ./docx2md.sh "$filename"
# done

cd "$currentDir"

frontMatter=""
mkdir -p ./assets/img/posts/

# add_default_frontmatter() {
function add_default_frontmatter {
  fileFrontMatter="$1"
  thidDir="$2"

  ## remove yaml front matter from imported file if any
  line_num=1
  i=0
  startLine=1
  stopLine=1
  while read -r line; do
    i=$((i+1))
    if [ $i -eq 1 ]; then  # line 1
      if [ "$line" != '---' ]; then
          stopLine=0
          break
      else 
          continue
      fi
    fi
      stopLine=$((stopLine+1))
      if [ "$line" != '---' ]; then
          continue
      else 
          #echo "stopping at $stopLine"
          break
      fi
  done < <(tail -n +"$line_num" "$fileFrontMatter")

  if [ $stopLine -gt 0 ]; then
      sed -i "${startLine},${stopLine}d" "$fileFrontMatter"
  fi
  ### End of remove front matter

  # Get the line number that contains the table header
  line_num=$(grep -n "^|[ ]*FrontMatter[ ]*|[ ]*Value[ ]*|" "$fileFrontMatter" | cut -d: -f1)

  # Read lines from the fileFrontMatter starting from the table header line until the last line that starts with |
  i=0

  ## Default front matter values
  layout="posts"
  image="person.png"

  found_layout=0
  found_image=0

  startLine=$line_num
  stopLine=$line_num
  metadata=$(echo "---"
  while read -r line; do
    i=$((i+1))
    if [[ "${line:0:1}" != "|" ]]; then
      break
    fi
    if [ $i -gt 2 ]; then
      key=$(echo "$line" | awk -F'|' '{print $2}' | sed 's/ //g' | sed 's/ $//g')
      value=$(echo "$line" | awk -F'|' '{print $3}' | sed 's/ \{2,\}/ /g' | sed 's/^ //g')
      # if [ $key = "Image" || $key = "image" ]; then 
      # if [ "$key" = "Image" ] || [ "$key" = "image" ]; then 
      #   value=$(echo $value|sed 's|.*/assets/img/||')
      # fi
      # if echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -qi "^image$"; then
      #   value=$(echo $value|sed 's|.*/assets/img/||')
      # fi
      echo "$key: $value"
      if [ "$key" = "layout" ]; then
        found_layout=1
      elif [ "$key" = "image" ]; then
        found_image=1
      fi
    fi
    stopLine=$((stopLine+1))
  done < <(tail -n +"$line_num" "$fileFrontMatter")
  sed -i "${startLine},${stopLine}d" "$fileFrontMatter"
  if [ $found_layout -eq 0 ]; then
    echo "layout: $layout"
  fi

  # if [ $found_image -eq 0 ]; then
  #   echo "image: $image"
  # fi
  docId=$(grep -oP '^DocId: \K[\w-]+' "$fileFrontMatter"  | tail -n 1)
  echo "docId: $docId"
  echo "---"
  echo " ")
  #echo "$metadata" | cat - "$fileFrontMatter" > temp && sed -i 's/Image: !\[\]({{site\.baseurl}}assets\/img\/\(posts\/[^/]*\/[^)]*\))/Image: \1/g' temp && sed -i '/^DocId: [^ ]*$/d' temp && mv temp "$fileFrontMatter"
  echo "$metadata" | cat - "$fileFrontMatter" > temp && sed -i "s/Image: !\[\]({{site\.baseurl}}assets\/img\/\($thidDir\/[^/]*\/[^)]*\))/Image: \1/g" temp 
  line_num=$(grep -n "^DocId: [^ ]*$" temp | tail -1 | cut -d: -f1)
  sed -i "${line_num}d" temp
  # sed -i "/^DocId: $docId/d" temp && 
  mv temp "$fileFrontMatter"

  # edit categories
  categoriesFile="$fileFrontMatter"
  ta=$(grep -n "^categories: " "$categoriesFile")
  lineNum=$(echo $ta | cut -f1 -d:)
  if [ -n "$lineNum" ]; then
      yaml=$(
      echo "categories:\\n"
      echo "  - "
      ta=$(echo "$ta" | tr '[:upper:]' '[:lower:]')
      bbys=$(echo $ta | cut -f3 -d: | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed 's/, */,/g' | sed 's/,/\\n  - /g')
      echo $bbys
      )

      echo $yaml | sed 's/\\n/\n/g' > temp
      awk 'NR==FNR{new = new $0 ORS; next} /^categories:/ {$0=new} 1' temp "$categoriesFile" > tmp
      mv tmp "$categoriesFile"

      # create categories files...
      sed -i '1d' temp

      while read -r line; do
        filename=$(echo "$line" | sed 's/^ *- *//')
        cat  "$currentDir/_pages/categories/categoryTemplate" > "$currentDir/_pages/categories/$filename.html"
        sed -i "s/template/$filename/g" "$currentDir/_pages/categories/$filename.html"
      done < temp

      rm temp

      ## authors
      sed -i 's/^Author: /author: /' "$categoriesFile"
      ta=$(grep -n "^author: " "$categoriesFile")
      lineNum=$(echo $ta | cut -f1 -d:)
      mkdir -p "$currentDir/_authors"
      if [ -n "$lineNum" ]; then
          fullName=$(echo $ta | cut -f3 -d: | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
          shortName=$(echo $ta | cut -f3 -d: | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed 's/ //g')
          echo "---" > authorProfile
          echo "isAuthorPage: true" >> authorProfile
          echo "short_name: $shortName" >> authorProfile
          echo "name: $fullName" >> authorProfile
          echo "permalink: /author/$shortName.html" >> authorProfile
          echo "layout: author" >> authorProfile
          echo "navBar: navBarAndHeroAuthor" >> authorProfile
          echo "Image: " >> authorProfile
          echo "---" >> authorProfile
          echo " " >> authorProfile
          mv authorProfile "$currentDir/_authors/$shortName.md"
          
      fi
  fi
}

for file in ./_posts/*; do
  filename=$(basename "$file")
  pattern="^[0-9]{4}-[0-9]{2}-[0-9]{2}-(.*)\.(md|markdown)$"
  if [[ "${filename}" =~ ${pattern} ]]; then
      post_title="${BASH_REMATCH[1]}"
      # echo "${post_title}"
      if [[ -d "/tmp/_posts/$post_title" ]]; then
          filename1=$(basename $file)
            
          # remove the extension (either .md or .markdown)
          filename1="${filename1%.*}"

          sed -i "s|./media|{{site.baseurl}}assets/img/posts/$filename1/media|g" "/tmp/_posts/$post_title/README.md" # correct links
          sed -i 's/\\\(["`\-]\)/\1/g' "/tmp/_posts/$post_title/README.md"
          add_default_frontmatter "/tmp/_posts/$post_title/README.md" "posts"
          mv "/tmp/_posts/$post_title/README.md" $file
          ## copy media as well
          ## edit links in .md for media
          ## check if dir is not empty (has media)
          if test -n "$(find /tmp/_posts/$post_title -maxdepth 1 -type f -o -type d)"; then
            rsync -aq /tmp/_posts/$post_title/ ./assets/img/posts/$filename1/
            # mv /tmp/_posts/$post_title ./assets/img/
            rm -rf /tmp/_posts/$post_title
          # else
            # 
          fi
      else
          rm -rf ./assets/img/$post_title
          rm -rf $file
      fi
  fi
done

## Handle new posts
if [ "$(find /tmp/_posts/ -mindepth 1 -type d -print -quit)" ]; then
  for dir in /tmp/_posts/*/; do
      # Do something with each subdirectory
      # echo "Processing $dir"
      newPost=$(basename $dir)
      date=$(date +%Y-%m-%d)
      newname="${date}-${newPost}"
      sed -i "s|./media|{{site.baseurl}}assets/img/posts/$newname/media|g" "/tmp/_posts/$newPost/README.md" # correct links
      sed -i 's/\\\(["`\-]\)/\1/g' "/tmp/_posts/$newPost/README.md"
      add_default_frontmatter "/tmp/_posts/$newPost/README.md" "posts"
      mv "/tmp/_posts/$newPost/README.md" "./_posts/$newname.md"
      if test -n "$(find /tmp/_posts/$newPost -maxdepth 1 -type f -o -type d)"; then
        # mv /tmp/_posts/$newPost ./assets/img/
        rsync -aq /tmp/_posts/$newPost/ ./assets/img/posts/$newname/
        rm -rf /tmp/_posts/$newPost
      # else
      #   echo "/path/to/directory is empty"
      fi
  done
fi

#####
#####
##### Download authors file
##### end of Download Authors File
rm -rf /tmp/_authors
mkdir -p /tmp/_authors
cd /tmp/_authors
rm /tmp/filelist
gdown https://drive.google.com/drive/folders/$authorFolderId -O /tmp --folder --continue  > /tmp/filelist 2>/dev/null  || true #2>/dev/null 
while read -r docId; do
  # Download a served file keeping its name.
  # wget --content-disposition --trust-server-names seems to be having some errors

  # wget --content-disposition --trust-server-names "https://docs.google.com/document/d/${docId}/export?format=docx" || true
  curl -sJLO "https://docs.google.com/document/d/${docId}/export?format=docx" || true
  addedFile=$(ls -t | head -n1)
  filename=$(basename "$addedFile" .docx)
  cp /tmp/docx2md.sh ./docx2md.sh
  ./docx2md.sh "$filename"

  echo " " >> "$filename/README.md"
  ## copy media directory
  mkdir -p "$currentDir/assets/img/authors/$filename/media/"
  rsync -aq $filename/media/ "$currentDir/assets/img/authors/media/"

done < <(grep -o 'Processing file .*' /tmp/filelist |sed 's/Processing file //' | sed 's/ .*//') 

find . -name '*export?format=docx*' -type f -delete
while read -r line
do
    if [ "$((${LINENO}-2))" -eq 1 ]; then
        continue
    fi

    # remove the "|" characters from the beginning and end of the string
    line="${line#"|"}"
    line="${line%"|"}"

    # Split the line using the "|" delimiter and assign values to variables
    IFS='|' read -r name info image <<< "$line"
    # remove leading and trailing spaces
    name=$(echo $name| sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    #name=${name%%*( )}
    info=$(echo $info| sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    # info=${info%%*( )}
    # image=${image##*( )}
    image=$(echo $image| sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    image=$(echo $image| sed 's/.*\/\(media.*\))/.\/\1/')
    image=$(echo $image | sed "s|./media/||g")
    shortName=$(echo $name | sed 's/ //g')

    ## create file if it does not exist
    if [ -f "$currentDir/_authors/$shortName.md" ]; then
        echo " "
    else
        echo " " > "$currentDir/_authors/$shortName.md"
    fi

    first_line=$(head -n 1 "$currentDir/_authors/$shortName.md")
    if [ "$first_line" != "---" ]; then ## if files not does have yaml frontmatter
      echo "---" > "$currentDir/_authors/$shortName.md"
      echo "isAuthorPage: true" >> "$currentDir/_authors/$shortName.md"
      echo "short_name: $shortName" >> "$currentDir/_authors/$shortName.md"
      echo "name: $name" >> "$currentDir/_authors/$shortName.md"
      echo "permalink: /author/$shortName.html" >> "$currentDir/_authors/$shortName.md"
      echo "layout: author" >> "$currentDir/_authors/$shortName.md"
      echo "navBar: navBarAndHeroAuthor" >> "$currentDir/_authors/$shortName.md"
      echo "Image: " >> "$currentDir/_authors/$shortName.md"
      echo "---" >> "$currentDir/_authors/$shortName.md"
      echo " " >> "$currentDir/_authors/$shortName.md"
    fi
    if [ -n "$shortName" ]; then
        sed -i "s|Image:.*|Image: $image|" "$currentDir/_authors/$shortName.md"
        linNum=$(grep -n "^---" "$currentDir/_authors/$shortName.md" |head -n 2 |tail -n  1 | cut -d: -f1)
        head -n $linNum "$currentDir/_authors/$shortName.md"  > temp.txt
        # echo $info >> "$currentDir/_authors/$shortName.md"
        echo $info >> temp.txt
        mv temp.txt "$currentDir/_authors/$shortName.md"
        
    fi
done < <(tail -n +3 "authors/README.md")
rm -f "$currentDir/_authors/.md"
cd "$currentDir"
#####
#####

##### Sermons list
#####
#####
cd ./scripts
./youtube-dl.sh "$youtubeChannel"
cd ..

##### pages
#####
rm -rf /tmp/_pages
mkdir -p /tmp/_pages
cd /tmp/_pages
rm /tmp/filelist
gdown https://drive.google.com/drive/folders/$pagesFolderId -O /tmp --folder --continue > /tmp/filelist 2>/dev/null || true
cat /tmp/filelist
while read -r docId; do
  # Download a served file keeping its name.
  # wget --content-disposition --trust-server-names seems to be having some errors

  # wget --content-disposition --trust-server-names "https://docs.google.com/document/d/${docId}/export?format=docx" || true
  curl -sJLO "https://docs.google.com/document/d/${docId}/export?format=docx" || true
  addedFile=$(ls -t | head -n1)
  filename=$(basename "$addedFile" .docx)
  cp /tmp/docx2md.sh ./docx2md.sh
  ./docx2md.sh "$filename"

  echo " " >> "$filename/README.md"
  echo "DocId: $docId" >> "$filename/README.md"
  ## copy media directory
  mkdir -p "$currentDir/assets/img/pages/$filename/media/"
  rsync -aq $filename/media/ "$currentDir/assets/img/pages/$filename/media/"
  cp "$filename/README.md"  "$currentDir/_pages/$filename.md"

done < <(grep -o 'Processing file .*' /tmp/filelist |sed 's/Processing file //' | sed 's/ .*//') 

for file in /tmp/_pages/*/; do
file=$(basename "$file")
  # remove the extension (either .md or .markdown)
  sed -i "s|./media|{{site.baseurl}}assets/img/pages/$file/media|g" "$currentDir/_pages/$file.md" # correct links
  sed -i 's/\\\(["`\-]\)/\1/g' "$currentDir/_pages/$file.md"
  # cat "$currentDir/_pages/$filename.md"
  add_default_frontmatter "$currentDir/_pages/$file.md" "pages"
done


cd "$currentDir"
cd ./configs/
./sheetProcessor.sh


## process files
cd "$currentDir"
filesDir="$dirPath/files"
cd ./scripts
./filelist.sh "$filesDir"
cd "$currentDir"

#### push repo
cd "$currentDir"
git config --global user.email "$GitCommitEmail" 
git config --global user.name "$GitCommitUser"
git add . && git commit -m "$(date)" && git push origin master