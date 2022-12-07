#!/usr/bin/env bash

########################
# include the magic
########################
. ./demo-magic/demo-magic.sh


########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster

TYPE_SPEED=100

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

# text color
# DEMO_CMD_COLOR=$BLACK

# hide the evidence
clear

# set up color var
red=$(tput setaf 1)

echo "${red} Helm - Library Chart Demo"
### Create Library Chart
echo "${red} Creating Library Chart...."
mkdir helm-exercise
cd helm-exercise
pe "helm create librarychart"

### Delete Templates & Values.yaml files from the library chart
echo "${red} Delete Templates & Values.yaml files..."
pe "rm -rf librarychart/templates/*"
pe "rm -f librarychart/Values.yaml"

### Generate Chart.yaml
echo "${red} Generate Chart.yaml File to set library chart as a Library Chart..."
echo "${red} To see the Chart.yaml file, Please refer to librarychart/Chart.yaml..."
rm -f librarychart/Chart.yaml
cat << EOF > librarychart/Chart.yaml
apiVersion: v2
name: librarychart
description: A Helm chart for Kubernetes

# A chart can be either an 'application' or a 'library' chart.
#
# Application charts are a collection of templates that can be packaged into versioned archives
# to be deployed.
#
# Library charts provide useful utilities or functions for the chart developer. They're included as
# a dependency of application charts to inject those utilities and functions into the rendering
# pipeline. Library charts do not define any templates and therefore cannot be deployed.
# type: application
type: library

# This is the chart version. This version number should be incremented each time you make changes
# to the chart and its templates, including the app version.
version: 0.1.0

# This is the version number of the application being deployed. This version number should be
# incremented each time you make changes to the application and it is recommended to use it with quotes.
appVersion: "1.16.0"
EOF

## Try to install the Library Chart to show the user it will run into an error.
echo "${red} Trying to install the Library Chart - An Error is expected..."
pe "helm install librarychart librarychart/"

## Create Kubernetes Service Common Template
echo "${red} Creating Kubernetes Service common template..."
echo "${red} To view the template please refer to librarychart/templates/_service.yaml"
cat << EOF > librarychart/templates/_service.yaml
{{- define "library-chart.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.service.name }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - protocol: {{ .Values.service.portProtocol }}
      port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
{{- end }}
EOF

## Create Sample Chart to test our Library Chart
echo "${red} Create a new sample-chart to test our Library Chart..."
pe "helm create sample-chart"
echo "${red} Remove templates as they won't be necessary"
pe "rm -rf sample-chart/templates/*"

## Add Dependencies to Sample-chart
echo "${red} Adding dependencies block to sample-chart Chart.yaml..."
rm -rf sample-chart/Chart.yaml
cat <<EOF > sample-chart/Chart.yaml
apiVersion: v2
name: sample-chart
description: A Helm chart for Kubernetes

# A chart can be either an 'application' or a 'library' chart.
#
# Application charts are a collection of templates that can be packaged into versioned archives
# to be deployed.
#
# Library charts provide useful utilities or functions for the chart developer. They're included as
# a dependency of application charts to inject those utilities and functions into the rendering
# pipeline. Library charts do not define any templates and therefore cannot be deployed.
type: application

# This is the chart version. This version number should be incremented each time you make changes
# to the chart and its templates, including the app version.
# Versions are expected to follow Semantic Versioning (https://semver.org/)
version: 0.1.0

# This is the version number of the application being deployed. This version number should be
# incremented each time you make changes to the application. Versions are not expected to
# follow Semantic Versioning. They should reflect the version the application is using.
# It is recommended to use it with quotes.
appVersion: "1.16.0"

# My common code in my library chart
dependencies:
- name: librarychart
  version: 0.1.0
  repository: file://../librarychart
EOF
echo "${red} To view the dependency block, please refer to sample-chart/Chart.yaml end of the file..."

## Update Sample-chart dependencies
echo "${red} Update sample-chart dependencies..."
pe "helm dependency update sample-chart"

## Create service.yaml template in Sample-chart to call the common template from the Library Chart.
echo "${red} Generate service.yaml in Sample-chart/templates which will call our newly common _service.yaml template from Library Chart..."
cat << EOF > sample-chart/templates/service.yaml
{{- include "library-chart.service" . }}
EOF
echo "${red} To view the service.yaml file, Refer to sample-chart/templates/service.yaml..."

## Testing our code - Editing Values.yaml file
echo "${red} Lets Test Our Code!..."
echo "${red} Generate values.yaml file!..."
rm -f sample-chart/values.yaml
cat << EOF > sample-chart/values.yaml
service: 
  namespace: "default"
  name: "sample-service"
  type: "NodePort"
  port: "80"
  protocol: TCP
  targetPort: "80"
EOF
echo "${red} To view the values.yaml file, Please refer to sample-chart/values.yaml!..."

## Install Sample Chart
echo "${red} Installing Sample-Chart - Don't worry, it's in dry-run mode :)..."
pe "helm install sample-chart sample-chart/ --debug --dry-run"


echo "${red} To Clean the environment - Please run the following: 'rm -rf helm-exercise'"
