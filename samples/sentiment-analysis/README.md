# A more realistic sample

With this sample, we will setup an app composed of many pods. with 2 backend and 1 frontend.
The sample is baseed on this [page](https://www.freecodecamp.org/news/learn-kubernetes-in-under-3-hours-a-detailed-guide-to-orchestrating-containers-114ff420e882/).
This page help you to learn kubernetes in 3 hours.
I advice you to follow the tutorial of this page.

This is just the last stop of this tutorial adapted to our cluster.

## Description

The application is a simple webapp which calculate the "sentiment" of the sentence.
The application is composed of 3 part:
- The UI in vue.js in an Nginx server
- The backend which is a a spring-boot application provided a Rest API
- The sentiment algorithm in the Python language

![The application shema](https://cdn-media-1.freecodecamp.org/images/JwIBwPsTfBmelKgSrCCkEZuTzC5Ty1pZi3K7)

## Setup the application

1 Create a namespace
```shell script
kubectl -n sentiment-analysis get svc
```
2 Deploy the app
```shell script
kubectl create -f samples/sentiment-analysis/app/
```
3 Check that the app is well deployed
```shell script
kubectl -n sentiment-analysis get all 
```
4 Set the Ingress Resource
The Ingress controller should be setup. If not go [here](../../ingress/README.md)
We would like access the UI using this url: `http://sentiments.example.com/`
To to that deploy the Ingress resource: 
```shell script
kubectl create -f samples/sentiment-analysis/ingress-sa-frontend.yaml
```
And add this line in the file `/etc/hosts`.
```shell script
172.42.42.200 sentiments.example.com sentiments
```
5. Test the application
go to http://sentiments.example.com/ and write a sentance.
Enjoy!
