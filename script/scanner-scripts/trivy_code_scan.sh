#!/bin/bash -e

echo "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$-inside trivy_code_scan.sh$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"
validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE
cd package-cache
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo $validate_build_script

if [ $validate_build_script == true ];then
        echo "+++++++++++++++++++++++++++inside if++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	TRIVY_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
	wget https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VERSION#v}_Linux-PPC64LE.tar.gz
	tar -xzf trivy_${TRIVY_VERSION#v}_Linux-PPC64LE.tar.gz
        chmod +x trivy
        sudo mv trivy /usr/bin
	echo "Executing trivy scanner"
	sudo trivy -q fs --timeout 30m -f json ${cloned_package} > trivy_source_vulnerabilities_results.json
 	#cat trivy_source_vulnerabilities_results.json
	sudo trivy -q fs --timeout 30m -f cyclonedx ${cloned_package} > trivy_source_sbom_results.cyclonedx
 	#cat trivy_source_sbom_results.cyclonedx
 fi

 echo "+++++++++++++++++++++++++++outside if+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
