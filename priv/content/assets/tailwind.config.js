const path = require("path");

console.log(path.join(__dirname, "../content/**/*.{html,heex,md,css}"));

export default {
  content: [
    path.join(__dirname, "../content/**/*.{html,heex,md,css}"),
    path.join(__dirname, "../pages/**/*.{html,heex,md,css}"),
    path.join(__dirname, "../components/**/*.{html,heex,md,css}"),
    path.join(__dirname, "../helpers/**/*.{html,heex,md,css}"),
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};
