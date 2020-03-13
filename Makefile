run_twitterbot: clean
	./run.sh

clean:
	rm -rf data/results/E14001007
	rm data/logs/tweet_log.txt
	touch data/logs/tweet_log.txt
