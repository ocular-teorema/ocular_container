#!/bin/bash

#free_space=`df | sed -n 4p | awk '{print $4}'`

while [ `df . | sed -n 2p | awk '{print $4}'` -le 419430400 ]
do
  ls '/home/_VideoArchive/' | while read line
  do
    videodir='/home/_VideoArchive/'$line
    dbdir='/home/_processInstances/'$line
    indefinitely=`cat '/home/_processInstances/'$line'/theorem.conf' | awk '/indefinitely=/' | cut -c14-`
    base='/home/_processInstances/'$line'/DB/video_analytics'

    if [ -z $indefinitely ]; then indefinitely=false; fi

    if [ -d $videodir ] && [ -d $dbdir ] && $indefinitely; then
      echo $videodir
      cd $videodir
      older_file=`ls $videodir -lth | grep 'mp4' | tail -1 | awk '{print $9}'`
      echo $older_file
      older_file_date=`stat -c %y $older_file | awk '{print $1}'`
      echo $older_file_date
      date_end=`date -d $older_file_date"+3 days" +%Y-%m-%d`
      echo $date_end
      count=`/usr/bin/find $videodir -newermt $older_file_date ! -newermt $date_end -name '*.mp4' | wc -l` 
      /usr/bin/find $videodir -newermt $older_file_date ! -newermt `date -d $older_file_date"+3 days" +%Y-%m-%d` -name '*.mp4' -delete
      echo $count
      database_date=`echo $older_file_date | tr '-' ' '`
      ucdate=`sh /usr/local/scripts/get_current_day.sh $database_date`

      su - postgres -c "psql video_analytics -c \"DELETE from records WHERE date <= $ucdate and cam='$line';\""

      su - postgres -c "psql video_analytics -c \"DELETE from events WHERE date <= $ucdate and cam='$line';\""	
    fi
  done
done


