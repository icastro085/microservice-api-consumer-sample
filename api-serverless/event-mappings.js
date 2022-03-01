const EVENTS_PATH = {
  "aws:sqs": "/sqs-hanlder",
};

function requestMapper({ event }) {
  const { path, headers, httpMethod, Records } = event

  if (Records?.length) {
    const { eventSource, body } = Records[0];
    const path = EVENTS_PATH[eventSource];

    if (!path) {
      throw new Error("EVENT SOURCE ERROR");
    }

    console.log("EVENT SOURCE: ", eventSource);
    console.log(path);

    return {
      path,
      method: "POST",
      headers,
      body,
    };
  }

  console.log("HTTP METHOD:", httpMethod);

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
  // Your logic here...

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