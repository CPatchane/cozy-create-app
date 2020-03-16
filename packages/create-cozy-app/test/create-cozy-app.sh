#!/usr/bin/env bash
set -e

#######
## Here, we only test the CLI with a mock script which just log a
## success message
#######

#######
## Variables
#######

color_green='\033[38;2;8;180;66m'
color_blue='\033[38;2;41;126;242m'
color_red='\033[38;2;221;6;6m'
color_orange='\033[38;2;255;174;95m'
color_close='\033[0m'

# This test will create a test application in test-app
# and remove it in any cases (error or success)
test_folder='.tmp_test'
root_path=$PWD
mock_scripts_path_from_root=packages/create-cozy-app/test/mocks/mock-scripts
app_name='test-app'

#######
## Functions
#######

# Check if provided filenames exists
function exists {
    for file in $*; do
        test -e $file
    done
}

# Check if provided filenames exists, stop with error if not
function exists_or_error {
    for file in $*; do
        if test ! -e $file; then
            echo -e "${color_red}The expected created file $file doesn't exist.${color_close}\n"
            exit 1
        fi
    done
}

function clean_up {
    # clean up generated files
    echo -e "${color_orange}Cleaning up generated files${color_close}"
    cd $root_path
    rm -rf $test_folder
    echo -e 'Cleaned.\n'
}

function graceful_exit {
    if [ -n "$1" ]; then
        echo -e "${color_red}$(basename $0): ERROR! Something went wrong executing $1.${color_close}\n" 1>&2
        clean_up
        exit 1
    else
        echo -e "${color_red}Something when wrong, exiting.${color_close}\n" 1>&2
        clean_up
        exit 1
    fi
}

#######
## Prepare
#######

# Allow graceful exit on errors
trap 'set +x; graceful_exit $LINENO $BASH_COMMAND' ERR
# Allow graceful exit when exiting without errors
trap 'set +x; graceful_exit' SIGQUIT SIGTERM SIGINT SIGKILL SIGHUP

# This test will will be run in .test
# and remove it in any cases (error or success)
if exists $test_folder; then
    echo -e "The test directory \"$test_folder/\" already exists.\nPlease verify its content and remove the \"$test_folder/\" folder then run the tests again."
    echo -e "${color_red}Exiting due to already existing folder $test_folder/ error.${color_close}" 1>&2
    exit 1
fi

# create and move to app folder
mkdir $test_folder
cd $test_folder

# clean yarn cache (disabled because it can make tests too long)
# yarn cache clean

#######
## Test with --scripts-source fileAbs:...
#######

# run the script
echo -e "\n${color_blue}----------------------------------------------------------------------------------${color_close}"
echo -e "${color_blue}• Test with --scripts-source fileAbs:$root_path/$mock_scripts_path_from_root${color_close}"
node $root_path/packages/create-cozy-app/index.js $app_name --scripts-source fileAbs:$root_path/$mock_scripts_path_from_root

# if here, there is no errors with the script
# check the new created folder content

exists_or_error $app_name
cd $app_name
exists_or_error package.json yarn.lock node_modules
# check dependency name in package.json
scriptsDep="$(node -pe 'JSON.parse(process.argv[1]).dependencies["cozy-scripts"]' "$(cat package.json)")"
if [ $scriptsDep == 'undefined' ]; then
    echo -e "${color_red} Dependency 'cozy-scripts' not found in package.json or not correctly installed.${color_close}\n"
    clean_up
    exit 1
fi

#######
## Clean up app folder for the next test
#######
cd ..
rm -rf $app_name

####------------------------------------------------------------####

#######
## Test with --scripts-source fileRel:...
#######

# run the script
echo -e "\n${color_blue}----------------------------------------------------------------------------------${color_close}"
echo -e "${color_blue}• Test with --scripts-source fileRel:../$mock_scripts_path_from_root${color_close}"
# here: cwd = $test_folder
node $root_path/packages/create-cozy-app/index.js $app_name --scripts-source fileRel:../$mock_scripts_path_from_root

# if here, there is no errors with the script
# check the new created folder content

exists_or_error $app_name
cd $app_name
exists_or_error package.json yarn.lock node_modules
# check dependency name in package.json
scriptsDep="$(node -pe 'JSON.parse(process.argv[1]).dependencies["cozy-scripts"]' "$(cat package.json)")"
if [ $scriptsDep == 'undefined' ]; then
    echo -e "${color_red} Dependency 'cozy-scripts' not found in package.json or not correctly installed.${color_close}\n"
    clean_up
    exit 1
fi

#######
## Clean up app folder for the next test
#######
cd ..
rm -rf $app_name

