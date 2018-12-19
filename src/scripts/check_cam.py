import os
import json
import requests
import re
import time
import subprocess

pIdir='/home/_processInstances/'

for dir in os.listdir(pIdir):
    theorem_conf='{}{}/theorem.conf'.format(pIdir, dir)
    conf_conf='{}{}/conf.conf'.format(pIdir, dir)
    with open(conf_conf, 'r') as file:
        status=json.loads(file.read())
        file.close()
    if status['is_active']:
        with open(theorem_conf, 'r') as file:
            port = re.search(r"(HttpPort=)(?P<port>\w+)", file.read()).group('port')
            file.close()
        try:
            response_1 = requests.get('http://127.0.0.1:{}/stat/'.format(port), timeout=1)
            samples_1 = re.search(r"(<td>Analysis total</td><td>)(?P<frames>\w+)", response_1.text).group('frames')
            time.sleep(3)
            response_2 = requests.get('http://127.0.0.1:{}/stat/'.format(port), timeout=1)
            samples_2 = re.search(r"(<td>Analysis total</td><td>)(?P<frames>\w+)", response_2.text).group('frames')
            print(samples_1)
            print(samples_2)
            if samples_1 == samples_2:
               print('{} not working'.format(dir))
#               pid = "echo $(lsof -i | grep {} | grep processIn | sed -n 1p | awk '{print $2}')".format(port)
#               pid = "echo $(lsof -i | grep {} | ".format(port) + "awk '{print $2}')"
               pid = "echo $(lsof -i | grep {} |".format(port) + " grep processIn | sed -n 1p | awk '{print $2}')"
               print(pid)
               pid = int(subprocess.check_output(pid, shell=True))
#               pid = "$(lsof -i | grep {} | ".format(port) + "awk '{print $2}')"
               print(pid)
               #p_id = os.system(pid)
               #print('pid ' + p_id)
               os.system('kill ' + str(pid))
               time.sleep(1)
               print('restarted')
            else:
               print('{} working'.format(dir))
        except:
            print('{} timeout'.format(dir))
