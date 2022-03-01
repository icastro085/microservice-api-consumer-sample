const express = require("express");
const app = express();

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

app.post("/sqs-hanlder", (req, res) => {
  const { body } = req;
  console.log("SQS HANLDER", body)
  res.json({
    message: "Hello, World! - sqs-hanlder",
  });
});

module.exports = app;