const EVENTS_PATH = {
  "aws:sqs": "/sqs-handler",
  "aws:s3": "/s3-handler",
};

const { log } = console;

function requestMapper({ event }) {
  const { path, headers, httpMethod, Records } = event;

  if (Records?.length) {
    const { eventSource } = Records[0];
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

  return {
    path,
    method: httpMethod,
    headers,
  };
}

function responseMapper({
  statusCode,
  body,
  headers,
  isBase64Encoded,
}) {
  return {
    statusCode,
    body,
    headers,
    isBase64Encoded,
  };
}

module.exports = {
  requestMapper,
  responseMapper,
};