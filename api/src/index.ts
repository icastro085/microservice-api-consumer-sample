import express, { Request, Response } from "express";
import AWS from "aws-sdk";
import dynamoose from "dynamoose";
import { v4 as uuid } from "uuid";
import cleanDeep from "clean-deep";

const PORT = (process.env.PORT || 3001) as string | number;
const SQS_URL_DELIVERY = process.env.SQS_URL_DELIVERY as string;
const DYNAMODB_URL = process.env.DYNAMODB_URL as string;

// -----------------
dynamoose.aws.sdk.config.update({ region: "us-east-2" });
dynamoose.aws.ddb.local(DYNAMODB_URL);

const DeliverySchema = new dynamoose.Schema(
  {
    id: {
      type: String,
      hashKey: true,
      default: uuid,
    },
    organizationId: String,
    description: String,
    status: {
      type: String,
      enum: ["PEDDING", "PROCESSING", "WAITING", "FINISHED", "CANCELED"],
      default: "PEDDING",
    },
  },
  { timestamps: true, saveUnknown: false },
);

const DeliveryModel = dynamoose.model("Delivery", DeliverySchema);

// -----------------
const sqs = new AWS.SQS({ region: "us-east-1" });
const app = express();

app.use(express.json());

// -----------------
app.post("/delivery", async (resquest: Request, response: Response) => {
  try {
    const { body: data = {} } = resquest;
    const delivery = await DeliveryModel.create(data);
    const messageBody = await delivery.populate();

    const params: AWS.SQS.SendMessageRequest = {
      MessageBody: JSON.stringify(messageBody),
      QueueUrl: SQS_URL_DELIVERY,
    };

    const onMessageSent = async (
      error: AWS.AWSError,
      data: AWS.SQS.SendMessageResult,
    ) => {
      console.log(data);

      error
        ? response.status(500).json({
            status: 500,
            error: error.message,
          })
        : response.status(200).json({
            status: 200,
            data: {
              ...(await delivery.populate()),
              messageIdSQS: data.MessageId,
            },
          });
    };

    sqs.sendMessage(params, onMessageSent);
  } catch (e) {
    const error = e as AWS.AWSError;
    const status = error?.statusCode || 500;

    response.status(status).json({
      status: status,
      error: error?.message || "Internal error server",
    });
  }
});

app.get("/delivery", async (resquest: Request, response: Response) => {
  const deliveries = await DeliveryModel.scan().exec();

  response.status(200).json({
    status: 200,
    data: deliveries,
  });
});

app.get("/delivery/:id", async (resquest: Request, response: Response) => {
  const { id } = resquest.params;
  const delivery = await DeliveryModel.get(id);
  const data = await delivery.populate();

  response.status(200).json({
    status: 200,
    data,
  });
});

app.patch("/delivery/:id", async (resquest: Request, response: Response) => {
  const { id } = resquest.params;
  const { body = {} } = resquest;
  const data = cleanDeep(body);

  delete data.id;
  const delivery = await DeliveryModel.update({ id }, data);

  response.status(200).json({
    status: 200,
    data: await delivery.populate(),
  });
});

app.delete("/delivery/:id", async (resquest: Request, response: Response) => {
  const { id } = resquest.params;
  await DeliveryModel.delete(id);

  response.status(200).json({
    status: 200,
  });
});

app.listen(PORT, () => console.log(`app is up on port: ${PORT}`));
