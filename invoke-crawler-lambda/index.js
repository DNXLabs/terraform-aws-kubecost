const { GlueClient, StartCrawlerCommand } = require('@aws-sdk/client-glue');
exports.handler = function (event, context, callback) {
  const glue = new GlueClient();
  const input = {
    Name: process.env.CRAWLER_NAME,
  };
  const command = new StartCrawlerCommand(input);
  glue.send(command, function (err, data) {
    if (err) {
      const responseData = JSON.parse(this.httpResponse.body);
      if (responseData['__type'] == 'CrawlerRunningException') {
        callback(null, responseData.Message);
      } else {
        const responseString = JSON.stringify(responseData);
        console.error(responseString)
        callback(responseString);
      }
    } else {
      callback(null, response.SUCCESS);
    }
  });
};