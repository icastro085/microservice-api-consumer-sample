const express = require("express");
const serverless = require("@vendia/serverless-express");

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

exports.handler = serverless({ app });