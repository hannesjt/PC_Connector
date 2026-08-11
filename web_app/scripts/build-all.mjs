#!/usr/bin/env node
import { execSync } from "node:child_process";
import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const isWin = process.platform === "win32";
const isMac = process.platform === "darwin";

function run(cmd, cwd = root) {
  console.log(`\n\x1b[36m$ ${cmd}\x1b[0m`);
  execSync(cmd, { cwd, stdio: "inherit", shell: true });
}

function header(title) {
  console.log(`\n\x1b[1m\x1b[34m=== ${title} ===\x1b[0m`);
}

const args = process.argv.slice(2).map((a) => a.toLowerCase());
const wantAll = args.length === 0;
const want = {
  android: wantAll || args.includes("android"),
  ios: wantAll || args.includes("ios"),
  exe: wantAll || args.includes("exe") || args.includes("desktop"),
};

const results = [];

function buildAndroid() {
  header("Android");
  run("npx nuxt generate");
  if (!existsSync(join(root, "android"))) run("npx cap add android");
  run("npx cap sync android");
  run(
    isWin ? "gradlew.bat assembleRelease" : "./gradlew assembleRelease",
    join(root, "android"),
  );
  results.push("Android APK -> android/app/build/outputs/apk/release/");
}

function buildIos() {
  if (!isMac) {
    console.warn("\n\x1b[33m! iOS skipped (macOS + Xcode required).\x1b[0m");
    results.push("iOS -> skipped (macOS only)");
    return;
  }
  header("iOS");
  run("npx nuxt generate");
  if (!existsSync(join(root, "ios"))) run("npx cap add ios");
  run("npx cap sync ios");
  run(
    "xcodebuild -workspace ios/App/App.xcworkspace -scheme App " +
      "-configuration Release -archivePath build/App.xcarchive archive " +
      "CODE_SIGNING_ALLOWED=NO",
  );
  results.push("iOS Archive -> build/App.xcarchive");
}

function buildDesktop() {
  header("Desktop");
  run("npx nuxt build");
  const flag = isWin ? "--win" : isMac ? "--mac" : "--linux";
  run(`npx electron-builder ${flag} --publish never`);
  results.push("Desktop -> release/");
}

try {
  if (want.android) buildAndroid();
  if (want.ios) buildIos();
  if (want.exe) buildDesktop();

  header("Done");
  results.forEach((r) => console.log("  " + r));
} catch (err) {
  console.error("\n\x1b[31mBUILD FAILED\x1b[0m");
  console.error(err.message);
  process.exit(1);
}
