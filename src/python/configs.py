import os
import sys
from os import path

# PATHS
data_dir = path.join(os.path.abspath(os.curdir), 'fixtures')
logs_dir = path.join(os.path.abspath(os.curdir), 'data/logs')
results_dir = path.join(os.path.abspath(os.curdir), 'data/results')
rscripts_dir = path.join(os.path.abspath(os.curdir), 'src/R')

# TWITTER CREDENTIALS
""" 
    In the real world, it is not a good idea to hard code sensitive credentials 
    into your application. If you run a Twitterbot from a laptop, you could store
    and access them as environment variables. If you run a Twitterbot on AWS, 
    you might use AWS Secret Store.

    You will need to apply for a Twitter developer account at 
    https://developer.twitter.com. 

"""

twitter_consumer_key = "abc123"
twitter_consumer_secret = "abc123"
twitter_access_token = "abc123"
twitter_access_token_secret = "abc123"