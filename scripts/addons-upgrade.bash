#!/bin/bash
#
# Variables
pod=$2
ba=$1
command=$(kubectl -n kube-system get pods | grep ${pod} | awk '{print $1}' | head -1)
awsnode=(${command})
bold=$(tput bold)
normal=$(tput sgr0)
purple=$(tput setaf 5)
red=$(tput setaf 1)

case $ba in
before)
	# run command against random pod in array
	kubectl -n kube-system get pod ${awsnode} -oyaml >${awsnode}-before.yaml
	;;
after)
	# run command against random pod in array
	kubectl -n kube-system get pod ${awsnode} -oyaml >${awsnode}-after.yaml
	# get the file name with wildcards and store in variable
	file=$(ls *${pod}*-before.yaml)
	# diff the two files and output to screen
	echo -e "\n${bold}${purple}"
	echo -e "---------------------------------------------------------------------------------------------------------"
	echo -e "      ${file}                              |       ${awsnode}-after.yaml"
	echo -e "---------------------------------------------------------------------------------------------------------"
	echo -e "---------------------------------------------------------------------------------------------------------${normal}\n"
	sdiff -s ${file} ${awsnode}-after.yaml
	echo -e "---------------------------------------------------------------------------------------------------------"
	;;
help)
	echo -e "\n${red}Error: Please specify a pod and state.${normal}"
	echo "Usage: ./addons-upgrade.bash {before|after} {pod}"
	echo "Example: ./addons-upgrade.bash before aws-node"
	exit 1
	;;
*)
	echo -e "\n${red}Error: Use help for usage information.${normal}"
	;;
esac
