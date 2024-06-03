const CopyWebpackPlugin = require("copy-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const Dotenv = require("dotenv-webpack");

module.exports = {
  mode: "development",
  entry: "./src/index.ts",
  output: {
    path: __dirname + "/dist/",
  },
  module: {
    rules: [
      {
        test: /\.(ts|tsx)$/,
        exclude: /node_modules/,
        resolve: {
          extensions: [".ts", ".tsx", ".js", ".json"],
        },
        use: "ts-loader",
      },
    ],
  },
  devtool: "inline-source-map",
  plugins: [
    new Dotenv(),
    new HtmlWebpackPlugin({ template: "./src/index.html" }),
    new CopyWebpackPlugin({
      patterns: [
        "assets/doom1.wad",
        "assets/default.cfg",
        "assets/websockets-doom.js",
        "assets/websockets-doom.wasm",
        "assets/websockets-doom.wasm.map",
        "assets/favicon.ico",
      ],
    }),
  ],
};
