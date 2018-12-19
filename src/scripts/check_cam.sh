ls '/home/_processInstances/' | while read line
do

  camdir='/home/_processInstances'$line
  
  conf_file='/home/_processInstances'$line'/theorem.conf'
  additional_conf_file='/home/_processInstance'$line'/conf.conf'

  port=`cat '/home/_processInstances/'$line'/theorem.conf' | awk '/HttpPort=/' | cut -c10-`
  echo $port
  is_active=$(head -n 1 '/home/_processInstances/'$line'/conf.conf')
  echo $is_active
  if [ "$is_active" = '{"is_active": true}' ] || [ "$is_active" = '{"is_active": 1}' ]; then
    echo 'cam is active, port:'$port
    check_port=`curl "127.0.0.1:"$port -m10>/dev/null 2>&1 || echo 'down'`
    if [ "$check_port" = 'down' ]; then
      echo 'port down'
      port=`lsof -i | grep $port | awk '{print $2}'`
      if [ -z  "$port" ]; then
#        supervisorctl restart theorem_worker
        echo 'killall'
      else
        kill $(lsof -i | grep $port | awk '{print $2}')
        echo "process restarted"
      fi 
    else
      echo 'port up'
    fi
  else
    echo 'non-active cam, port:'$port
  fi

done


