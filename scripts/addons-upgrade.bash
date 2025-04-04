#!/bin/bash
#
# Variables
ba=$1
p=$2
p2=$3
command=$(kubectl -n kube-system get pods | grep ${p} | awk '{print $1}' | head -1)
awsnode=(${command})
bold=$(tput bold)
normal=$(tput sgr0)
purple=$(tput setaf 5)
red=$(tput setaf 1)

case $ba in
check)
## get the version of the addons for the kubernetes version and remove [] and AddonVersion from the output
	kp=`eksctl utils describe-addon-versions --kubernetes-version ${p} --name kube-proxy | grep AddonVersion | awk '{print $2}' | tr -d '[],'`
	ckp=`eksctl utils describe-addon-versions --kubernetes-version ${p2} --name kube-proxy | grep AddonVersion | awk '{print $2}' | tr -d '[],'`
	vci=`eksctl utils describe-addon-versions --kubernetes-version ${p} --name vpc-cni | grep AddonVersion | awk '{print $2}' | tr -d '[],'`
	cvci=`eksctl utils describe-addon-versions --kubernetes-version ${p2} --name vpc-cni | grep AddonVersion | awk '{print $2}' | tr -d '[],'`
	cdn=`eksctl utils describe-addon-versions --kubernetes-version ${p} --name coredns | grep AddonVersion | awk '{print $2}' | tr -d '[],'`
	ccdn=`eksctl utils describe-addon-versions --kubernetes-version ${p2} --name coredns | grep AddonVersion | awk '{print $2}' | tr -d '[],'`

# Kube-Proxy
	command=$(kubectl -n kube-system get pods | grep kube-proxy | awk '{print $1}' | head -1)
	kversion=$(kubectl -n kube-system get pods ${command} -o jsonpath='{.spec.containers[0].image}' | cut -d ':' -f2)
	
	echo -e "\n${bold}${purple}"
	echo -e "---------------------------------------------------------------------------------------------------------"
	printf " | %-90s\n" "Addon Image Compatibility Check"
	echo -e "---------------------------------------------------------------------------------------------------------${normal}"

	echo -e "\n${bold}${purple}"
	echo -e "---------------------------------------------------------------------------------------------------------"
	printf "| %-90s\n" "cluster version: ${kversion}"
	printf "| Please check the compatibility of the kube-proxy cluster version with the kubernetes version\n"
	echo -e "---------------------------------------------------------------------------------------------------------"
	printf "| %-10s | %-40s | %-40s\n" "Kube-Proxy" "Kubernetes Version ${p}" "Kubernetes Version ${p2}"
	echo -e "---------------------------------------------------------------------------------------------------------${normal}\n"
	kp_array=(${kp})
	ckp_array=(${ckp})
	for ((i=0; i<${#kp_array[@]}; i++)); do
		printf "| %-10s | %-40s | %-40s\n" "" "${kp_array[$i]}" "${ckp_array[$i]}"
	done
	echo -e "---------------------------------------------------------------------------------------------------------"

# VPC-CNI
	command=$(kubectl -n kube-system get pods | grep aws-node | awk '{print $1}' | head -1)
	kversion=$(kubectl -n kube-system get pods ${command} -o jsonpath='{.spec.containers[0].image}' | cut -d ':' -f2)
	

	echo -e "\n${bold}${purple}"
	echo -e "---------------------------------------------------------------------------------------------------------"
	printf "| %-90s\n" "cluster version: ${kversion}"
	printf "| Please check the compatibility of the VPC-CNI cluster version with the kubernetes version\n"
	echo -e "---------------------------------------------------------------------------------------------------------"
	printf "| %-10s | %-40s | %-40s\n" "VPC-CNI" "Kubernetes Version ${p}" "Kubernetes Version ${p2}"
	echo -e "---------------------------------------------------------------------------------------------------------${normal}\n"
	vci_array=(${vci})
	cvci_array=(${cvci})
	for ((i=0; i<${#vci_array[@]}; i++)); do
		printf "| %-10s | %-40s | %-40s\n" "" "${vci_array[$i]}" "${cvci_array[$i]}"
	done
	echo -e "---------------------------------------------------------------------------------------------------------"
	
# CoreDNS
	command=$(kubectl -n kube-system get pods | grep coredns | awk '{print $1}' | head -1)
	kversion=$(kubectl -n kube-system get pods ${command} -o jsonpath='{.spec.containers[0].image}' | cut -d ':' -f2)
	

	echo -e "\n${bold}${purple}"
	echo -e "---------------------------------------------------------------------------------------------------------"
	printf "| %-90s\n" "cluster version: ${kversion}"
	printf "| Please check the compatibility of the CoreDNS cluster version with the kubernetes version\n"
	echo -e "---------------------------------------------------------------------------------------------------------"
	printf "| %-10s | %-40s | %-40s\n" "CoreDNS" "Kubernetes Version ${p}" "Kubernetes Version ${p2}"
	echo -e "---------------------------------------------------------------------------------------------------------${normal}\n"
	cdn_array=(${cdn})
	ccdn_array=(${ccdn})
	for ((i=0; i<${#cdn_array[@]}; i++)); do
		printf "| %-10s | %-40s | %-40s\n" "" "${cdn_array[$i]}" "${ccdn_array[$i]}"
	done
	echo -e "---------------------------------------------------------------------------------------------------------"
	;;
before)
	kubectl -n kube-system get pod ${awsnode} -oyaml >${awsnode}-before.yaml
	;;
after)
	kubectl -n kube-system get pod ${awsnode} -oyaml >${awsnode}-after.yaml
	file=$(ls *${p}*-before.yaml)
	echo -e "\n${bold}${purple}"
	echo -e "---------------------------------------------------------------------------------------------------------"
	echo -e "      ${file}                              |       ${awsnode}-after.yaml"
	echo -e "---------------------------------------------------------------------------------------------------------"
	echo -e "---------------------------------------------------------------------------------------------------------${normal}\n"
	sdiff -s ${file} ${awsnode}-after.yaml
	echo -e "---------------------------------------------------------------------------------------------------------"
	;;
help)
	echo -e "\n${bold}${purple}Usage:${normal}"
	echo "check: runs a check on the compatibility versions for addons for the kubernetes versions inputted"
	echo "	- parameters: {upgrade-kubernetes-version} {current-kubernetes-version}"
	echo "	- Usage: ./addons-upgrade.bash {check} {upgrade-kubernetes-version} {current-kubernetes-version}"
	echo "	- Example: ./addons-upgrade.bash check 1.29 1.28"

	echo "before: get the yaml of the pod before the upgrade to be used in diff after the upgrade"
	echo "	- parameters: {aws-node|kube-proxy|coredns}"
	echo " 	- Usage: ./addons-upgrade.bash {before} {pod}"
	echo " 	- Example: ./addons-upgrade.bash before aws-node"

	echo "after: get the yaml of the pod after the upgrade and do a diff on the before and after yaml for changes"
	echo "	- parameters: {aws-node|kube-proxy|coredns}"
	echo " 	- Usage: ./addons-upgrade.bash {after} {pod}"
	echo " 	- Example: ./addons-upgrade.bash after aws-node"

	echo "help - display the usage information"
	exit 1
	;;
*)
	echo -e "\n${red}Error: Use help for usage information.${normal}"
	;;
esac
