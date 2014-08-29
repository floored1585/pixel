while true; do 
	curl http://127.0.0.1:9292/v1/poller/poke &
	sleep 1
done
