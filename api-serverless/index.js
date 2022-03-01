const serverlessExpress = require("@vendia/serverless-express");
const app = require("./app");
const { requestMapper, responseMapper } = require("./event-mappings");

let serverlessExpressInstance;

function asyncTask() {
  return new Promise((resolve) => {
    setTimeout(() => resolve('connected to database'), 1000);
  });
}

async function setup(event, context) {
  const asyncValue = await asyncTask();
  console.log(asyncValue);

  serverlessExpressInstance = serverlessExpress({
    app,
    eventSource: {
      getRequest: requestMapper,
      getResponse: responseMapper,
    }
  });

  return serverlessExpressInstance(event, context);
}

function handler(event, context) {
  return serverlessExpressInstance
    ? serverlessExpressInstance(event, context)
    : setup(event, context);
}

exports.handler = handler;