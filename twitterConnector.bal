import ballerina.lang.messages;
import ballerina.lang.strings;
import ballerina.lang.system;
import ballerina.net.http;
import ballerina.net.uri;
import ballerina.utils;
import ballerina.lang.arrays;
import ballerina.lang.maps;

connector Twitter(string consumerKey, string consumerSecret, string accessToken, string accessTokenSecret) {
    http:ClientConnector tweeterEP = create http:ClientConnector("https://api.twitter.com");
    http:ClientConnector tweeterEP2 = create http:ClientConnector("https://stream.twitter.com");

    action tweet(Twitter t, string msg)(message ) {
        message request = {};
        string oauthHeader = constructOAuthHeader(consumerKey, consumerSecret, accessToken, accessTokenSecret, msg);
        string tweetPath = "/1.1/statuses/update.json?status=" + uri:encode(msg);
        messages:setHeader(request, "Authorization", oauthHeader);
        message response = http:ClientConnector.post(tweeterEP, tweetPath, request);
        return response;
    
    }

    action search(Twitter t, string query) (message) {
        message request = {};
        map parameters = {};
        string urlParams;
        string tweetPath = "/1.1/search/tweets.json";
        query = uri:encode(query);
        parameters["q"] = query;
        urlParams = "q=" + query;
        constructRequestHeaders(request, "GET", tweetPath, consumerKey, consumerSecret, accessToken,
                                accessTokenSecret, parameters);
        tweetPath = tweetPath + "?" + urlParams;

        message response = http:ClientConnector.get(tweeterEP, tweetPath, request);

        return response;
    }
}
function constructRequestHeaders(message request, string httpMethod, string serviceEP, string consumerKey,
                                 string consumerSecret, string accessToken, string accessTokenSecret, map parameters) {
    int index;
    string paramStr;
    string key;
    string value;

    string timeStamp = strings:valueOf(system:epochTime());
    string nonceString = utils:getRandomString();
    serviceEP = "https://api.twitter.com" + serviceEP;

    parameters["oauth_consumer_key"] = consumerKey;
    parameters["oauth_nonce"] = nonceString;
    parameters["oauth_signature_method"] = "HMAC-SHA1";
    parameters["oauth_timestamp"] = timeStamp;
    parameters["oauth_token"] = accessToken;
    parameters["oauth_version"] = "1.0";

    string[] parameterKeys = maps:keys(parameters);
    string[] sortedParameters = arrays:sort(parameterKeys);
    while (index < sortedParameters.length){
        key =  sortedParameters[index];
        value, _ = (string) parameters[key];
        paramStr = paramStr + key + "=" + value + "&";
        index = index + 1;
    }
    paramStr = strings:subString(paramStr, 0, strings:length(paramStr)-1);
    string baseString = httpMethod + "&" + uri:encode(serviceEP) + "&" + uri:encode(paramStr);
    string keyStr = uri:encode(consumerSecret) + "&" + uri:encode(accessTokenSecret);
    string signature = utils:getHmac(baseString, keyStr, "SHA1");
    string oauthHeaderString = "OAuth oauth_consumer_key=\"" + consumerKey +
                               "\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"" + timeStamp +
                               "\",oauth_nonce=\"" + nonceString + "\",oauth_version=\"1.0\",oauth_signature=\"" +
                               uri:encode(signature) + "\",oauth_token=\"" + uri:encode(accessToken) + "\"";

    messages:setHeader(request, "Authorization", strings:unescape(oauthHeaderString));
}
function constructOAuthHeader(string consumerKey, string consumerSecret, string accessToken, string accessTokenSecret, string tweetMessage)(string ) {
    string timeStamp = strings:valueOf(system:epochTime());
    string nonceString = utils:getRandomString();
    string paramStr = "oauth_consumer_key=" + consumerKey + "&oauth_nonce=" + nonceString + "&oauth_signature_method=HMAC-SHA1&oauth_timestamp=" + timeStamp + "&oauth_token=" + accessToken + "&oauth_version=1.0";
    string baseString = "GET&" + uri:encode("https://api.twitter.com/1.1/search/tweets.json") + "&" + uri:encode
                                                                                                      (paramStr);
    string keyStr = uri:encode(consumerSecret) + "&" + uri:encode(accessTokenSecret);
    string signature = utils:getHmac(baseString, keyStr, "SHA1");
    string oauthHeader = "OAuth oauth_consumer_key=\"" + consumerKey + "\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"" + timeStamp + "\",oauth_nonce=\"" + nonceString + "\",oauth_version=\"1.0\",oauth_signature=\"" + uri:encode(signature) + "\",oauth_token=\"" + uri:encode(accessToken) + "\"";
    return strings:unescape(oauthHeader);
    
}

function main(string[] args) {
    Twitter twitterConnector = create Twitter(args[0], args[1], args[2], args[3]);
    message tweetResponse = Twitter.search(twitterConnector, args[4]);
    system:println(tweetResponse);
    http:ClientConnector tweeterEP = create http:ClientConnector("http://localhost:8005");
    json payload =  {"Customer": {"ID": "987654", "Name": "ABC PQR","Description": "Sample Customer."}};
    message request = {};
    messages:setJsonPayload(request, payload);
    string tweetPath = "/ep";
    message response = http:ClientConnector.post(tweeterEP, tweetPath, request);
    system:println(request);
    //Twitter twitterConnector = create Twitter(args[0], args[1], args[2], args[3]);
    //message tweetResponse = Twitter.stream(twitterConnector, args[4]);
    ////system:println(tweetResponse);
    //import ballerina.lang.jsons;
    //json tweetJSONResponse = messages:getJsonPayload(tweetResponse);
    //system:println(jsons:toString(tweetJSONResponse));


    //message req = {};
    //messages:setJsonPayload(req, payload);
    //message response = customerMgt(req);

}
