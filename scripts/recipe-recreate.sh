#!/usr/bin/env bash

##Set 
#SINGULARITY_API_HOST=
#JENKINS_API_TOKEN=
#use .env file or some other method of assigning env vars

[ -f .env ] && . .env

if [ $(command -v templater | wc -c) -eq 0 ]; then
    echo 'Please install Templater using...
    sudo curl -L https://raw.githubusercontent.com/JBris/bash-templater/master/templater.sh -o /usr/local/bin/templater
    sudo chmod +x /usr/local/bin/templater'
    exit 1
fi

#Vars 
DIR=$(pwd)
SUBSTRING=Singularity
EXT_FILTER="template"
SOFTWARE_ID=${PWD##*/}

#Main
read -p "Please enter your target directory (Defaults to \$PWD): " input_dir
read -p "Please enter your recipe file name (Defaults to \"Singularity\"): " input_substring
read -p "Please enter your semicolon delimited filter for recipe versions. These versions will not be recreated: " input_ext_filter
read -p "Please enter the software name (defaults to the current directory name): " input_software_id
read -p "Please enter the current template version (defaults to the most recent git commit): " input_template_version

[ "$input_dir" != '' ] && DIR="$input_dir"
[ "$input_substring" != '' ] && SUBSTRING="$input_substring"
[ "$input_ext_filter" != '' ] && EXT_FILTER="${EXT_FILTER} ; $input_ext_filter"
[ "$input_software_id" != '' ] && SOFTWARE_ID="$input_software_id"

if [[ "$input_template_version" == '' ]]; then
    if [ "$DIR" == "$PWD" ]; then
        export TEMPLATE_VERSION=$(git log -n 1 --pretty=format:"%H")
    else
        export TEMPLATE_VERSION=$(git --git-dir "${DIR}/.git" log -n 1 --pretty=format:"%H")
    fi
else 
    export TEMPLATE_VERSION="$input_template_version"
fi

IFS=';' read -r -a filter_values <<< "$EXT_FILTER"
declare -A filter_map
for filter_value in "${filter_values[@]}"; do
    key=$(echo "$filter_value" | sed -e 's/ *$//g' -e 's/^ *//g')
    filter_map[$key]=''
done

declare -a versions
for file in ${DIR}/*; do
    no_path="${file##*/}"
    [[ "$no_path" != *"$SUBSTRING"* ]] && continue
    version="${no_path##${SUBSTRING}.}"
    [ -v "filter_map[${version}]" ] && continue
    versions+=( "$version" )
done

[ -f "${DIR}/pre_hook_regenerate_recipes.sh" ] && . "${DIR}/pre_hook_regenerate_recipes.sh"

for version in "${versions[@]}"; do
    (
        export SINGULARITY_RELEASE_VERSION="$version"
        [ -f "${DIR}/pre_hook_regenerate_recipe.sh" ] && . "${DIR}/pre_hook_regenerate_recipe.sh" 
        templater "${DIR}/${SUBSTRING}.template" > "${DIR}/${SUBSTRING}.${SINGULARITY_RELEASE_VERSION}" 
        [ -f "${DIR}/post_hook_regenerate_recipe.sh" ] && . "${DIR}/post_hook_regenerate_recipe.sh" 
        echo "Recreated ${SUBSTRING}.${SINGULARITY_RELEASE_VERSION}"
    ) &
done

wait