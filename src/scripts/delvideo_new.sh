#!/bin/bash
LOCK=/usr/local/scripts/delvideo_new.lck

if [ -f $LOCK ] ; then
        echo "Already running delvideo.sh on ${HOSTNAME}!" 
        exit 1
fi

touch $LOCK
echo '====================STARTED AT '`date`'===================='

ls '/home/_VideoArchive/' | while read line
do

#  videodir='/home/_VideoArchive/'`echo $line | awk '{print $1}'`
#  dbdir='/home/_processInstances/'`echo $line | awk '{print $1}'`

  videodir='/home/_VideoArchive/'$line
  dbdir='/home/_processInstances/'$line

  if [ -d $videodir ] && [ -d $dbdir ]; then
        echo "${videodir} and ${dbdir} exist"
  elif [ -d $videodir ] && [ ! -d $dbdir ]; then
        echo "${dbdir} not exist"
        echo "start rm ${dbdir}"
        rm -r $videodir
  else
        echo "!!! ERROR !!!" 
        echo "${videodir} or ${dbdir} not found"
        exit 1
  fi

  #base='/home/_processInstances/'$line'/DB/video_analytics'
  #days='30'
  #statistic=`cat '/home/processInstances/'$line'/theorem.conf' | awk '/statisticPeriodDays=/' | cut -c21`  

  days=`cat '/home/_processInstances/'$line'/theorem.conf' | awk '/storage_life=/' | cut -c14-`

  if [ -z $days ]; then days=30; fi

  cdate=`date '+%G %m %d' --date "-${days} days"`
  ucdate=`sh /usr/local/scripts/get_current_day.sh $cdate`
 
  count=`/usr/bin/find $videodir -mtime +$days -name "*.mp4" | wc -l`
  /usr/bin/find $videodir -mtime +$days -name "*.mp4" -delete
  echo "$count файлов старше $days дней успешно удалены из папки $videodir"
  
  su - postgres -c "psql video_analytics -c \"DELETE from records WHERE date <= $ucdate and cam='$line';\""

  su - postgres -c "psql video_analytics -c \"DELETE from events WHERE date <= $ucdate and cam='$line';\""	

done

echo '====================FINISHED AT '`date`'===================='

rm -rf $LOCK


