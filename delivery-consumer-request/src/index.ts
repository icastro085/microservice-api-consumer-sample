import http from "http";
import { Consumer } from "sqs-consumer";
import AWS from "aws-sdk";

const SQS_URL_DELIVERY = process.env.SQS_URL_DELIVERY as string;
const SQS_URL_DELIVERY_RESPONSE = process.env
  .SQS_URL_DELIVERY_RESPONSE as string;

const sqs = new AWS.SQS({
  region: "us-east-2",
  httpOptions: {
    agent: new http.Agent({
      keepAlive: true,
    }),
  },
});

const handleStatus = async (
  body: { id: string },
  status: string,
): Promise<void> => {
  const messageBody = {
    ...body,
    status,
  };

  const params: AWS.SQS.SendMessageRequest = {
    MessageBody: JSON.stringify(messageBody),
    QueueUrl: SQS_URL_DELIVERY_RESPONSE,
    MessageGroupId: body.id,
    MessageDeduplicationId: `${body.id}-${status}`,
  };

  const onMessageSent = (
    error: AWS.AWSError,
    data: AWS.SQS.SendMessageResult,
  ) => {
    console.log(`Updated message: ${status}`, data, messageBody);

    if (error) {
      // throw new Error("Error on update message status");
      console.log("ERROR:", error.message);
    }
  };

  await sqs.sendMessage(params, onMessageSent).promise();
};

const handleMessage = async (message: AWS.SQS.Message): Promise<void> => {
  console.log("Received Message:", message);

  const body = message.Body ? JSON.parse(message.Body) : {};
  const { id } = body;

  // update message to the consumer response
  console.log("Updating message: PROCESSING");
  await handleStatus({ id }, "PROCESSING");

  // TODO: add partners request

  // update message to the consumer response
  console.log("Updating message: WAITING");
  await handleStatus({ id }, "WAITING");
};

const consumer = Consumer.create({
  queueUrl: SQS_URL_DELIVERY,
  handleMessage,
  sqs,
});

consumer.on("error", (error) => {
  console.error(error.message);
});

consumer.on("processing_error", (error) => {
  console.error(error.message);
});

consumer.start();
