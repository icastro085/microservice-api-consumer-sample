const {  getEventSourceNameBasedOnEvent } = require("@vendia/serverless-express/src/event-sources/utils");
const { getEventSource } = require("@vendia/serverless-express/src/event-sources");

const EVENTS_PATH = {
  "aws:sqs": "/sqs-handler",
  "aws:s3": "/s3-handler",
};

const { log } = console;

function requestMapper({ event }) {
  const { headers, httpMethod, Records } = event;

  if (Records?.length) {
    const eventSource = event.Records[0]
      ? event.Records[0].EventSource || event.Records[0].eventSource
      : undefined

    const path = EVENTS_PATH[eventSource];

    if (!path) {
      throw new Error("EVENT SOURCE ERROR");
    }

    log("EVENT SOURCE: ", eventSource);
    log(path);

    return {
      path,
      method: "POST",
      headers,
      body: event,
    };
  }

  log("HTTP METHOD:", httpMethod);

  const eventSourceName = getEventSourceNameBasedOnEvent({ event });
  const { getRequest } = getEventSource({ eventSourceName });

  return getRequest({ event });
}


function responseMapper ({
  statusCode,
  body,
  headers,
  isBase64Encoded
}) {
  return {
    statusCode,
    body,
    headers,
    isBase64Encoded
  }
}


module.exports = {
  requestMapper,
  responseMapper,
};