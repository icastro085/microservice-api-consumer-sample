import http from "http";
import { Consumer } from "sqs-consumer";
import AWS from "aws-sdk";
import axios from "axios";

const HUB_URL_API = process.env.HUB_URL_API as string;

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

const huaApi = axios.create({
  baseURL: HUB_URL_API,
  timeout: 1000,
});

const handleMessage = async (message: AWS.SQS.Message): Promise<void> => {
  const delivery = message.Body ? JSON.parse(message.Body) : null;

  if (delivery) {
    console.log("Received Message:", message);
    const response = await huaApi.patch(`/delivery/${delivery.id}`, delivery);
    console.log(response.status, response.data);
  }
};

const consumer = Consumer.create({
  queueUrl: SQS_URL_DELIVERY_RESPONSE,
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
