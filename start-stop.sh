#!/bin/sh
USER='LINUX_USER' # edson
APP='SPRINGBOOT_JAR' #springboot.jar
STDOUT='LOG' # /home/USER/logs/stdout.log
JAR_HOME='PATH_APP' # /home/USER/$APP
JAVA_HOME='JDK_HOME' # /usr/java/jdk-11/
PROPERTIES='application.yml' # /home/USER/application.yml | /home/USER/application.properties
#Memory
XMS='-Xms128M'
XMX='-Xmx256M'
META_SPACE='-XX:MetaspaceSize=100M'
MAX_META_SPACE='-XX:MaxMetaspaceSize=256M'

jps=`ps wwwaux | egrep -w $USER | egrep  ".*java.*-jar.*$JAR_HOME.*" |  egrep -v egrep|awk '{printf $2" "}'`


if [ -z "$STARTUP_WAIT" ]; then
	STARTUP_WAIT=10
fi

if [ -z "$SHUTDOWN_WAIT" ]; then
	SHUTDOWN_WAIT=10
fi

case $1 in
start)
    # rodando?
    if [ ! -z "$jps" ]; then
      echo "$APP is running (pid $jps) ";
      exit 1;
    else
      echo "Starting $APP ..."


      `/usr/bin/nohup $JAVA_HOME/bin/java -jar $JAR_HOME  --spring.config.location=$PROPERTIES $XMS $XMX $META_SPACE $MAX_META_SPACE  > $STDOUT 2>&1 &`

        count=0
        launched=false

        until [ $count -gt $STARTUP_WAIT ]
        do
                grep 'Started' $STDOUT > /dev/null
                if [ $? -eq 0 ] ; then
                        launched=true
                        break
                fi
                sleep 1
                let count=$count+1;
        done

        if  $launched ; then
          echo "$APP Started"
        else
          echo "$APP not running"
        fi

     fi ;;
stop|kill)
	count=0
    if [ -z "$jps" ]; then
        echo "$APP not running"
    else
		let kwait=$SHUTDOWN_WAIT
        if [ $1 = 'kill' ]; then KSIGNAL='-9' ; else KSIGNAL='-15' ; fi
        echo "Stopping $APP"

        kill $KSIGNAL $jps 2>/dev/null
		until [ `ps --pid $jps 2> /dev/null | grep -c $jps 2> /dev/null` -eq '0' ] || [ $count -gt $kwait ]
			do
			sleep 1
			let count=$count+1;
		done

		if [ $count -gt $kwait ]; then
			kill -9 $jps
		fi
    fi ;;
*)
    echo "Use $0 [stop|start|kill]" ;;
esac
