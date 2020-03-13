import json
import pandas as pd
import shutil
import subprocess
from configs import *
from tweet import *

nicarshire = "UC0001"
tweet_log_file = f"{logs_dir}/tweet_log.txt"


def run_twitterbot(fixture, twitter_client):
    """
    Request your data. You implementation of this request
    will depend on your data source and the form it takes.

    In our production twitterbot, we have polled endpoints and consumed data published to 
    an Amazon SQS queue (via the Boto API).

    But in this demo, we'll use fixture data, as a CSV.

    Here's some fixture data for this demo:
    """

    data = pd.read_csv(f"{data_dir}/{fixture}.csv")

    """
    Get the unique ID of a jurisdiction. In the case of a UK
    general election, it's a constiuency, and each 
    constituency is associated with a unique GSSID.

    Also, get the constituency name, which will be used in the tweet's 
    status update text
    """

    gssid = data["gssId"].iloc[0]
    constituency_name = data["constituency_shortName"].iloc[0]

    """
    Once you have the ID for a jurisdiction, you need to check if 
    it has been tweeted or not. 

    This is where your tweet log comes into play - it's the 'source of 
    truth' about what your twitterbot has processed.

    Our tweet log contains the GSSID's of contsituencies that have 
    been declared and whose results have been tweeted.

    Our log items take the specific format of 
    "Tweeted <GSSID> id <tweed status id> <tweet created at time> <constituency name>

    eg. 
    "Tweeted E14001007 id 1205331757349982210 at 2019-12-13 03:40:59+00:00 nicarshire"

    """

    # First, read from the tweet log to get the log items of what's already been tweeted.
    tweets = []
    with open(tweet_log_file) as log:
        for line in log:
            tweets.append(line)

    #  We're only interested in the GSSIDs, so extract them into a list
    gssids_to_check = []
    for tweet in tweets:
        gssids_to_check.append(tweet.split(" id")[0].split("Tweeted ")[1])

    #  Create a boolean representing whether the GSSID you're looking at is in the list of GSSIDs that has been tweeted
    tweeted = gssid in gssids_to_check

    """
    If a GSSID has been tweeted, it can be ignored. 

    (You can also bring in more complex logic to check if a new result
    signifies that a correction has to be issued. 
        
    We had a dedicated Slack channel that listed for whether corrections 
    were required, and we issued corrections manually. But this 
    process could also be automated.)

    """

    if tweeted:
        print("No new results... nothing to tweet.")

    """
    But if a GSSID hasn't been tweeted, the result it 
    represents needs to be processed. 

    First create a directory named for the GSSID,
    and move the data and candidate image there.

    """
    outdir = f"{results_dir}/{gssid}"
    if not os.path.exists(outdir):
        os.mkdir(outdir)

    data = f"{outdir}/{gssid}.csv"
    candidate_picture = f"{outdir}/{gssid}_MRP.png"

    shutil.copy(f"{data_dir}/{fixture}.csv", data)
    shutil.copy(f"{data_dir}/{fixture}_MRP.png", candidate_picture)

    """
    Now that data is saved in the local filesystem
    That data can be referenced in an R script that will 
    create a graphic.
    """

    rscript = f"{rscripts_dir}/BUILD_GRAPHIC.R"
    filepath_dir = outdir
    backing_path = f"{rscripts_dir}/background.png"

    # Use Python's subprocess module to call the R script that will create the graphic
    args = f"{rscript} {data} {filepath_dir}/ {backing_path}/ {candidate_picture}"
    subprocess.call(f"/usr/local/bin/Rscript --vanilla {args}", shell=True)

    """
    Tweet the graphic with text.
    update_status returns a string, which will be appened to tweet_log.txt
    """
    tweet_text = f"RESULT: {constituency_name}"
    log_string = update_status(
        twitter_client, f"{outdir}/graphic.png", tweet_text, gssid
    )
    print(log_string)

    """
    Finally, update the tweet_log with details about the tweet that has been sent.
    """
    logfile = open(tweet_log_file, "a+")
    logfile.write(log_string)
    logfile.close()

"""
Initialise the twitter client
"""

twitter_client = initialise_twitter(
    twitter_consumer_key,
    twitter_consumer_secret,
    twitter_access_token,
    twitter_access_token_secret,
)


if __name__ == "__main__":
    run_twitterbot(nicarshire, twitter_client)
