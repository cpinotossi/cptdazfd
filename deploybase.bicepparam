using './deploybase.bicep'

param location  = readEnvironmentVariable('location', 'eastus')
param username  = 'chpinoto'
param password  = 'demo!pass123'
param prefix   = readEnvironmentVariable('prefix', 'cptdazfd')
param vmip = '10.0.0.4'
param cidervnet = '10.0.0.0/16'
param cidersubnet = '10.0.0.0/24'
param ciderbastion = '10.0.1.0/24'
param myip = readEnvironmentVariable('myip', '')
param myobjectid = readEnvironmentVariable('currentUserObjectId', '')
