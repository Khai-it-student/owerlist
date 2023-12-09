#!/usr/bin/env groovy
pipeline {
 agent any
 stages {
 stage('Install') {
 steps {
 echo 'Install..'
 sh 'npm install'
 }
 }
 stage('Stop all') {
 steps {
 echo 'Stop all..'
 sh 'forever stopall'
 }
 }
 stage('Deploy') {
 steps {
 echo 'Deploying.'
 sh 'BUILD_ID=dontKillMe pm2 start app.js'
 }
 } }}
