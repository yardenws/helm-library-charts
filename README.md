# Helm - Library Chart exercise

- [Helm Library Chart exercise ](#helm-library-chart-exercise)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Run Demo Magic](#run-demo-magic)
  - [So Whats Helm? And how does it helps us?](#so-whats-helm?-and-how-does-it-helps-us?)
  - [Kubernetes service helm template example](#so-whats-helm?-and-how-does-it-helps-us?)
  - [Library Chart](#library-chart)
     - [Create a Library Chart](#create-a-library-chart)
     - [Library Chart - Kubernetes Service Reusable Template](#library-chart---kubernetes-service-reusable-template)
  - [Test our newly created Library Chart](#test-our-newly-created-library-chart)
  - [Concolusion](#conclusion)
  - [Resources](#resources)

## Introduction
Let’s think about the effort of deploying many resources to a Kubernetes cluster,  
long time ago, in a far far Kubernetes Cluster, we had to run multiple commands manually, in order to deploy different resources. Fun? Yes.  Efficient? Not really. 

## Prerequisites
In order to run the exercise you will need to install Helm.  
To Install Helm please refer to here:  
[Helm Installation Guide](https://helm.sh/docs/intro/install/)

## Run Demo Magic
In order to run this Helm Library Chart exercise using Demo Magic, Please navigate to /demo-magic and run the following command:  
```bash
sh demomg.sh
```
Please refer to the Resources section in order to check Demo Magic out.
  
## So Whats Helm? And how does it helps us?   
Helm provides us with a sufficient way to template and manage our Kubernetes resources as a full package and pretty much makes our lives  easier with some awesome abilities.  
  
Helm main features helps us with our day to day challenges such as: Version control of Kubernetes resources, packaging Kubernetes resources  using a human friendly templating mechanism, Deploying Kubernetes resources sufficiently and much more.  
   
> “Helm is the best way to find, share, and use software build for Kubernetes” - Helm.sh 
> 
  
Let’s say that we have an application that contains multiple Kubernetes resources such as: Deployment, Service and an Ingress.  
Usually what we will be doing is run some kubectl commands in order to deploy those resources to our Cluster. We can deploy multiple .yaml  files simultaneously when giving a folder path instead of a specific file path.  
  
For example:  
```bash
kubectl apply -f .
```
But what happens when we need to configure those specific resources? Should we go inside each .yaml file and change it manually? Big pain.  
  
Using Helm, We can edit a Values.yaml file that will contain our configuration and helm will do the rest for us.  
  
## Kubernetes Service Helm Template Example 
```bash
apiVersion: v1
kind: Service
metadata:
  name: {{ include "test-chart.fullname" . }}
  labels:
    {{- include "test-chart.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "test-chart.selectorLabels" . | nindent 4 }}
```  
We can define our Kubernetes Service Type using Values.yaml file like so:  

```bash
service:
	type: "nodePort"
```

Easy as that!  
  
## Library Charts
Lets think about a situation when we have multiple applications that needs to be packaged as Helm Charts.
Are we going to contain the templates in each Chart? We can end up having tons of identical templates in our charts that way.  
  
This is where Helm - Library Charts comes to the rescue!  
  
> “A library chart is a type of [Helm chart](https://helm.sh/docs/topics/charts/) that defines chart primitives or definitions which can be shared by Helm templates in other charts. This allows users to share snippets of code that can be re-used across charts, avoiding repetition and keeping charts [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)” - Helm.sh
> 

#### Create a Library Chart
First we need to create a Library Chart - 

```bash
# Create a Regular Chart called Library Chart
helm create librarychart

# Delete Templates as they won't be needed
rm -rf librarychart/templates/*

# Delete values.yaml as it also won't be needed
rm -f librarychart/values.yaml

```

In order to configure our newly created library-chart to act as a library chart we need to add our Chart.yaml file with the following:  

```bash
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
```

Library chart are not installable - so if we will try to install it we will get an error.  

```bash
helm install librarychart librarychart/
# Error: library charts are not installable
```

Moving on!  

#### Library Chart - Kubernetes Service Reusable Template
Let’s Create a common Kubernetes Service template again: and re-use it instead of copying it to each Chart.  
Copy the below code and create a file called _service.yaml inside librarychart/templates  

```bash
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
```

#### Test our newly created Library Chart
Let’s create a sample helm chart  

```bash
# Create the Chart
helm create sample-chart

# Delete Templates as they won't be needed
rm -rf sample-chart/templates/*
```

1st we’ll have to configure our sample-chart to be dependent on our library-chart. we can do that by adding the following code to the end of our sample-chart’s Chart.yaml.  

```bash
# My common code in my library chart
dependencies:
- name: librarychart
  version: 0.1.0
  repository: file://../librarychart
```

Afterwards we will also need to update the dependencies of our sample-chart.  

```bash
helm dependency update sample-chart/
```

In order to use the common templates which we created in the library chart we need to add the following to each chart: inside templates folder create a file with the name service.yaml and copy the below content to it.

```bash
{{- include "library-chart.service" . }}
```

Now let’s test our code 💪🏻  

Let’s add our sample-chart values.yaml file.  
Copy the below code and add it to values.yaml  

```bash
service: 
  namespace: "default"
  name: "yarden-service"
  type: "NodePort"
  port: "80"
  protocol: TCP
  targetPort: "80"
```

Lets install our helm chart!  

```bash
helm install sample-chart sample-chart/ --debug --dry-run
```

## Conclusion

Helm is a great packaging tool for Kubernetes resources, but when we grow up to use many helm charts we should consider developing a library chart to hold all of our common templates, it will make our lives easier when developing new helm charts, we’ll just need to use our common templates for every new chart we implement to our infrastructure.  
  
⎈Happy Helming!⎈  
  

## Resources
[Helm.sh](https://helm.sh/docs/)  
[Helm Library Chart Documentation](https://helm.sh/docs/topics/library_charts/#helm)  
[Demo Magic](https://github.com/paxtonhare/demo-magic)
