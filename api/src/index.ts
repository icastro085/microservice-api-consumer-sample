import express, { Request, Response } from "express";
import AWS from "aws-sdk";
import mongoose, { Schema } from "mongoose";
import { v4 as uuid } from "uuid";
import cleanDeep from "clean-deep";

// -----------------
const PORT = (process.env.PORT || 3001) as string | number;
const SQS_URL_DELIVERY = process.env.SQS_URL_DELIVERY as string;
const SQS_URL_WEBHOOK = process.env.SQS_URL_WEBHOOK as string;
const MONGODB_URL = process.env.MONGODB_URL as string;

type AnyThing = Record<string, unknown>;

const logger = (value: AnyThing | unknown) => console.log(value);

// -----------------
const schemaNormalizePlugin = (schema: Schema) => {
  const options = ["toObject", "toJSON"] as const;
  type OptionsTypes = typeof options[number];

  options.forEach((key: OptionsTypes) => {
    schema.set(key, { virtuals: true });
  });

  schema.add({
    _id: {
      type: String,
      default: function () {
        const { id } = this as AnyThing;
        return id;
      },
    },
  });

  schema.set("versionKey", false);
  schema.set("timestamps", true);
};

mongoose.plugin(schemaNormalizePlugin);

interface Delivery {
  id?: string;
  organizationId: string;
  description?: string;
  status: "PEDDING" | "PROCESSING" | "WAITING" | "FINISHED" | "CANCELED";
  createdAt?: Date;
  updatedAt?: Date;
}

const DeliverySchema = new Schema<Delivery>({
  id: {
    type: String,
    default: uuid,
  },
  organizationId: {
    type: String,
    required: true,
  },
  description: String,
  status: {
    type: String,
    enum: ["PEDDING", "PROCESSING", "WAITING", "FINISHED", "CANCELED"],
    default: "PEDDING",
  },
});

const DeliveryModel = mongoose.model<Delivery>("DeliveryModel", DeliverySchema);

// -----------------
const sqs = new AWS.SQS({ region: "us-east-2" });
const app = express();

app.use(express.json());

// -----------------
const init = async () => {
  try {
    await mongoose.connect(MONGODB_URL);

    app.post("/delivery", async (resquest: Request, response: Response) => {
      try {
        const { body: data = {} } = resquest;
        const delivery = await DeliveryModel.create(data);
        const messageBody = JSON.stringify(delivery.toObject());

        const params: AWS.SQS.SendMessageRequest = {
          MessageBody: messageBody,
          QueueUrl: SQS_URL_DELIVERY,
        };

        const onMessageSent = async (
          error: AWS.AWSError,
          data: AWS.SQS.SendMessageResult,
        ) => {
          console.log(error);
          error
            ? response.status(500).json({
                status: 500,
                error: error.message,
              })
            : response.status(200).json({
                status: 200,
                data: {
                  ...delivery.toObject(),
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
      const deliveries = await DeliveryModel.find();

      response.status(200).json({
        status: 200,
        data: deliveries,
      });
    });

    app.get("/delivery/:id", async (resquest: Request, response: Response) => {
      const { id } = resquest.params;
      const delivery = await DeliveryModel.findById(id);
      const data = delivery?.toObject();

      response.status(200).json({
        status: 200,
        data,
      });
    });

    app.patch(
      "/delivery/:id",
      async (resquest: Request, response: Response) => {
        const { id } = resquest.params;
        const { body = {} } = resquest;
        const data = cleanDeep(body);
        delete data.id;
        const delivery = await DeliveryModel.findByIdAndUpdate(id, data, {
          new: true,
        });

        // SQS WEBHOOK-----------------------------------
        const messageBody = JSON.stringify(delivery?.toObject());

        const params: AWS.SQS.SendMessageRequest = {
          MessageBody: messageBody,
          QueueUrl: SQS_URL_WEBHOOK,
          MessageGroupId: body.id,
          MessageDeduplicationId: `${body.id}-${body.status}`,
        };

        const onMessageSent = async (
          error: AWS.AWSError,
          data: AWS.SQS.SendMessageResult,
        ) => {
          console.log("WEBHOOK");
          error ? console.log("ERROR", error) : console.log("DATA:", data);
        };

        sqs.sendMessage(params, onMessageSent);
        // -----------------------------------

        response.status(200).json({
          status: 200,
          data: delivery?.toObject(),
        });
      },
    );

    app.delete(
      "/delivery/:id",
      async (resquest: Request, response: Response) => {
        const { id } = resquest.params;
        await DeliveryModel.deleteOne({ id });

        response.status(200).json({
          status: 200,
        });
      },
    );

    app.listen(PORT, () => logger(`app is up on port: ${PORT}`));
  } catch (e) {
    logger(e);
  }
};

init();
