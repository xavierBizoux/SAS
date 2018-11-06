#!/usr/bin/python
#
# updatePreferences.py
# Xavier Bizoux, GEL
# October 2018
#
# Update user preferences for a single user of a group of users
#
# Change History
#
# sbxxab 30OCT2018 first version  
# sbxxab 05NOV2018 add support for nested groups update
#
####################################################################
#### DISCLAIMER                                                 ####
####################################################################
#### This program  provided as-is, without warranty             ####
#### of any kind, either express or implied, including, but not ####
#### limited to, the implied warranties of merchantability,     ####
#### fitness for a particular purpose, or non-infringement.     ####
#### SAS Institute shall not be liable whatsoever for any       ####
#### damages arising out of the use of this documentation and   ####
#### code, including any direct, indirect, or consequential     ####
#### damages. SAS Institute reserves the right to alter or      ####
#### abandon use of this documentation and code at any time.    ####
#### In addition, SAS Institute will provide no support for the ####
#### materials contained herein.                                ####
####################################################################

####################################################################
#### COMMAND LINE EXAMPLE                                       ####
####################################################################
#### ./updatePreferences.py -a myAdmin                          ####
####                        -p myAdminPW                        ####
####                        -sn http://myServer.sas.com:80      ####
####                        -an app                             ####
####                        -as appsecret                       ####
####                        -t user                             ####
####                        -tn myUser                          ####
####                        -pi VA.geo.drivedistance.unit       ####
####                        -pv kilometers                      ####
####################################################################
#### POSSIBLE VALUES                                            ####
####################################################################
#### sas.welcome.suppress = true/false                          #### 
#### sas.drive.show.pinned = true/false                         #### 
#### VA.geo.drivedistance.unit = kilometers/miles               #### 
#### OpenUI.Theme.Default = sas_corporate/sas_inspire/sas_hcb   #### 
####################################################################

import requests 
import json 
import xml.etree.ElementTree as ET
import argparse

# Define arguments for command line execution
parser = argparse.ArgumentParser(description="Update user preferences for a user or a group of users")
parser.add_argument("-a", "--adminuser", help="User used for the Viya connection and who will update the preferences.", required=True)
parser.add_argument("-p", "--password", help="Password for the administrater user.", required=True)
parser.add_argument("-sn", "--servername", help="URL of the Viya environment (including protocol and port).", required= True)
parser.add_argument("-an", "--applicationname", help="Name of the application defined based on information on https://developer.sas.com/apis/rest/", required=True)
parser.add_argument("-as", "--applicationsecret", help="Secret for the application based on information on https://developer.sas.com/apis/rest/", required=True )
parser.add_argument("-t", "--target", help="Type the target of the update: user or group", required=True, choices=['user', 'group'])
parser.add_argument("-tn", "--targetname", help="ID of the user or group to which the update applies.", required=True)
parser.add_argument("-pi", "--preferenceid", help="ID of the preference to be updated", required=True)
parser.add_argument("-pv", "--preferencevalue", help="Value to be set for the preference", required=True)

# Read the arguments from the command line
args = parser.parse_args()
adminUser = args.adminuser
adminPW = args.password
serverName = args.servername
applicationName = args.applicationname
applicationSecret = args.applicationsecret
target = args.target
targetName = args.targetname
preferenceID = args.preferenceid
preferenceValue = args.preferencevalue

# Function to authenticate the administrative user and get the authentication token
def authenticateUser (serverName, adminUser, adminPW, appName, appSecret):
    auth_r = requests.post(serverName + "/SASLogon/oauth/token", 
    data= {"grant_type":"password", "username": adminUser, "password": adminPW},
    auth=(appName, appSecret), headers={'Content-type': 'application/x-www-form-urlencoded'})
    accessToken = auth_r.json()['access_token']
    return accessToken;

# Function to update preference of a specific user
def updatePreference(serverName, accessToken, userID, preferenceID, preferenceValue):
    prefUpdate = requests.put(serverName + "/preferences/preferences/"+ userID +"/" + preferenceID, 
    json= {"application": "SAS Visual Analytics", "version": 1,"id": preferenceID ,"value": preferenceValue},
    headers = {'accept': 'application/vnd.sas.preference+json', 'content-type': 'application/vnd.sas.preference+json', 'authorization': 'Bearer ' + accessToken} )
    if prefUpdate.status_code == 200 :
        print('Preference for "'+ preferenceID +'" has been set to "' + preferenceValue + '" for user ' + userID)
    else:
        print('Preference for "'+ preferenceID +'" failed to update for user ' + userID + ' with code:' + prefUpdate.status_code)
    return;

# Function to collect recursively the users in a group
def scanGroup (serverName, accessToken, targetName):
    global usersList
    getUsers = requests.get(serverName + '/identities/groups/'+ targetName +'/members?limit=1000', headers = { 'content-type': 'application/vnd.sas.identity+json','authorization': 'Bearer ' + accessToken} )
    root = ET.fromstring(getUsers.text)
    for child in root:
        if child.tag == "items":
            for el in child:
                if el[4].text == "group" :
                    scanGroup (serverName, token, el[1].text)
                else:
                    usersList.append(el[1].text)

# Authenticate administrative user and get authentication token
token = authenticateUser(serverName, adminUser, adminPW, applicationName, applicationSecret)

# List users to update
usersList = []
if target == 'user':
    usersList.append(targetName)
else :
    scanGroup(serverName, token, targetName)

# Update preference for the users in the list
for user in usersList:
    updatePreference(serverName, token, user, preferenceID, preferenceValue)
