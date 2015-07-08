while true; do 
	curl http://127.0.0.1:9292/v2/poller/poke -m 1 1>/dev/null 2>&1
	sleep 2
done
