const express = require("express");
const app = express();

app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "Hello, World!",
  });
});

app.get("/hi", (req, res) => {
  res.json({
    message: "Hi!",
  });
});

app.get("/oi", (req, res) => {
  res.json({
    message: "Oi!",
  });
});

app.get("/hello/:name", (req, res) => {
  const { name } = req.params;

  res.json({
    message: `Hello ${name}!`,
  });
});

app.post("/sqs-handler", (req, res) => {
  const { body } = req;
  console.log(typeof body, "SQS HANDLER", body);

  res.json({
    message: "Hello, World! - sqs-hanlder",
  });
});

app.post("/s3-handler", (req, res) => {
  const { body } = req;
  console.log(typeof body, "S3 HANDLER", body);

  res.json({
    message: "Hello, World! - s3-hanlder",
  });
});

app.post("/post-test", (req, res) => {
  const { body } = req;
  console.log(typeof body, "POST TEST", body);

  res.json({
    message: "Hello, World! - post-test",
  });
});

app.get("/post-test", (req, res) => {
  const { query } = req;
  console.log(typeof query, "GET TEST", query);

  res.json({
    message: "Hello, World! - post-test",
  });
});

module.exports = app;