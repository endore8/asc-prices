#!/usr/bin/env node
import { Command } from "commander";
import { runSession } from "./session/repl.js";
import { runLogout } from "./session/logout.js";

const program = new Command();

program
  .name("asc-prices")
  .description(
    "Preview and apply PPP-aligned App Store subscription and in-app purchase prices",
  )
  .version("0.0.1")
  .action(async () => {
    await runSession();
  });

program
  .command("logout")
  .description("Forget cached App Store Connect credentials")
  .action(async () => {
    await runLogout();
  });

program.parseAsync(process.argv).catch((err) => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
