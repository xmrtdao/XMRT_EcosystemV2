const express = require("express");
const app = express();
app.get("/", (req, res) => res.json({message: "XMRT API", author: "Joseph Andrew Lee"}));
app.listen(3000, () => console.log("XMRT API running"));