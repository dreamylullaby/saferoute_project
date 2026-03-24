const express = require("express");

const reportRoutes = require("./interfaces/routes/reportRoutes");

const app = express();

app.use(express.json());

app.use("/reports",reportRoutes);

app.get("/",(req,res)=>{
 res.send("SafeRoute API running");
});

app.listen(3000,()=>{
 console.log("server running");
});