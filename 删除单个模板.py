使用说明：
该脚本是为了只删除掉一个或几个匹配到的模板，，在文中写入要删除的模板名称，在同级目录下编辑ip.txt文件，写入hostname,执行即可。


#!/usr/bin/env python
# -*- coding: utf-8 -*-
import requests
#import urllib2
import json

url = 'http://10.9.1.22/api_jsonrpc.php'
username = 'Admin'
password = '0rC4wPZ$dCZvXUzC'

headers = {'Content-Type': 'application/json-rpc'}

# 登陆
def requestJson(url, values):
    data = json.dumps(values).encode('utf-8')
    req = json.loads(requests.post(url, data, headers={'Content-Type': 'application/json-rpc'}).text)
    output = req
    #    print output
    try:
        message = output['result']
    except:
        message = output['error']['data']
        print(message)
        quit()

    return output['result']


##登陆的API
def authenticate(url, username, password):
    values = {'jsonrpc': '2.0',
              'method': 'user.login',
              'params': {
                  'user': username,
                  'password': password
              },
              'id': '0'
              }
    idvalue = requestJson(url, values)
    return idvalue


# auth的值
auth = authenticate(url, username, password)

def template():
    data = {
        "jsonrpc": "2.0",
        "method": "template.get",
        "params": {},
        "auth": auth,
        "id": 1
    }

    html = json.loads(requests.post(url, data=json.dumps(data), headers=headers).text)['result']

    temp = {}
    data_list = []
    for i in html:
       # if i['name'] in ('GlusterFS_Cluster','GPU_Cluster_TrainK8S','Service_openldap'):
        if i['name'] in ('Template_GPU_Base'):
            data_list.append(i['templateid'])
    return data_list

def get_hosts(files):
    datas = []
    with open(files, 'r') as f:
        for i in f.readlines():
            data = {
                "jsonrpc": "2.0",
                "method": "host.get",
                "params": {
                    "filter": {
                    "host": [
                        i.strip()
                    ]
                    }
                },
                "auth": auth,
                "id": 1
            }
            text = json.loads(requests.post(url, data=json.dumps(data), headers=headers).text)
            for i in text['result']:
                datas.append(i['hostid'])
    return datas

def update_hosts():
    s = map(lambda x:{'templateid': x} ,template())
    hosts = get_hosts('ip.txt')
    for i in hosts:
        data = {
        "jsonrpc": "2.0",
        "method": "host.update",
        "params": {
            "hostid": i,
            #"templates": template(),
            "templates_clear": s

        },
        "auth": auth,
        "id": 1
        }
        text = json.loads(requests.post(url, data=json.dumps(data), headers=headers).text)
        print(text)

if __name__ == '__main__':
    update_hosts()