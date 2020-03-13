import tweepy
import pytz
import datetime


def initialise_twitter(
    twitter_consumer_key,
    twitter_consumer_secret,
    twitter_access_token,
    twitter_access_token_secret,
):
    auth = tweepy.OAuthHandler(twitter_consumer_key, twitter_consumer_secret)
    auth.set_access_token(twitter_access_token, twitter_access_token_secret)

    api = tweepy.API(auth, retry_count=10, retry_delay=5, retry_errors=set([503, 500]))

    return api


"""
Posts a Tweet to a timeline. 

Note: support for accessibily (alt text) should be available in Tweepy version 3.9
see https://github.com/tweepy/tweepy/issues/1247
"""


def update_status(api, path_to_image, tweet_text, gssid):
    try:
        image = api.media_upload(path_to_image)
        status = api.update_status(status=tweet_text, media_ids=[image.media_id_string])
        created_at = status._json["created_at"]
        tweet_id = status._json["id_str"]

        return (
            f"Tweeted {gssid} id {tweet_id}"
            f" at {datetime_to_local(created_at)}"
        )

    except Exception as e:
        print(
            f"""
            Error tweeting result for {gssid} \n
            Tweeet text was: {tweet_text}
            Image path was {path_to_image}
            {e}
            """
        )


def datetime_to_local(created_at):
    """
    Get the tweeted time in UTC, convert to local (Europe/London) 
    For logging use only
    """
    d = datetime.datetime.strptime(created_at, "%a %b %d %H:%M:%S +0000 %Y")
    d = pytz.UTC.localize(d)  # add timezone info
    europe_london = pytz.timezone("Europe/London")

    return d.astimezone(europe_london)
